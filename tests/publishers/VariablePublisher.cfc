component{

	variables.published = [];

	function publish(data){
		published.addAll(data);
		return published;
	}

	function getPublished(){
		return published;
	}

}