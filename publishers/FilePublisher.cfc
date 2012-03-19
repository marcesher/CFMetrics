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
	public function init( string applicationName, string fileOutputDir, string fieldDelimiter="#chr(9)#", boolean showHeader=true, rolloverFileSize=5000){

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
		
		if( NOT fileExists( outputFile ) OR fileRolloverRequired() ){
			variables.outputFile = fileUtil.createUniqueFileName(fileOutputDir & "/" & fileName);
			writeLog("FilePublisher: Creating new output file #variables.outputFile#");
			var output = showHeader ? variables.header : "";
			fileWrite( outputFile, output );
		}
	}
	
	private function fileRolloverRequired(){
		var fileSizeKB = getFileInfo( variables.outputFile ).size / 1024;
		if(fileSizeKB GT rolloverFileSize){
			writeLog("FilePublisher: rolling over file. Current size is #fileSizeKB# kb and max allowed is #rolloverFileSize# kb");
			return true;
		}
		return false;
	}
	

	/**
	* @data An array of structs. Each struct will contain fields: template, method, args, totalExecutionTime
	*/
	public function publish( array data ){ 

		initializeOutputFile();
		var startTick = getTickCount();
		var stringData = "";
		
    	try{
			stringData = dataToString( data );
			writeLog("FilePublisher: #getTickCount() - startTick# ms to create data string");

			if(stringData neq ""){
				fileUtil.cffile(action="append", file=variables.outputFile, output=stringData);
			}

    	} catch( any e ){
    		writeLog("Exception in FilePublisher: #e.message#");
    	}
		
		writeLog("FilePublisher: #getTickCount() - startTick# ms to publish #arrayLen(data)# rows");

    	return outputFile;
	}
	
	private function dataToString( array data ){
		var builder = createObject("java", "java.lang.StringBuilder");
		var d = variables.fieldDelimiter;
		for( var result in data ){
			//builder.append( "#result.template##d##result.method##d##result.args##d##result.timestamp##d##result.scriptName##d##result.queryString##d##result.totalExecutionTime##chr(10)#" );
			builder.append(result.template).append(d)
				.append(result.method).append(d)
				.append(result.args).append(d)
				.append(result.timestamp).append(d)
				.append(result.scriptName).append(d)
				.append(result.queryString).append(d)
				.append(result.totalExecutionTime).append(chr(10));
		}
		return builder.toString();
	}

}
