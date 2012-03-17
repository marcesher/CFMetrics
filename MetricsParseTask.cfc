component output="false"{

	/**
	* @metricsQuery a query from the CF Debugger service. Must contain columns template and totalExecutionTime
	*/
	public function init( string applicationName, query metricsQuery ){

		structAppend( variables, arguments );
		variables.timestamp = now();
		variables.scriptName = cgi.SCRIPT_NAME;
		variables.queryString = cgi.QUERY_STRING;
		return this;
	}

	public any function call(){

		try{
			return createMetrics();
		} catch( any e ){
			writeLog("Exception in MetricsParseTask.call(): #cfcatch.message#");
			return cfcatch;
		}
	}

	public function createMetrics(){

		var all = [];
		var rc = variables.metricsQuery.recordCount;

		for( var row = 1; row <= rc; row++ ){
			var result = parseTemplate( metricsQuery.template[row] );
			result.totalExecutionTime = metricsQuery.totalExecutionTime[row];
			arrayAppend( all, result );
		}

		return all;
	}

	/*Contends with a 'template' string from the CF Debugger service of the form:

		CFC[ C:\dev\projects\wwwroot\mxunit\framework\decorators\DataProviderDecorator.cfc | setUp(methodName = testSomething) ] from C:\dev\projects\wwwroot\mxunit\framework\decorators\DataProviderDecorator.cfc

		Surely there's a more clever way to parse this
	*/
	public function parseTemplate( string template ){
		var result = {found = false, template = template, method="", args=""};

		/*
		* turn CFC[ C:\dev\projects\wwwroot\mxunit\framework\decorators\DataProviderDecorator.cfc | setUp(methodName = testSomething) ] from C:\dev\projects\wwwroot\mxunit\framework\decorators\DataProviderDecorator.cfc
			into
		  CFC[ C:\dev\projects\wwwroot\mxunit\framework\decorators\DataProviderDecorator.cfc | setUp(methodName = testSomething) ]
		*/
		var templateAndMethod = reMatch("CFC\[ .*\]", template);

		if( arrayLen(templateAndMethod) eq 1 ){
			var tmp = templateAndMethod[1];

			/*
			* turn CFC[ C:\dev\projects\wwwroot\mxunit\framework\decorators\DataProviderDecorator.cfc | setUp(methodName = testSomething) ]
			into
			C:\dev\projects\wwwroot\mxunit\framework\decorators\DataProviderDecorator.cfc | setUp(methodName = testSomething)
			*/
			var f = trim(replace(listFirst(tmp, "|" ), "CFC[", "", "one"));

			//get the method and args, which follows the pipe
			var method = trim(replace(listLast(tmp, "|" ), ") ]", ")", "one"));

			//get all the stuff in between the start and end parens in the method
			var args = trim(reMatch("\(.*\)", method)[1]);

			//chop parens off the args
			args = mid( args,2, len(args)-2 );

			//if we have linebreaks in the args, just truncate it at the first break and return the first 200 chars
			args = left(reReplace(args, "#chr(13)#|#chr(10)#"," ", "all"), 200);

			//pull the method name off the front
			method = listFirst(method, "(");

			result = {found = true, template = f, method = method, args = args};
		}
		return result;
	}

}
