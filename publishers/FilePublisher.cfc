/*
* Writes parse results to a file
*/

component output="false"{

	public function init( string fileOutputDir, string fieldDelimiter="#chr(9)#", boolean showHeaders=true){

		structAppend( variables, arguments );
		createObject("java", "java.io.File").init(fileOutputDir).mkdirs();
		var headerFields = ["template", "method", "args", "totalExecutionTime"];
		variables.header = arrayToList(headerFields, fieldDelimiter) & chr(10);
		return this;
	}

	/**
	* @data An array of structs. Each struct will contain fields: template, method, args, totalExecutionTime
	*/
	public function publish( array data ){

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
	}

	private function getFileName(){
		return "#getTickCount()#.log";
	}
}
