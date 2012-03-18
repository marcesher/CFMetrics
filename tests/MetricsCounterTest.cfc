component extends="BaseCFMetricsTestCase" {
	
	function setUp(){
		counter = new cfmetrics.MetricsCounter();
	}
	
	function counters_are_zero_when_started(){
		counters = counter.getCounters();
		for( key in counters ){
			assertEquals( 0, counters[key] );
		}
	}
	
	function counters_increment(){
		counter
			.addDebuggerQueryTime(50)
			.addDebuggerQueryTime(50)
			.addPublishTime(500)
			.addPublishTime(500)
			.addPublishCount(2)
			.addPublishCount(2)
			.addParseTime(100)
			.addParseTime(100)
			.addParseQueueTime(2000)
			.addParseQueueTime(2000)
			.addParseCount(10)
			.addParseCount(10)
			.addParseEventCount(90)
			.addParseEventCount(90);
			
		counters = counter.getCounters();
		
		assertEquals( counters, {debuggerQueryTime=100, publishTime=1000, publishCount=4, parseTime=200, parseQueueTime = 4000, parseCount = 20, parseEventCount = 180} );
	}
} 