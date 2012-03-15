<!---
Writes parse results to a file
 --->
<cfcomponent hint="" output="false">

	<cffunction name="init" output="false" access="public" returntype="any" hint="">
		<cfargument name="fileOutputDir" type="string" required="false" default="#getDirectoryFromPath(getCurrentTemplatePath())#/metrics_output/"/>
		<cfargument name="fieldDelimiter" type="string" required="false" default="#chr(9)#"/>
		<cfargument name="showHeaders" type="boolean" required="false" default="true"/>

		<cfset structAppend( variables, arguments )>
		<cfset createObject("java", "java.io.File").init(fileOutputDir).mkdirs()>
		<cfset var headerFields = ["template", "method", "args", "totalExecutionTime"]>
		<cfset variables.header = arrayToList(headerFields, fieldDelimiter) & chr(10)>

		<cfreturn this>
    </cffunction>

	<cffunction name="publish" output="false" access="public" returntype="any" hint="Writes results to a structured text file">
		<cfargument name="data" type="array" required="true" hint="An array of structs. Each struct will contain fields: template, method, args, totalExecutionTime"/>

    	<cfscript>
    	var outputFile = "";
    	try{
			var d = variables.fieldDelimiter;
			var stringData = "";

			if(stringData eq "" AND variables.showHeaders){
				stringData = header;
			}
			for( var result in data ){
				stringData &= "#result.template##d##result.method##d##result.args##d##result.totalExecutionTime##chr(10)#";
			}

			if(stringData neq "" and stringData neq header){
				outputFile = variables.fileOutputDir & "/#getFileName()#";
		    	fileWrite(outputFile, stringData);
			}

    	} catch( any e ){
    		writeLog("Exception in FilePublisher: #e.message#");
    	}

    	return outputFile;

		</cfscript>

    </cffunction>

    <cffunction name="getFileName" output="false" access="public" returntype="string" hint="">

    	<cfreturn "#getTickCount()#.log">
    </cffunction>

</cfcomponent>