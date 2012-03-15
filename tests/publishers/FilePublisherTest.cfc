component extends="cfmetrics.tests.BaseCFMetricsTestCase" {



	function setUp(){
		removeOutputDirectory();
		testQuery = getTestQuery();
		parseTask = new CFMetrics.MetricsParseTask( testQuery );
		publisher = new CFMetrics.publishers.FilePublisher( outputDirectory );
	}

	function tearDown(){
		//removeOutputDirectory();
	}

	function publish_should_do_nothing_with_zero_rows(){
		publisher.publish([]);
		assertTrue( arrayIsEmpty( directoryList(outputDirectory, "false", "array" )  ) );
	}

	function publish_should_write_file_with_rows(){
		var result = parseTask.call();
		var publishResult = publisher.publish(result);
		debug( publishResult );
		assertTrue( len(publishResult) );
		assertTrue( fileExists( publishResult ) );

		var fileContents = fileRead(publishResult);
		debug(fileContents);
		var linesAsArray = listToArray( fileContents, chr(10) );
		var headerRowAsArray = listToArray( linesAsArray[1], chr(9) );
		debug(headerRowAsArray);
		assertEquals( "template", headerRowAsArray[1] );
		assertEquals( "method", headerRowAsArray[2] );
		assertEquals( "args", headerRowAsArray[3] );
		assertEquals( "totalExecutionTime", headerRowAsArray[4] );
	}
}