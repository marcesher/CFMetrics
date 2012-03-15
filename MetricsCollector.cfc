component accessors="true" {

	property name="publishFrequency" type="numeric" hint="In seconds, how frequently should gathered metrics be published?";

	hasBeenStarted = false;
	taskInterfaces = ["java.util.concurrent.Callable"];
	supportsNativeProxy = structKeyExists( getFunctionList(), "createDynamicProxy" );
	status = "stopped";

	debuggerUnavailbleQuery = queryNew('DebuggerUnavailable');
	serviceNotRunningQuery = queryNew('ServiceNotRunning');

	function init( publishFrequency = 120, publishers ){
		variables.timeUnit = createObject( "java", "java.util.concurrent.TimeUnit" );
		variables.metricsDebuggingService = createObject( "java", "coldfusion.server.ServiceFactory" ).getDebuggingService();
		structAppend( variables, arguments );
		return this;
	}

	public function start(){
		//always ensure we shut down anything we previously created
		stop();
		initJavaLoader();

		variables.completionQueue = createObject("java", "java.util.concurrent.LinkedBlockingQueue").init( 100000 );
		variables.metricsExecutorThreadPool = createObject("java", "java.util.concurrent.Executors").newFixedThreadPool( 4 );
		variables.metricsParseService = createObject("java", "java.util.concurrent.ExecutorCompletionService").init( metricsExecutorThreadPool, completionQueue );
		variables.metricsCompletionService = createObject("java", "java.util.concurrent.ScheduledThreadPoolExecutor").init( 1 );

		//schedule the periodic persisting of the gathered metrics
		var metricsCompletionTask = new MetricsCompletionTask( metricsParseService, variables.publishers );
		var proxy = createProxy( metricsCompletionTask, ["java.lang.Runnable"] );
		variables.metricsCompletionService.scheduleAtFixedRate( proxy, publishFrequency, publishFrequency, timeUnit.SECONDS );


		hasBeenStarted = true;
		status = "started";
		return this;
	}

	public function stop(){
		if( hasBeenStarted ){
			variables.metricsExecutorThreadPool.shutdown();
			variables.metricsExecutorThreadPool.awaitTermination( 1, timeUnit.SECONDS );
			variables.metricsCompletionService.shutdownNow();
		}

		status = "stopped";
		return this;
	}

	public function pause(){
		status = "paused";
	}

	public function unPause(){
		if( isStopped() ){
			start();
		} else {
			status = "started";
		}
	}

	public function getCompletionQueueSize(){
		if( isStopped() ){
			throw("Completion Queue Size is unavailable when this service is stopped", "OperationUnavailableException");
		} else {
			return completionQueue.size();
		}
	}

	public function isStarted(){
		return getStatus() eq "started";
	}

	public function isStopped(){
		return getStatus() eq "stopped";
	}

	public function isPaused(){
		return getStatus() eq "paused";
	}

	public function collect(){
		writeLog("starting collection!")

		if( isStarted() ){
			var summary = getMetricsDataFromDebugger();
			if( summary.recordCount ){
				submitCollection( summary );
			}
			return summary;
		} else {
			return serviceNotRunningQuery;
		}
	}

	public function isDebuggerAvailable(){
		return NOT isNull( metricsDebuggingService.getDebugger() );
	}

	private function getMetricsDataFromDebugger(){
		//when debug output is disabled in CFAdmin, this will be null; however, we can't use isDebugMode() because that returns
		//false when debugging is enabled in CFAdmin but cfsetting showdebugoutput='false' is set
		if( isDebuggerAvailable() ){
			var qEvents =  metricsDebuggingService.getDebugger().getData();
			return new Query(dbtype="query",
				sql="
					SELECT  template, Sum(endTime - startTime) AS totalExecutionTime
					FROM qEvents
					WHERE type = 'Template'
					and endTime <> startTime
					and parent not like '%ModelGlue%'
					and parent not like '%Coldspring%'
					and template not like '%EventContext.cfc'
					group by template
					order by totalExecutionTime DESC"
				, qEvents=qEvents).execute().getResult();

		} else {
			return debuggerUnavailbleQuery;
		}
	}

	private function submitCollection( summaryQuery ){
		var task = new MetricsParseTask( summaryQuery );
		var proxy = createProxy( task, taskInterfaces );
		try{
			metricsParseService.submit( proxy );
			//writeLog("metrics collection of size #summaryQuery.recordCount# submitted for processing");
		} catch( any e ){
			writeLog(e.message);
		}
		return summaryQuery;
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