component accessors="true" {

	taskInterfaces = ["java.util.concurrent.Callable"];
	supportsNativeProxy = structKeyExists( getFunctionList(), "createDynamicProxy" );
	status = "stopped";

	debuggerUnavailableQuery = queryNew('DebuggerUnavailable');
	serviceNotRunningQuery = queryNew('ServiceNotRunning');
	
	//for internal metrics
	metricsCounter = new MetricsCounter();
	
	function init( publishFrequency = 120, publishers ){
		variables.timeUnit = createObject( "java", "java.util.concurrent.TimeUnit" );
		variables.metricsDebuggingService = createObject( "java", "coldfusion.server.ServiceFactory" ).getDebuggingService();
		structAppend( variables, arguments );
		return this;
	}

	/* Lifecycle methods */
	
	public function start(){
		//always ensure we shut down anything we previously created
		stop();
		initJavaLoader();

		variables.completionQueue = createObject("java", "java.util.concurrent.LinkedBlockingQueue").init( 100000 );
		variables.metricsExecutorThreadPool = createObject("java", "java.util.concurrent.Executors").newFixedThreadPool( 4 );
		variables.metricsParseService = createObject("java", "java.util.concurrent.ExecutorCompletionService").init( metricsExecutorThreadPool, completionQueue );
		variables.metricsCompletionService = createObject("java", "java.util.concurrent.ScheduledThreadPoolExecutor").init( 1 );

		//schedule the periodic persisting of the gathered metrics
		variables.metricsCompletionTask = new MetricsCompletionTask( metricsParseService, metricsCounter, variables.publishers );
		var proxy = createProxy( metricsCompletionTask, ["java.lang.Runnable"] );
		variables.metricsCompletionService.scheduleAtFixedRate( proxy, publishFrequency, publishFrequency, timeUnit.SECONDS );

		status = "started";
		return this;
	}

	public function stop(){
		if( isDefined("metricsExecutorThreadPool") ){
			variables.metricsExecutorThreadPool.shutdownNow();
			variables.metricsCompletionService.shutdownNow();
		}

		status = "stopped";
		return this;
	}

	public function pause(){
		status = "paused";
		return this;
	}

	public function unPause(){
		if( isStopped() ){
			start();
		} else {
			status = "started";
		}
		return this;
	}
	
	public function collect(){
		writeLog("Starting Collection!")

		if( isStarted() ){
			var summary = getMetricsDataFromDebugger();
			if( summary.recordCount ){
				submitCollection( summary );
			}
			writeLog("Collection Submitted.");
			return summary;
		} else {
			return serviceNotRunningQuery;
		}
	}

	
	/* CFMetrics State methods */

	public function isStarted(){
		return getStatus() eq "started";
	}

	public function isStopped(){
		return getStatus() eq "stopped";
	}

	public function isPaused(){
		return getStatus() eq "paused";
	}
	
	public function getCFMetricsCounters(){
		return metricsCounter.getCounters();
	}
	
	public function getCompletionQueueSize(){
		if( isStopped() ){
			throw("Completion Queue Size is unavailable when this service is stopped", "OperationUnavailableException");
		} else {
			return completionQueue.size();
		}
	}
	
	public function isDebuggerAvailable(){
		return NOT isNull( metricsDebuggingService.getDebugger() );
	}

	public function getMetricsDataFromDebugger(){

		//when debug output is disabled in CFAdmin, this will be null; however, we can't use isDebugMode() because that returns
		//false when debugging is enabled in CFAdmin but cfsetting showdebugoutput='false' is set
		var result = debuggerUnavailableQuery;
		var startTick = getTickCount();
		
		if( isDebuggerAvailable() ){
			
			var qEvents =  metricsDebuggingService.getDebugger().getData();
			result = new Query(dbtype="query",
				sql="
					SELECT template, endTime - startTime AS totalExecutionTime
					FROM qEvents
					WHERE type = 'Template'
					and endTime <> startTime
					and parent not like '%ModelGlue%'
					and parent not like '%Coldspring%'
					and template not like '%EventContext.cfc'

					order by totalExecutionTime DESC
					"
				, qEvents=qEvents).execute().getResult();

		}
		
		metricsCounter.addDebuggerQueryTime( getTickCount() - startTick );
		return result;
	}

	private void function submitCollection( summaryQuery ){

		var task = new MetricsParseTask( summaryQuery, variables.metricsCounter );
		var proxy = createProxy( task, taskInterfaces );

		try{
			metricsParseService.submit( proxy );
			//writeLog("metrics collection of size #summaryQuery.recordCount# submitted for processing");
		} catch( any e ){
			writeLog(e.message);
		}
	}

	private function getStatus(){
		return status;
	}

	private function initJavaLoader(){
		if( NOT supportsNativeProxy ){
			structDelete( server, "___CFMetricsJavaLoader" );
			var proxyJarPath = getDirectoryFromPath( getCurrentTemplatePath() ) & "/javaloader/support/cfcdynamicproxy/lib/cfcdynamicproxy.jar";
			var paths = [proxyJarPath];
			server.___CFMetricsJavaLoader = new javaloader.JavaLoader( loadPaths = paths, loadColdFusionClassPath = true );

			//for convenience
			variables.javaloader = server.___CFMetricsJavaLoader;
			variables.CFCDynamicProxy = variables.javaloader.create( "com.compoundtheory.coldfusion.cfc.CFCDynamicProxy" );
		}
	}

	private function createProxy( object, interfaces ){
		if( supportsNativeProxy ){
			return createDynamicProxy( arguments.object, arguments.interfaces );
		} else {
			return cfcDynamicProxy.createInstance( arguments.object, arguments.interfaces );
		}
	}
}