/*
Takes all the completed parses and publishes them. Implements the java.lang.Runnable interface
 */
component output="false" accessors="true"{

	property name="publishers" type="array";
	

	public function init( any parseService, MetricsCounter metricsCounter, array publishers ){
		structAppend( variables, arguments );
		return this;
	}

	/*
	* pulls completed tasks off of the completion queue and submits them to all registered publishers
	*/
	public function run(){
		var allResults = [];
		var startTick = getTickCount();
		var thisTask = parseService.poll();
		
		while(  NOT isNull( thisTask ) ){

			try
		    {
		    	var all = thisTask.get();
		    	if( isArray(all) ){
			    	allResults.addAll( all );
		    	} else {
		    		writeLog("MetricsCompletionTask: Result of task.get() was not an array... not adding to the publish queue");
		    	}
		    }
		    catch( Any e )
		    {
		    	writeLog("Error in Metrics Completion Task polling the queue : #e.getMessage()#; #e.getDetail()#")
		    }

			thisTask = parseService.poll();
		}
		
		try
		{
			if( NOT arrayIsEmpty(allResults) ){
				for( var publisher in publishers ){
					publisher.publish( allResults );
				}
				metricsCounter.addPublishCount(1);
			}
		}
		catch( Any e )
		{
			writeLog("Error in Metrics Completion Task publish : #e.getMessage()#; #e.getDetail()#")
		}

		metricsCounter.addPublishTime( getTickCount() - startTick );
	}

}
