/*
Takes all the completed parses and publishes them. Implements the java.lang.Runnable interface
 */
component output="false" accessors="true"{

	property name="publishers" type="array";

	public function init( any parseService, array publishers ){
		structAppend( variables, arguments );
		return this;
	}

	/*
	* pulls completed tasks off of the completion queue and submits them to all registered publishers
	*/
	public function run(){
		var allResults = [];
		var thisTask = parseService.poll();
		while(  NOT isNull( thisTask ) ){

			try
		    {
		    	var all = thisTask.get();
		    	allResults.addAll( all );
		    }
		    catch(Any e)
		    {
		    	writeLog("Error in Metrics Completion Task : #e.getMessage()#; #e.getDetail()#")
		    }

			thisTask = parseService.poll();
		}

		if( NOT arrayIsEmpty(allResults) ){
			for( var publisher in publishers ){
				publisher.publish( allResults );
			}
		}
	}

}
