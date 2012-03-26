/*
How CFMetrics keeps track of its own internal processing time and counts
*/
component output="false"  {

	debuggerQueryTime = createObject( "java", "java.util.concurrent.atomic.AtomicLong" );
	publishTime = createObject( "java", "java.util.concurrent.atomic.AtomicLong" );
	publishCount = createObject( "java", "java.util.concurrent.atomic.AtomicLong" );
	parseQueueTime = createObject( "java", "java.util.concurrent.atomic.AtomicLong" );
	parseTime = createObject( "java", "java.util.concurrent.atomic.AtomicLong" );
	parseCount = createObject( "java", "java.util.concurrent.atomic.AtomicLong" );
	parseEventCount = createObject( "java", "java.util.concurrent.atomic.AtomicLong" );

	public function getCounters(){
		return {
			debuggerQueryTime = debuggerQueryTime.get()
			, publishTime = publishTime.get()
			, publishCount = publishCount.get()
			, parseQueueTime = parseQueueTime.get()
			, parseTime = parseTime.get()
			, parseCount = parseCount.get()
			, parseEventCount = parseEventCount.get()
		};
	}

	private function addCount( target, value ){
		//writeLog("looking at value #value#");
		if( value GT 0 ){
			target.addAndGet( value );
		}
		return this;
	}

	function addDebuggerQueryTime( numeric time ){
		return addCount( debuggerQueryTime, time );
	}

	function addPublishTime( numeric time ){
		return addCount( publishTime, time );
	}

	function addPublishCount( numeric count ){
		return addCount( publishCount, count );
	}

	function addParseQueueTime( numeric time ){
		return addCount( parseQueueTime, time );
	}

	function addParseTime( numeric time ){
		return addCount( parseTime, time );
	}

	function addParseCount( numeric count ){
		return addCount( parseCount, count );
	}

	function addParseEventCount( numeric count ){
		return addCount( parseEventCount, count );
	}
}