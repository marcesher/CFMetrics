/*
* Writes parse results to a file
*/

component output="false"{

	/**
	* @applicationName The name of the application
	* @fileOutputDir The directory where files should be written. If it does not exist it will be created.
	* @fieldDelimiter The character(s) to use to delimit header and data row fields. Defaults to tab
	* @showHeader Whether to add the header row to the output file
	* @rolloverFileSize Approximate Size in KB when file will be rolled over
	*/
	public function init( string applicationName, string fileOutputDir, string fieldDelimiter="#chr(9)#", boolean showHeader=true, rolloverFileSize=1024){

		structAppend( variables, arguments );
		createObject("java", "java.io.File").init(fileOutputDir).mkdirs();
		var headerFields = ["template", "method", "args", "timestamp", "scriptName", "queryString", "totalExecutionTime"];
		variables.header = arrayToList(headerFields, fieldDelimiter) & chr(10);
		variables.fileNameStub = dateFormat(now(), "mm_dd_yyyy") & "_" & timeFormat(now(), "hh_mm_ss");
		variables.fileUtil = createObject( "component", "cfmetrics.util.FileUtil" );
		
		return this;
	}
	
	private function initializeOutputFile(){
		
		var fileName = variables.fileNameStub & ".log";
		variables.outputFile = fileOutputDir & "/" & fileName;
		
		if( requiresNewFile() ){
			variables.outputFile = fileUtil.createUniqueFileName(fileOutputDir & "/" & fileName);
			writeLog("FilePublisher: Creating new output file #variables.outputFile#");
			var output = showHeader ? variables.header : "";
			fileWrite( outputFile, output );
		}
	}
	
	private function requiresNewFile(){
		return NOT fileExists( outputFile ) 
			OR getFileInfo( variables.outputFile ).size / 1024 GT rolloverFileSize;
	}
	

	/**
	* @data An array of structs. Each struct will contain fields: template, method, args, totalExecutionTime
	*/
	public function publish( array data ){ 

		initializeOutputFile();
		
    	try{
			var d = variables.fieldDelimiter;
			var stringData = "";
			
			for( var result in data ){
				stringData &= "#result.template##d##result.method##d##result.args##d##result.timestamp##d##result.scriptName##d##result.queryString##d##result.totalExecutionTime##chr(10)#";
			}

			if(stringData neq ""){
				fileUtil.cffile(action="append", file=variables.outputFile, output=stringData);
			}

    	} catch( any e ){
    		writeLog("Exception in FilePublisher: #e.message#");
    	}
		

    	return outputFile;
	}

}
