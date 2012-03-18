<cfcomponent>
<cfscript>
	


	function createUniqueFileName(fullPath){
	    var extension = "";
	    var thePath = "";
	    var newPath = arguments.fullPath;
	    var counter = 0;
	    
	    if(listLen(arguments.fullPath,".") gte 2) extension = listLast(arguments.fullPath,".");
	    thePath = listDeleteAt(arguments.fullPath,listLen(arguments.fullPath,"."),".");
	
	    while(fileExists(newPath)){
	        counter = counter+1;        
	        newPath = thePath & "_" & counter & "." & extension;            
	    }
	    return newPath;    
	}
</cfscript>

	<cffunction name="cffile" output="false" access="public" returntype="any" hint="">    
		<cffile attributecollection="#arguments#">		
    </cffunction>

</cfcomponent>