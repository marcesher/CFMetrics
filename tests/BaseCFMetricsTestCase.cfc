<cfcomponent extends="mxunit.framework.TestCase">

	<cfset thisDir = getDirectoryFromPath(getCurrentTemplatePath())>
	<cfset variables.outputDirectory = thisDir & "/tmpoutput">
	<cfset variables.metricsCounter = new cfmetrics.MetricsCounter()>

	<cffunction name="getTestQuery" output="false" access="private" returntype="query" hint="">
    	<cfset var wddx = "">
    	<cfset var testQuery = "">
    	<cfset var filePath = thisDir & "/input/queryoutput.txt">
    	<cffile action="read" file="#filePath#" variable="wddx">
    	<cfwddx action="wddx2cfml" input="#wddx#" output="testQuery">
    	<cfreturn testQuery>
    </cffunction>

    <cffunction name="removeOutputDirectory" output="false" access="private" returntype="any" hint="">
    	<cfif directoryExists( outputDirectory )>
    		<cfdirectory action="delete" directory="#outputDirectory#" recurse="true" >
    	</cfif>
    </cffunction>


</cfcomponent>