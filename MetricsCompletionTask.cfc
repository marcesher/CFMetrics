<!---
This task takes all the completed parses and publishes them
 --->
<cfcomponent hint="" output="false" accessors="true">

	<cfproperty name="publishers">

	<cffunction name="init" output="false" access="public" returntype="any" hint="">
    	<cfargument name="parseService" type="any" required="true"/>
		<cfargument name="publishers" type="array" required="true"/>

		<cfset structAppend( variables, arguments )>
		<cfreturn this>
    </cffunction>


	<cffunction name="run" output="false" access="public" returntype="void" hint="">

    	<cfscript>
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
			for( publisher in publishers ){
				publisher.publish( allResults );
			}
		}

		</cfscript>



    </cffunction>

</cfcomponent>