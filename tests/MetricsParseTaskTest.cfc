component extends="BaseCFMetricsTestCase"{

	function setUp(){
		testQuery = getTestQuery();
		parseTask = new CFMetrics.MetricsParseTask( testQuery );
	}

	function call_should_create_array_of_metrics_based_on_input_query(){
		var result = parseTask.call();
		//debug(testQuery);
		assertTrue( arrayLen(result) GT 0 );
		assertEquals( testQuery.recordCount, arrayLen(result) );

		//hard-coding these expectations b/c I know them to be true from the input query
		var result2 = result[2];

		assertEquals( testQuery.TotalExecutionTime[2], result2.totalExecutionTime );
		assertEquals( "run", result2.method );
		assertEquals( "", result2.args );
		debug(result2);
	}

}