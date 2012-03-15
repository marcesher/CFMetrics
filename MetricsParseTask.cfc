<cfcomponent>

	<cffunction name="init" output="false" access="public" returntype="any" hint="">
    	<cfargument name="metricsQuery" type="query" required="true"/>
		<cfset structAppend( variables, arguments )>
    </cffunction>

	<cffunction name="call" output="false" access="public" returntype="any" hint="">
    	<cfset var result = createMetrics( variables.metricsQuery )>

		<cfreturn result>
    </cffunction>



    <cffunction name="createMetrics" output="false" access="public" returntype="array" hint="">
		<cfargument name="metricsQuery" type="query" required="true"/>

		<cfset var all = []>
		<cfloop query="metricsQuery">
			<cfset var result = parseTemplate(metricsQuery.template)>
			<cfset result.totalExecutionTime = metricsQuery.totalExecutionTime>
			<cfset arrayAppend( all, result )>
		</cfloop>
		<cfreturn all>
	</cffunction>

	<!---<cfdump var="#data#">--->

	<cffunction name="parseTemplate" output="false" access="public" returntype="any" hint="">
    	<cfargument name="template" type="string" required="true"/>
		<cfset var result = {found = false, template = template, method="", args=""}>
		<cfset var templateAndMethod = reMatch("CFC\[ .*\]", template)>
		<cfif arrayLen(templateAndMethod) eq 1>
			<cfset var tmp = templateAndMethod[1]>
			<cfset var f = trim(replace(listFirst(tmp, "|" ), "CFC[", "", "one"))>
			<cfset var method = trim(replace(listLast(tmp, "|" ), ") ]", ")", "one"))>


			<cfset var args = trim(reMatch("\(.*\)", method)[1])>
			<cfset args = mid( args,2, len(args)-2 )>
			<!--- if we have linebreaks in the args, just truncate it at the first break --->
			<cfset args = left(reReplace(args, "#chr(13)#|#chr(10)#"," ", "all"), 200)>
			<cfset method = listFirst(method, "(")>
			<cfset result = {found = true, template = f, method = method, args = args}>
		</cfif>
		<cfreturn result>
    </cffunction>



</cfcomponent>