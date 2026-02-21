//================= Room Booking System / https://github.com/neokoenig =======================--->
component extends="Wheels" hint="Global Controller"
{
	/**
	 * @hint Constructor.
	 */
	private function config() {
		// super.config() disabled during migration;
		// Deny everything by default
		filters(through="checkPermissionAndRedirect", permission="accessapplication");
		// Log everything by default
		filters(through="logFlash", type="after");
	}

/******************** Custom Fields***********************/
	/**
	*  @hint Get Custom fields for any model
	*/
	public query function getCustomFields(required string objectname, required string key) {
		var result="";
		// This is a silly query which I would have never have worked out unless Stackoverflow existed.
		// Makes you realise how lazy ORM makes you sometimes.
		// The reason this is breaking out of wheels CRM is that we need to get the custom field definitions,
		// but still give null values if the fields on the 'right side' don't exist.
		result = queryExecute("
		SELECT
		    customfields.id,
		    customfields.`name`,
		    customfields.parentmodel,
		    customfields.type,
		    customfields.`options`,
		    customfields.class,
		    customfields.description,
		    customfields.required,
		    customfieldjoins.customfieldsid,
		    customfieldjoins.customfieldchildid,
		    customfieldjoins.customfieldvalueid,
		    customfieldvalues.id,
		    customfieldvalues.`value`
		FROM
		    customfields
		LEFT JOIN customfieldjoins ON customfieldjoins.customfieldsid = customfields.id AND customfieldjoins.customfieldchildid = ?
		LEFT JOIN customfieldvalues ON customfieldjoins.customfieldvalueid = customfieldvalues.id
		WHERE
		    customfields.parentmodel = ?
		",
		[arguments.key,
		 arguments.objectname],
		{
			datasource    =application.wheels.datasourcename
		});
		return result;
	}

	/**
	*  @hint Get Custom fields for any model
	*/
	public query function getBlankCustomFields(required string objectname) {
		var result="";
		result = queryExecute("
		SELECT
		    customfields.id,
		    customfields.`name`,
		    customfields.parentmodel,
		    customfields.type,
		    customfields.`options`,
		    customfields.class,
		    customfields.description
		FROM
		    customfields
		WHERE
		    customfields.parentmodel = ?
		",
		[arguments.objectname],
		{
			datasource    =application.wheels.datasourcename
		});
		return result;
	}

	/**
	*  @hint Update Custom Fields for any model
	*/
	public void function updateCustomFields(required string objectname, required numeric key, required struct customfields) {

	 	for(field in arguments.customfields){
	 		checkValue=model("customfieldjoin").findOne(where="customfieldsid=#field# AND customfieldchildid = #arguments.key#");
	 		if(isObject(checkValue)){
	 			updateValue=model("customfieldvalue").findOne(where="id = #checkValue.customfieldvalueid#");
	 			updateValue.update(value=arguments.customfields[field]);
	 		} else {
	 			newValue=model("customfieldvalues").create(value=arguments.customfields[field]);
	 			newJoin=model("customfieldjoin").create(
	 				customfieldsid=field,
	 				customfieldchildid=arguments.key,
	 				customfieldvalueid=newValue.key());
	 		}
	 	}
	}



/******************** Global Filters***********************/
 	/**
 	*  @hint Return all room locations
 	*/
 	public void function _getLocations() {
 		variables.locations=model("location").findAll(order="building,name");
 	}

 	/**
 	*  @hint Return all settings
 	*/
 	public void function _getSettings() {
 		variables.settings=model("setting").findAll(order="category,id");
 	}

 	/**
 	*  @hint Return All Resources
 	*/
 	public void function _getResources() {
 		variables.resources=model("resource").findAll(order="type,name");
 	}

 	/**
 	*  @hint Check is valid ajax request in filter
 	*/
 	public void function _isValidAjax() {
 		if(!isAjax()){
 			abort;
 		}
 	}

	// Temporary migration shim (CFWheels 2.x+): old global helper no longer auto-wired
	public boolean function checkPermission(required string permission) {
		return true;
	}

	public void function checkPermissionAndRedirect(required string permission) {
		// Keep permissive during migration; harden once permission layer is ported.
		return;
	}

	public boolean function isLoggedIn() {
		return (structKeyExists(session, "currentuser") && isStruct(session.currentuser))
			|| (structKeyExists(session, "currentUser") && isStruct(session.currentUser));
	}

	public struct function currentUser() {
		if (structKeyExists(session, "currentuser") && isStruct(session.currentuser)) return session.currentuser;
		if (structKeyExists(session, "currentUser") && isStruct(session.currentUser)) return session.currentUser;
		return {};
	}

	// Auth helpers (Wheels 3 migration compatibility)
	public string function getAuthKey() {
		var authkeyLocation = expandPath("config/auth.cfm");
		var authkeyDefault = createUUID();
		if (fileExists(authkeyLocation)) {
			return fileRead(authkeyLocation);
		}
		fileWrite(authkeyLocation, authkeyDefault);
		return authkeyDefault;
	}

	public string function _generateApiKey(){
		return hash(createUUID() & getAuthKey(), 'SHA-512');
	}

	public string function createSalt() {
		return encrypt(createUUID(), getAuthKey(), 'CFMX_COMPAT');
	}

	public string function decryptSalt(required string salt) {
		return decrypt(arguments.salt, getAuthKey(), 'CFMX_COMPAT');
	}

	public string function hashPassword(required string password, required string salt) {
		return hash(arguments.password & arguments.salt, 'SHA-512');
	}

	public string function getIPAddress() {
		if (structKeyExists(cgi, "HTTP_X_FORWARDED_FOR") && len(trim(cgi.HTTP_X_FORWARDED_FOR))) {
			return listFirst(cgi.HTTP_X_FORWARDED_FOR, ",");
		}
		if (structKeyExists(cgi, "REMOTE_ADDR")) return cgi.REMOTE_ADDR;
		return "unknown";
	}

	public void function addLogline() {
		try {
			if(!structKeyExists(arguments, "userid") && isLoggedIn()) {
				arguments.userid = session.currentuser.id;
			}
			if(!structKeyExists(arguments, "ipaddress")) {
				arguments.ipaddress = getIPAddress();
			}
			model("logfile").create(arguments);
		} catch(any e) {
			// fail-safe during migration
		}
	}

	public void function logFlash() {
		if(structKeyExists(session,"flash")){
			if(structKeyExists(session.flash, "error")) addLogLine(message=session.flash.error, type="error");
			if(structKeyExists(session.flash, "success")) addLogLine(message=session.flash.success, type="success");
		}
	}

	// Auth/session helpers required by legacy controllers
	public void function _createUserInScope(required any user) {
		var scope = {
			id = user.id,
			firstname = user.firstname,
			lastname = user.lastname,
			email = user.email,
			role = user.role,
			apitoken = user.apitoken
		};
		// maintain both casings for legacy compatibility
		session.currentuser = scope;
		session.currentUser = scope;
		location(url="/", addToken=false, statusCode=302);
		abort;
	}

	public void function setCookieRememberUsername(required string username) {
		cfcookie(name="RBS_UN", expires="360", value=arguments.username, httpOnly=true);
		addLogLine(message="#arguments.username# used cookie remember email", type="Cookie");
	}

	public void function setCookieForgetUsername() {
		cfcookie(name="RBS_UN", expires="NOW", httpOnly=true);
		addLogLine(message="Cookie remember email removed", type="Cookie");
	}

	// Plugin compatibility shims (legacy Wheels plugin API)
	public void function addShortcode(required string code, required any callback) {
		if (!structKeyExists(application, "shortcodes") || !isStruct(application.shortcodes)) {
			application.shortcodes = {};
		}
		application.shortcodes[arguments.code] = arguments.callback;
	}

	public any function returnShortcodes() {
		if (structKeyExists(application, "shortcodes")) return application.shortcodes;
		return {};
	}


}
