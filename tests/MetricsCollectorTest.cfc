component extends="cfmetrics.tests.BaseCFMetricsTestCase"{

	function setUp(){
		publisher = new publishers.VariablePublisher();
		publisher2 = new publishers.VariablePublisher();
		//use the same publisher twice... doing this to test that multiple publishers are honored
		collector = new cfmetrics.MetricsCollector(1, [ publisher, publisher2 ]);

	}

	function tearDown(){
		collector.stop();
	}

	function stop_does_not_fail_when_called_repeatedly(){
		collector.stop();
		collector.stop();
		assertTrue(collector.isStopped());
		collector.start();
		assertTrue(collector.isStarted());
		collector.stop();
		assertTrue(collector.isStopped());
		collector.stop();
		assertTrue(collector.isStopped());
	}

	/**
	* @mxunit:expectedException OperationUnavailableException
	*/
	function completionQueueSize_errors_if_collector_is_not_started(){
		collector.stop();
		var size = collector.getCompletionQueueSize();
	}

	function completionQueueSize_increments_when_tasks_are_completed(){
		submitCollection();
		sleep(100);
		assertEquals( 1, collector.getCompletionQueueSize() );
	}

	function metricsCompletionTask_publishes_to_all_publishers(){
		var query = submitCollection();
		sleep(1100);//since we set the reap time to 1 second up above
		var pub1Result = publisher.getPublished();
		var pub2Result = publisher2.getPublished();
		assertTrue( arrayLen(pub1Result) GT 0 );
		assertEquals( query.recordCount, arrayLen(pub1Result) );
		assertEquals( query.recordCount, arrayLen(pub2Result) );

		//do it again... we know that the submission uses a pre-built, static query
		submitCollection();
		sleep(1100);
		var pub1Result2 = publisher.getPublished();
		var pub2Result2 = publisher2.getPublished();

		assertEquals( query.recordCount * 2, arrayLen(pub1Result2) );
		assertEquals( query.recordCount * 2, arrayLen(pub2Result2) );

	}

	function collect_returns_empty_query_when_service_not_running(){
		collector.stop();
		var result = collector.collect();
		assertEquals( 0, result.recordCount );
	}

	function collect_returns_empty_query_when_debugger_unavailable(){
		injectMethod( collector, this, "isDebuggerAvailable", "isDebuggerAvailable" );
		collector.start();
		var result = collector.collect();
		assertEquals( 0, result.recordCount );
	}

	private function submitCollection(){
		injectProperty(collector, "thisDir", thisDir);
		injectMethod(collector, this, "getTestQuery", "getMetricsDataFromDebugger");
		collector.start();
		return collector.collect();
	}

	private function isDebuggerAvailable(){
		return false;
	}


}