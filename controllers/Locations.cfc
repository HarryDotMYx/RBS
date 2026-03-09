//================= Room Booking System / https://github.com/neokoenig =======================--->
component extends="Controller" hint="Locations Controller"
{
	/**
	 * @hint Constructor.
	 */
	public void function config() {
		
		// super.config() disabled during migration;
// Permission filters
		// legacy super.init removed for CFWheels2+
		protectsFromForgery(with="exception");
		filters(through="requirePostRequest", only="create,update,delete");

		// Permissions
		filters(through="f_checkLocationsAdmin");
		filters(through="checkPermissionAndRedirect", permission="accessLocations", except="list,view");
		filters(through="checkPermissionAndRedirect", permission="accessCalendar", except="list,view");
		filters(through="_setModelType");
		// Data
		filters(through="_getLocations");

		// Verification
		verifies(only="view,edit,update,delete", params="key", paramsTypes="integer", route="home", error="Sorry, that event can't be found");

	}

/******************** Admin ***********************/
	/**
	*  @hint Public Location List
	*/
	public void function list() {
	}

	/**
	*  @hint
	*/
	public void function view() {
		location=model("location").findOne(where="id = #val(params.key)#");
		if (!isObject(location)) {
			redirectTo(action="index", error="Sorry, that location can't be found");
			return;
		}
		customfields=getCustomFields(objectname=request.modeltype, key=location.key());
	}
/******************** Admin ***********************/
	/**
	*  @hint Add Location
	*/
	public void function add() {
		location=model("location").new();
		customfields=getCustomFields(objectname=request.modeltype, key=location.key());
	}

	/**
	*  @hint Create Location
	*/
	public void function create() {
		if(!requirePostRequest()){
			return;
		}
		if(structkeyexists(params, "location")){
	    	location = model("location").new(params.location);
			if ( location.save() ) {
				redirectTo(action="index", success="location successfully created");
			}
	        else {
				renderView(action="add", error="There were problems creating that location");
			}
		}
	}

	/**
	*  @hint Edit  Location
	*/
	public void function edit() {
		location=model("location").findOne(where="id = #val(params.key)#");
		request.modeltype="location";
		customfields=getCustomFields(objectname=request.modeltype, key=params.key);

	}

	/**
	*  @hint Update Location
	*/
	public void function update() {
		if(!requirePostRequest()){
			return;
		}
		if(structkeyexists(params, "location")){
			location = model("location").findOne(where="id = #val(params.key)#");
			location.update(params.location);
			if ( location.save() )  {
				if(structkeyexists(params, "customfields") AND isStruct(params.customfields)){
					customfields=updateCustomFields(objectname="location", key=params.key, customfields=params.customfields);
				}
				redirectTo(action="index", success="Location successfully updated");
			}
	        else {
				renderView(action="edit", error="There were problems updating that Location");
			}
		}
	}

	/**
	*  @hint Delete Location
	*/
	public void function delete() {
		if(!requirePostRequest()){
			return;
		}
		checkLocation=model("location").findAll();
		if(checkLocation.recordcount GT 1){
			 if(structkeyexists(params, "key")){
			    	location = model("location").findOne(where="id = #val(params.key)#");
				if(!isObject(location)){
					redirectTo(action="index", error="That location no longer exists.");
					return;
				}
				queryExecute(
					"
						DELETE cfj
						FROM customfieldjoins cfj
						INNER JOIN customfields cf ON cf.id = cfj.customfieldsid
						INNER JOIN events e ON e.id = cfj.customfieldchildid
						WHERE cf.parentmodel = 'event'
						AND e.locationid = ?
					",
					[{value=val(location.id), cfsqltype="cf_sql_integer"}],
					{datasource=application.wheels.datasourcename}
				);
				queryExecute(
					"
						DELETE cfj
						FROM customfieldjoins cfj
						INNER JOIN customfields cf ON cf.id = cfj.customfieldsid
						WHERE cf.parentmodel = 'location'
						AND cfj.customfieldchildid = ?
					",
					[{value=val(location.id), cfsqltype="cf_sql_integer"}],
					{datasource=application.wheels.datasourcename}
				);
				queryExecute(
					"
						DELETE er
						FROM eventresources er
						INNER JOIN events e ON e.id = er.eventid
						WHERE e.locationid = ?
					",
					[{value=val(location.id), cfsqltype="cf_sql_integer"}],
					{datasource=application.wheels.datasourcename}
				);
				queryExecute(
					"DELETE FROM events WHERE locationid = ?",
					[{value=val(location.id), cfsqltype="cf_sql_integer"}],
					{datasource=application.wheels.datasourcename}
				);
				queryExecute(
					"DELETE FROM locations WHERE id = ?",
					[{value=val(location.id), cfsqltype="cf_sql_integer"}],
					{datasource=application.wheels.datasourcename}
				);
				queryExecute(
					"
						DELETE cfv
						FROM customfieldvalues cfv
						LEFT JOIN customfieldjoins cfj ON cfj.customfieldvalueid = cfv.id
						WHERE cfj.customfieldvalueid IS NULL
					",
					[],
					{datasource=application.wheels.datasourcename}
				);
				redirectTo(action="index", success="Location successfully deleted");
			}
		} else {
 			redirectTo(action="index", error="At least one Location is required.");
		}
	}
/******************** Private *********************/
	/**
	*  @hint Whether to allow access
	*/
	public void function f_checkLocationsAdmin() {
		if(!application.rbs.setting.allowLocations){
			redirectTo(route="home", error="Facility to edit Locations has been disabled");
		}
	}

	/**
	*  @hint Sets the model type to use with Custom Fields + Templates
	*/
	public void function _setModelType() {
		request.modeltype="location";
	}
}
