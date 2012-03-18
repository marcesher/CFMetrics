component extends="cfmetrics.tests.BaseCFMetricsTestCase" {



	function setUp(){
		removeOutputDirectory();
		testQuery = getTestQuery();
		parseTask = new CFMetrics.MetricsParseTask( testQuery, variables.metricsCounter );
		publisher = new CFMetrics.publishers.FilePublisher( "cfmetrics", outputDirectory );
	}

	function tearDown(){
		//removeOutputDirectory();
	}
	function publish_should_do_nothing_with_zero_rows(){
		var result = publisher.publish([]);
		assertTrue( fileExists( result ) );
		var fileContents = trim(fileRead(result));
		var asArray = listToArray( fileContents, Chr(10) );
		assertEquals( 1, arrayLen(asArray) );
	}

	function publish_should_write_file_with_rows(){
		var result = parseTask.call();
		var publishResult = publisher.publish(result);
		var publishResult2 = publisher.publish(result);
		assertTrue( len(publishResult) );
		assertTrue( fileExists( publishResult ) );
		
		assertEquals( publishResult, publishResult2 );

		var fileContents = trim(fileRead(publishResult));
		
		var linesAsArray = listToArray( fileContents, chr(10) );
		var headerRowAsArray = listToArray( linesAsArray[1], chr(9) );
		debug(headerRowAsArray);
		
		assertEquals( (testQuery.RecordCount + 1)*2, arrayLen(linesAsArray), "should have been a line for every row in the test query, plus the header row (X2 since we submitted twice)" );
		
		assertEquals( "template", headerRowAsArray[1] );
		assertEquals( "method", headerRowAsArray[2] );
		assertEquals( "args", headerRowAsArray[3] );
		assertEquals( "timestamp", headerRowAsArray[4] );
		assertEquals( "scriptName", headerRowAsArray[5] );
		assertEquals( "queryString", headerRowAsArray[6] );
		assertEquals( "totalExecutionTime", headerRowAsArray[7] );
	}
}