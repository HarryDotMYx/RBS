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
		// Enforce CSRF token checks on state-changing requests.
		protectsFromForgery(with="exception");
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
	public void function updateCustomFields(required string objectname, required numeric key, struct customfields={}) {
		if(!isStruct(arguments.customfields) || structIsEmpty(arguments.customfields)){
			return;
		}
	 	for(field in arguments.customfields){
	 		var safeFieldId = isNumeric(field) ? val(field) : 0;
	 		if(safeFieldId LTE 0){
	 			continue;
	 		}
	 		checkValue=model("customfieldjoin").findOne(where="customfieldsid=#safeFieldId# AND customfieldchildid = #val(arguments.key)#");
	 		if(isObject(checkValue)){
	 			updateValue=model("customfieldvalue").findOne(where="id = #checkValue.customfieldvalueid#");
	 			updateValue.update(value=arguments.customfields[field]);
	 		} else {
	 			newValue=model("customfieldvalues").create(value=arguments.customfields[field]);
	 			newJoin=model("customfieldjoin").create(
	 				customfieldsid=safeFieldId,
	 				customfieldchildid=val(arguments.key),
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

	// Permission checking — wired from events/functions.cfm logic
	public boolean function checkPermission(required string permission) {
		if(_permissionsSetup() && structKeyExists(application.rbs.permission, arguments.permission)) {
			var retValue = application.rbs.permission[arguments.permission][_returnUserRole()];
			return (retValue == 1);
		}
		return false;
	}

	public void function checkPermissionAndRedirect(required string permission) {
		if(!checkPermission(arguments.permission)){
			redirectTo(route="denied", error="Sorry, you have insufficient permission to access this. If you believe this to be an error, please contact an administrator.");
		}
	}

	public boolean function isLoggedIn() {
		return (structKeyExists(session, "currentuser") && isStruct(session.currentuser))
			|| (structKeyExists(session, "currentUser") && isStruct(session.currentUser));
	}

	/**
	*  @hint Redirect to login if not authenticated — usable as a filter
	*/
	public void function _checkLoggedIn() {
		if(!isLoggedIn()){
			redirectTo(route="login");
		}
	}

	/**
	*  @hint Reject non-POST requests for state-changing actions
	*/
	public boolean function requirePostRequest() {
		var requestMethod = "";
		var tokenValue = "";
		if(structKeyExists(cgi, "request_method")){
			requestMethod = uCase(cgi.request_method);
		}
		if(requestMethod != "POST"){
			redirectTo(route="denied", error="Invalid request method.");
			return false;
		}
		if(structKeyExists(params, "authenticityToken")){
			tokenValue = trim(params.authenticityToken & "");
		}
		if(!len(tokenValue)){
			try {
				var reqData = getHttpRequestData();
				if(structKeyExists(reqData, "headers") AND isStruct(reqData.headers)){
					if(structKeyExists(reqData.headers, "X-CSRF-Token")){
						tokenValue = trim(reqData.headers["X-CSRF-Token"] & "");
					} else if(structKeyExists(reqData.headers, "x-csrf-token")){
						tokenValue = trim(reqData.headers["x-csrf-token"] & "");
					}
				}
			} catch(any e) {
				tokenValue = "";
			}
		}
		if(!len(tokenValue) OR !CsrfVerifyToken(tokenValue)){
			redirectTo(route="denied", error="Invalid authenticity token.");
			return false;
		}
		return true;
	}

	/**
	*  @hint Redirect logged-in users away — usable as a filter (Sessions)
	*/
	public void function redirectIfLoggedIn() {
		if(isLoggedIn()){
			redirectTo(route="home");
		}
	}

	/**
	*  @hint Load current user object into scope — usable as a filter
	*/
	public void function getCurrentUser() {
		var cu = currentUser();
		var safeUserId = structKeyExists(cu, "id") ? val(cu.id) : 0;
		var safeEmail = structKeyExists(cu, "email") ? trim(cu.email & "") : "";
		var userLookup = queryNew("");
		if(safeUserId LTE 0 OR !len(safeEmail)){
			redirectTo(route="home", error="Sorry, we couldn't find your account.");
			return;
		}
		userLookup = queryExecute(
			"SELECT id FROM users WHERE id = ? AND email = ? LIMIT 1",
			[safeUserId, safeEmail],
			{datasource=application.wheels.datasourcename}
		);
		if(userLookup.recordCount){
			user = model("user").findByKey(val(userLookup.id[1]));
		}
		if(!isObject(user)){
			redirectTo(route="home", error="Sorry, we couldn't find your account.");
		}
	}

	/**
	*  @hint Load all roles into scope — usable as a filter
	*/
	public void function _getRoles() {
		variables.roles = application.rbs.roles;
	}

	/**
	*  @hint Set request model type — usable as a filter
	*/
	public void function _setModelType() {
		if(structKeyExists(application.rbs, "modeltypes")){
			request.modeltype = lCase(variables.$class.name);
		}
	}

	/**
	*  @hint Deny access in demo mode — usable as a filter
	*/
	public void function denyInDemoMode() {
		if(structKeyExists(application, "rbs") && structKeyExists(application.rbs, "setting") && application.rbs.setting.isdemomode){
			redirectTo(route="home", error="Disabled in Demo Mode");
		}
	}

	/**
	*  @hint Returns true if user is in a specified role
	*/
	public boolean function userIsInRole(required string role) {
		if(isLoggedIn()){
			if(structKeyExists(session.currentuser, "role") && session.currentuser.role == arguments.role){
				return true;
			}
		}
		return false;
	}

	/**
	*  @hint Returns current user role or "guest"
	*/
	public string function _returnUserRole() {
		if(_permissionsSetup() && isLoggedIn() && structKeyExists(session.currentuser, "role")){
			return session.currentuser.role;
		}
		return "guest";
	}

	/**
	*  @hint Checks if permissions are set up in application scope
	*/
	public boolean function _permissionsSetup() {
		return (structKeyExists(application, "rbs") && structKeyExists(application.rbs, "permission"));
	}

	/**
	*  @hint Check admin flag for locations
	*/
	public void function f_checkLocationsAdmin() {
		// placeholder for locations admin check — passes through by default
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
		var sr = createObject("java", "java.security.SecureRandom");
		return lCase(binaryEncode(sr.generateSeed(32), "hex"));
	}

	public string function createSalt() {
		return encrypt(createUUID(), getAuthKey(), 'CFMX_COMPAT');
	}

	public string function decryptSalt(required string salt) {
		return decrypt(arguments.salt, getAuthKey(), 'CFMX_COMPAT');
	}

	public string function hashPassword(required string password, required string salt) {
		if(len(trim(arguments.salt & ""))){
			return hash(arguments.password & arguments.salt, 'SHA-512');
		}
		return hash(arguments.password, 'SHA-512');
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
		// Rotate session id on login to reduce session fixation risk.
		try {
			sessionRotate();
		} catch(any e) {
			// Older engines may not expose sessionRotate().
		}
		var scope = {
			id = user.id,
			firstname = user.firstname,
			lastname = user.lastname,
			email = user.email,
			tel = structKeyExists(user, "tel") ? user.tel : "",
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

	/**
	*  @hint Return cfmail-compatible SMTP settings from runtime env variables.
	*/
	public struct function getMailDeliverySettings() {
		var mailSettings = {};
		var smtpHost = _getRuntimeEnvValue("SMTP_HOST", "");
		var smtpPort = _getRuntimeEnvValue("SMTP_PORT", "");
		var smtpUsername = _getRuntimeEnvValue("SMTP_USERNAME", "");
		var smtpPassword = _getRuntimeEnvValue("SMTP_PASSWORD", "");
		var smtpTls = _getRuntimeEnvValue("SMTP_TLS", "");
		var smtpSsl = _getRuntimeEnvValue("SMTP_SSL", "");

		if (!len(smtpHost)) {
			return mailSettings;
		}

		mailSettings.server = smtpHost;

		if (len(smtpPort) && isNumeric(smtpPort)) {
			mailSettings.port = val(smtpPort);
		}
		if (len(smtpUsername)) {
			mailSettings.username = smtpUsername;
		}
		if (len(smtpPassword)) {
			mailSettings.password = smtpPassword;
		}
		if (len(smtpTls)) {
			mailSettings.useTLS = _toBooleanEnvValue(smtpTls);
		}
		if (len(smtpSsl)) {
			mailSettings.useSSL = _toBooleanEnvValue(smtpSsl);
		}

		return mailSettings;
	}

	/**
	*  @hint Read runtime env values from OS env first, then `.env` values loaded in `Application.cfc`.
	*/
	private string function _getRuntimeEnvValue(required string key, string defaultValue="") {
		try {
			local.systemValue = createObject("java", "java.lang.System").getenv(arguments.key);
			if (!isNull(local.systemValue) && len(trim(local.systemValue))) {
				return trim(local.systemValue);
			}
		} catch(any e) {
			// Ignore and fallback.
		}

		if (
			structKeyExists(application, "env")
			&& structKeyExists(application.env, arguments.key)
			&& len(trim(application.env[arguments.key] & ""))
		) {
			return trim(application.env[arguments.key] & "");
		}

		return arguments.defaultValue;
	}

	/**
	*  @hint Parse an env value into boolean.
	*/
	private boolean function _toBooleanEnvValue(required any value) {
		if (isBoolean(arguments.value)) {
			return arguments.value;
		}
		return listFindNoCase("1,true,yes,on", trim(arguments.value & "")) GT 0;
	}


}
