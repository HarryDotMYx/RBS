//================= Room Booking System / https://github.com/neokoenig =======================--->
component extends="Controller" hint="Resources Controller"
{
	/**
	 * @hint Constructor.
	 */
	private function config() {
		
		// super.config() disabled during migration;
// Permission filters
		// legacy super.init removed for CFWheels2+
		protectsFromForgery(with="exception");
		filters(through="requirePostRequest", only="create,update,delete");

		// Permissions
		filters(through="checkPermissionAndRedirect", permission="accessresources");
		filters(through="_checkResourcesAdmin");
		//filters(through="_isValidAjax", only="checkavailability");

		// Data
		filters(through="_getresources", only="index");
		filters(through="_getLocations");

		// Verification
		verifies(only="view,edit,update,delete", params="key", paramsTypes="integer", route="home", error="Sorry, that event can't be found");


		// Format
		provides("html,json");
	}

/******************** Public***********************/
	/**
	*  @hint Add Resource
	*/
	public void function add() {
		resource=model("resource").new();
	}

	/**
	*  @hint Create Resource
	*/
	public void function create() {
		if(!requirePostRequest()){
			return;
		}
		if(structkeyexists(params, "resource")){
	    	resource = model("resource").new(params.resource);
			if ( resource.save() ) {
				redirectTo(action="index", success="resource successfully created");
			}
	        else {
				renderView(action="add", error="There were problems creating that resource");
			}
		}
	}

	/**
	*  @hint Edit Resource
	*/
	public void function edit() {
		resource=model("resource").findOne(where="id = #val(params.key)#");
	}

	/**
	*  @hint Update Resource
	*/
	public void function update() {
		if(!requirePostRequest()){
			return;
		}
		if(structkeyexists(params, "resource")){
	    	resource = model("resource").findOne(where="id = #val(params.key)#");
			resource.update(params.resource);
			if ( resource.save() )  {
				redirectTo(action="index", success="resource successfully updated");
			}
	        else {
				renderView(action="edit", error="There were problems updating that resource");
			}
		}
	}

	/**
	*  @hint Delete Resource
	*/
	public void function delete() {
		if(!requirePostRequest()){
			return;
		}
	    	resource = model("resource").findOne(where="id = #val(params.key)#");
		if ( resource.delete() )  {
			redirectTo(action="index", success="resource successfully deleted");
		}
        else {
			redirectTo(action="index", error="There were problems deleting that resource");
		}
	}

/******************** Private *********************/
	/**
	*  @hint
	*/
	public void function _checkResourcesAdmin() {
		if (!application.rbs.setting.allowResources){
			redirectTo(route="home", error="Facility to add/edit resources has been disabled");
		}
	}
/******************** Ajax/Remote/Misc*************/
	/**
	*  @hint Bit of a hack, but a quick lookup to see if a resource is already booked
	*/
	public void function checkavailability() {
		param name="params.id" default="" type="numeric";
		param name="params.eventid" default="" type="numeric";
		param name="params.start" default="" type="string";
		param name="params.end" default="" type="string";
		if(!isDate(params.start) OR val(params.id) LTE 0){
			renderText(0);
			return;
		}
		var safeResourceId = val(params.id);
		var safeEventId = val(params.eventid);
		var safeStart = parseDateTime(params.start);
		var safeEnd = isDate(params.end) ? parseDateTime(params.end) : dateAdd("h", 1, safeStart);
		var safeStartLiteral = createODBCDateTime(safeStart);
		var safeEndLiteral = createODBCDateTime(safeEnd);
		// Check for any events which may have booked the unique resource in the given timeframe, excluding the event itself
		checkEvent=model("event").findAll(
			where="start <= #safeStartLiteral# AND end >= #safeEndLiteral# AND id != #safeEventId# AND resourceid = #safeResourceId#",
			include="eventresources");
		/* Check for events with an All Day flag which might have incorrect timings set; this shouldn't affect events which span multiple days, as the above check (should) pick them up;*/
			tempstart=dateFormat(safeStart, "yyyy-mm-dd") & ' ' & timeFormat(safeStart, "00:00");
			tempend=dateFormat(safeEnd, "yyyy-mm-dd") & ' ' & timeFormat(safeEnd, "23:59");
		checkEvent2=model("event").findAll(
			where="start >= '#tempstart#' AND end <= '#tempend#' AND id != #safeEventId# AND allday=1 AND resourceid=#safeResourceId#",
			include="eventresources");

		if(checkEvent.recordCount OR checkEvent2.recordcount){
			renderText(0);
		} else {
			renderText(1);
		}


	}
}
