component output="false" {

	// Put variables we just need internally inside a wheels struct.
	this.wheels = {};
	this.wheels.rootPath = GetDirectoryFromPath(GetBaseTemplatePath());

	// Bootstrap fallback only; final app name is set after env load.
	this.name = Hash(this.wheels.rootPath);

	this.bufferOutput = true;

	// Set up the application paths.
	this.appDir     = expandPath("./");
	this.vendorDir  = expandPath("./vendor/");
	this.wheelsDir  = this.appDir & "wheels/";
	this.wireboxDir = this.vendorDir & "wirebox/";
	this.testboxDir = this.vendorDir & "testbox/";
	// Set up the mappings for the application.
	this.mappings["/app"]     = this.appDir;
	this.mappings["/vendor"]  = this.vendorDir;
	this.mappings["/wheels"]  = this.wheelsDir;
	this.mappings["/wirebox"] = this.wireboxDir;
	this.mappings["/testbox"] = this.testboxDir;
	this.mappings["/tests"] = expandPath("./tests");
	this.mappings["/config"] = expandPath("./config");
	this.mappings["/plugins"] = expandPath("./plugins");

	// We turn on "sessionManagement" by default since the Flash uses it.
	this.sessionManagement = true;

	// If a plugin has a jar or class file, automatically add the mapping to this.javasettings.
	this.wheels.pluginDir = this.appDir & "plugins";
	this.wheels.pluginFolders = DirectoryList(
		this.wheels.pluginDir,
		"true",
		"path",
		"*.class|*.jar|*.java"
	);

	for (this.wheels.folder in this.wheels.pluginFolders) {
		if (!StructKeyExists(this, "javaSettings")) {
			this.javaSettings = {};
		}
		if (!StructKeyExists(this.javaSettings, "LoadPaths")) {
			this.javaSettings.LoadPaths = [];
		}
		this.wheels.pluginPath = GetDirectoryFromPath(this.wheels.folder);
		if (!ArrayFind(this.javaSettings.LoadPaths, this.wheels.pluginPath)) {
			ArrayAppend(this.javaSettings.LoadPaths, this.wheels.pluginPath);
		}
	}

	// Put environment vars into env struct
	if ( !structKeyExists(this,"env") ) {
		this.env = {};
		
		// Load base .env file
		envFilePath = this.appDir & ".env";
		if (fileExists(envFilePath)) {
			loadEnvFile(envFilePath, this.env);
		}
		
		// Determine current environment
		currentEnv = "";
		if (structKeyExists(this.env, "WHEELS_ENV")) {
			currentEnv = this.env["WHEELS_ENV"];
		} else {
			// Try system environment variable
			try {
				javaSystem = createObject("java", "java.lang.System");
				systemEnv = javaSystem.getenv("WHEELS_ENV");
				if (!isNull(systemEnv) && len(systemEnv)) {
					currentEnv = systemEnv;
				}
			} catch (any e) {
				// Ignore errors accessing system environment
			}
		}
		
		// Load environment-specific .env file if it exists
		if (len(currentEnv)) {
			envSpecificPath = this.appDir & ".env." & currentEnv;
			if (fileExists(envSpecificPath)) {
				loadEnvFile(envSpecificPath, this.env);
			}
		}
		
		// Perform variable interpolation
		performVariableInterpolation(this.env);
	}

	// Build environment-aware app name to prevent session bleed between instances
	// (e.g. production on :8888 and development on :3999 sharing one host).
	variables.instanceName = trim(getRuntimeEnvValue("RBS_INSTANCE_NAME", ""));
	variables.wheelsEnvName = lCase(trim(getRuntimeEnvValue("WHEELS_ENV", "production")));
	if(len(variables.instanceName)){
		variables.sanitizedInstanceName = reReplaceNoCase(variables.instanceName, "[^a-z0-9_-]", "", "all");
		if(len(variables.sanitizedInstanceName)){
			this.name = "RoomBooking-" & variables.sanitizedInstanceName;
		} else {
			this.name = Hash(this.wheels.rootPath & "|" & variables.wheelsEnvName);
		}
	} else {
		this.name = Hash(this.wheels.rootPath & "|" & variables.wheelsEnvName);
	}

	// Configure datasources at runtime so DB host/credentials can be controlled via environment variables.
	variables.runtimeDbHost = getRuntimeEnvValue("DB_HOST", "db");
	variables.runtimeDbPort = getRuntimeEnvValue("DB_PORT", "3306");
	variables.runtimeDbName = getRuntimeEnvValue("DB_NAME", "roombooking");
	variables.runtimeDbUser = getRuntimeEnvValue("DB_USER", "roombooking");
	variables.runtimeDbPassword = getRuntimeEnvValue("DB_PASSWORD", "roombooking123");
	variables.runtimeDbCustom = "useUnicode=true&characterEncoding=UTF-8&useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC";
	variables.baseDatasource = {
		type = "mysql",
		host = variables.runtimeDbHost,
		port = variables.runtimeDbPort,
		database = variables.runtimeDbName,
		username = variables.runtimeDbUser,
		password = variables.runtimeDbPassword,
		connectionLimit = 100,
		connectionTimeout = 1,
		metaCacheTimeout = 60000,
		blob = true,
		clob = true,
		validate = false,
		storage = false,
		custom = variables.runtimeDbCustom
	};
	this.datasources = {
		roombooking = duplicate(variables.baseDatasource),
		app = duplicate(variables.baseDatasource)
	};

	function onServerStart() {}

	include "./config/app.cfm";

	function onApplicationStart() {
		wirebox = new wirebox.system.ioc.Injector("wheels.Wirebox");
		if (structKeyExists(this, "env") && isStruct(this.env)) {
			application.env = duplicate(this.env);
		}

		/* wheels/global object */
		application.wo = wirebox.getInstance("global");
		initArgs.path="wheels";
		initArgs.filename="onapplicationstart";
		application.wirebox.getInstance(name = "wheels.events.onapplicationstart", initArguments = initArgs).$init(this);
	}

	public void function onApplicationEnd( struct ApplicationScope ) {
		application.wo.$include(
			template = "../../#arguments.applicationScope.wheels.eventPath#/onapplicationend.cfm",
			argumentCollection = arguments
		);
	}

	public void function onSessionStart() {
		local.lockName = "reloadLock" & this.name;

		// Fix for shared application name (issue 359).
		if (!StructKeyExists(application, "wheels") || !StructKeyExists(application.wheels, "eventpath")) {
			local.executeArgs = {"componentReference" = "application"};

			application.wo.$simpleLock(name = local.lockName, execute = "onApplicationStart", type = "exclusive", timeout = 180, executeArgs = local.executeArgs);
		}

		local.executeArgs = {"componentReference" = "wheels.events.EventMethods"};
		application.wo.$simpleLock(name = local.lockName, execute = "$runOnSessionStart", type = "readOnly", timeout = 180, executeArgs = local.executeArgs);
	}

	public void function onSessionEnd( struct SessionScope, struct ApplicationScope ) {
		local.lockName = "reloadLock" & this.name;

		arguments.componentReference = "wheels.events.EventMethods";
		application.wo.$simpleLock(
			name = local.lockName,
			execute = "$runOnSessionEnd",
			executeArgs = arguments,
			type = "readOnly",
			timeout = 180
		);
	}

	public boolean function onRequestStart( string targetPage ) {

		// Added this section so that whenever the format parameter is passed in the URL and it is junit, json or txt then the content will be served without the head and body tags
		if(structKeyExists(url, "format") && listFindNoCase("junit,json,txt", url.format))
		{
			application.contentOnly = true;
		}else{
			application.contentOnly = false;
		}
		setResponseSecurityHeaders();

		local.lockName = "reloadLock" & this.name;

		// Abort if called from incorrect file.
		application.wo.$abortInvalidRequest();

		// Fix for shared application name issue 359.
		if (!StructKeyExists(application, "wheels") || !StructKeyExists(application.wheels, "eventPath")) {
			this.onApplicationStart();
		}

		// Need to setup the wheels struct up here since it's used to store debugging info below if this is a reload request.
		application.wo.$initializeRequestScope();

		// IP-based access to public Component/debug GUI (only if allowed in settings)
		if (!structKeyExists(application.wheels, "debugIPAccess")) {
			application.wheels.debugIPAccess.originalEnablePublicComponent = application.wheels.enablePublicComponent;
			application.wheels.debugIPAccess.originalShowDebugInformation  = application.wheels.showDebugInformation;
			application.wheels.debugIPAccess.originalShowErrorInformation  = application.wheels.showErrorInformation;
		}

		// Conditional override for allowed IPs (but only in non-dev mode)
		if (
			StructKeyExists(application.wheels, "allowIPBasedDebugAccess") &&
			application.wheels.environment != "development" &&
			(application.wheels.allowIPBasedDebugAccess)
		) {
			local.clientIP = CGI.HTTP_X_FORWARDED_FOR ?: CGI.REMOTE_ADDR;
			local.allowedIPs = application.wheels.debugAccessIPs;

			if (arrayContains(local.allowedIPs, local.clientIP)) {
				// Temporarily override — per request
				application.wheels.enablePublicComponent = true;
				application.wheels.showDebugInformation = true;
				application.wheels.showErrorInformation = true;

				// Enable the main GUI Component
				application.wheels.public = application.wo.$createObjectFromRoot(path = "wheels", fileName = "Public", method = "$init");
			} else {
				application.wheels.enablePublicComponent = application.wheels.debugIPAccess.originalEnablePublicComponent;
				application.wheels.showDebugInformation = application.wheels.debugIPAccess.originalShowDebugInformation;
				application.wheels.showErrorInformation = application.wheels.debugIPAccess.originalShowErrorInformation;
			}
		}

			// Reload application only when an explicit configured password is provided and matches.
			if (StructKeyExists(url, "reload")) {
				if (
					!StructKeyExists(application, "wheels")
					|| !StructKeyExists(application.wheels, "reloadPassword")
					|| !len(application.wheels.reloadPassword)
				) {
					writeLog(type="warning", text="RBS_RELOAD_BLOCKED reason=reloadPassword_not_configured");
					return true;
				}
				if (!StructKeyExists(url, "password") || url.password != application.wheels.reloadPassword) {
					writeLog(type="warning", text="RBS_RELOAD_BLOCKED reason=invalid_password");
					return true;
				}
				application.wo.$debugPoint("total,reload");
				if (StructKeyExists(url, "lock") && !url.lock) {
					this.$handleRestartAppRequest();
				} else {
					local.executeArgs = {"componentReference" = "application"};
					application.wo.$simpleLock(name = local.lockName, execute = "$handleRestartAppRequest", type = "exclusive", timeout = 180, executeArgs = local.executeArgs);
				}
				return false; // Stop processing this request after restart
			}

		// Run the rest of the request start code.
		arguments.componentReference = "wheels.events.EventMethods";
		application.wo.$simpleLock(
			name = local.lockName,
			execute = "$runOnRequestStart",
			executeArgs = arguments,
			type = "readOnly",
			timeout = 180
		);

		return true;
	}

	public boolean function onRequest( string targetPage ) {
		lock name="reloadLock#this.name#" type="readOnly" timeout="180" {
			include "#arguments.targetpage#";
		}

		return true;
	}

	public void function onRequestEnd( string targetPage ) {
		local.lockName = "reloadLock" & this.name;

		arguments.componentReference = "wheels.events.EventMethods";

		application.wo.$simpleLock(
			name = local.lockName,
			execute = "$runOnRequestEnd",
			executeArgs = arguments,
			type = "readOnly",
			timeout = 180
		);
		if (
			application.wheels.showDebugInformation && StructKeyExists(request.wheels, "showDebugInformation") && request.wheels.showDebugInformation
		) {
			if(!structKeyExists(url, "format")){
				application.wo.$includeAndOutput(template = "/wheels/events/onrequestend/debug.cfm");
			}
		}
	}

	public boolean function onAbort( string targetPage ) {
		if (
			StructKeyExists(application, "wo")
			&& StructKeyExists(application.wo, "$restoreTestRunnerApplicationScope")
		) {
			application.wo.$restoreTestRunnerApplicationScope();
			application.wo.$include(template = "../../#application.wheels.eventPath#/onabort.cfm");
		}
		return true;
	}

	public void function onError( any Exception, string EventName ) {
		wirebox = new wirebox.system.ioc.Injector("wheels.Wirebox");
		application.wo = wirebox.getInstance("global");

		// In case the error was caused by a timeout we have to add extra time for error handling.
		// We have to check if onErrorRequestTimeout exists since errors can be triggered before the application.wheels struct has been created.
		local.requestTimeout = application.wo.$getRequestTimeout() + 30;
		if (StructKeyExists(application, "wheels") && StructKeyExists(application.wheels, "onErrorRequestTimeout")) {
			local.requestTimeout = application.wheels.onErrorRequestTimeout;
		}
		setting requestTimeout=local.requestTimeout;

		application.wo.$initializeRequestScope();
		arguments.componentReference = "wheels.events.EventMethods";

		local.lockName = "reloadLock" & this.name;
		local.rv = application.wo.$simpleLock(
			name = local.lockName,
			execute = "$runOnError",
			executeArgs = arguments,
			type = "readOnly",
			timeout = 180
		);
		WriteOutput(local.rv);
	}

	public boolean function onMissingTemplate( string targetPage ) {
		local.lockName = "reloadLock" & this.name;

		arguments.componentReference = "wheels.events.EventMethods";

		application.wo.$simpleLock(
			name = local.lockName,
			execute = "$runOnMissingTemplate",
			executeArgs = arguments,
			type = "readOnly",
			timeout = 180
		);

		return true;
	}

	public void function $handleRestartAppRequest() {
		local.redirectUrl = this.$buildRedirectUrl();
		applicationStop();
		location(url = local.redirectUrl, addToken = false);
	}

	public string function $buildRedirectUrl() {
		// Determine the base URL
		if (StructKeyExists(cgi, "path_info") && Len(cgi.path_info)) {
			local.url = cgi.path_info;
		} else if (StructKeyExists(cgi, "path_info")) {
			local.url = "/";
		} else {
			local.url = cgi.script_name;
		}

		// Process query string parameters, removing reload-related ones
		if (StructKeyExists(cgi, "query_string") && Len(cgi.query_string)) {
			local.oldQueryString = ListToArray(cgi.query_string, "&");
			local.newQueryString = [];
			local.iEnd = ArrayLen(local.oldQueryString);
			
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.keyValue = local.oldQueryString[local.i];
				local.key = ListFirst(local.keyValue, "=");
				
				// Remove reload-related parameters
				if (!ListFindNoCase("reload,password,lock", local.key)) {
					ArrayAppend(local.newQueryString, local.keyValue);
				}
			}
			
			// Add query string to URL if any parameters remain
			if (ArrayLen(local.newQueryString)) {
				local.queryString = ArrayToList(local.newQueryString, "&");
				local.url = "#local.url#?#local.queryString#";
			}
		}

		return local.url;
	}

	/**
	 * Read runtime config value from system environment first, then .env values.
	 */
	private string function getRuntimeEnvValue(required string key, string defaultValue = "") {
		try {
			local.systemValue = createObject("java", "java.lang.System").getenv(arguments.key);
			if (!isNull(local.systemValue) && len(trim(local.systemValue))) {
				return trim(local.systemValue);
			}
		} catch (any e) {
			// Ignore errors accessing system environment
		}

		if (
			structKeyExists(this, "env")
			&& structKeyExists(this.env, arguments.key)
			&& len(trim(this.env[arguments.key] & ""))
		) {
			return trim(this.env[arguments.key] & "");
		}

		return arguments.defaultValue;
	}

	/**
	 * Load environment variables from a file into the provided struct
	 */
	private void function loadEnvFile(required string filePath, required struct envStruct) {
		local.envFile = fileRead(arguments.filePath);
		local.tempStruct = {};
		
		if (isJSON(local.envFile)) {
			local.tempStruct = deserializeJSON(local.envFile);
		} else {
			// Parse as properties file with enhanced features
			local.lines = listToArray(local.envFile, chr(10));
			
			for (local.line in local.lines) {
				local.trimmedLine = trim(local.line);
				
				// Skip empty lines and comments
				if (!len(local.trimmedLine) || left(local.trimmedLine, 1) == "##") {
					continue;
				}
				
				// Parse key=value pairs
				if (find("=", local.trimmedLine)) {
					local.key = trim(listFirst(local.trimmedLine, "="));
					local.value = trim(listRest(local.trimmedLine, "="));
					
					// Remove surrounding quotes if present
					if ((left(local.value, 1) == '"' && right(local.value, 1) == '"') ||
						(left(local.value, 1) == "'" && right(local.value, 1) == "'")) {
						local.value = mid(local.value, 2, len(local.value) - 2);
					}
					
					// Type casting for boolean and numeric values
					if (local.value == "true" || local.value == "false") {
						local.value = (local.value == "true");
					} else if (isNumeric(local.value) && !find(".", local.value)) {
						// Only convert integers, leave decimals as strings
						local.value = val(local.value);
					}
					
					local.tempStruct[local.key] = local.value;
				}
			}
		}
		
		// Merge into the main env struct
		for (local.key in local.tempStruct) {
			arguments.envStruct[local.key] = local.tempStruct[local.key];
		}
	}
	
	/**
	 * Perform variable interpolation on env values using ${VAR} syntax
	 */
	private void function performVariableInterpolation(required struct envStruct) {
		local.maxIterations = 10; // Prevent infinite loops
		local.iteration = 0;
		local.hasChanges = true;
		
		while (local.hasChanges && local.iteration < local.maxIterations) {
			local.hasChanges = false;
			local.iteration++;
			
			for (local.key in arguments.envStruct) {
				local.value = arguments.envStruct[local.key];
				
				if (isSimpleValue(local.value) && isString(local.value)) {
					local.newValue = local.value;
					
					// Find all ${VAR} patterns
					local.matches = reMatchNoCase("\$\{([^}]+)\}", local.value);
					
					for (local.match in local.matches) {
						// Extract variable name
						local.varName = reReplaceNoCase(local.match, "\$\{([^}]+)\}", "\1");
						
						// Replace with actual value if it exists
						if (structKeyExists(arguments.envStruct, local.varName)) {
							local.replacement = arguments.envStruct[local.varName];
							if (isSimpleValue(local.replacement)) {
								local.newValue = replace(local.newValue, local.match, local.replacement, "all");
								local.hasChanges = true;
							}
						}
					}
					
					arguments.envStruct[local.key] = local.newValue;
				}
			}
		}
	}
	
	/**
	 * Helper to check if a value is a string (not boolean or numeric after parsing)
	 */
	private boolean function isString(required any value) {
		return isSimpleValue(arguments.value) && !isBoolean(arguments.value) && !isNumeric(arguments.value);
	}

	/**
	 * Set baseline HTTP response security headers.
	 */
	private void function setResponseSecurityHeaders() {
		cfheader(name="X-Content-Type-Options", value="nosniff");
		cfheader(name="X-Frame-Options", value="SAMEORIGIN");
		cfheader(name="Referrer-Policy", value="strict-origin-when-cross-origin");
		cfheader(name="Permissions-Policy", value="camera=(), microphone=(), geolocation=()");
		cfheader(name="Content-Security-Policy", value="frame-ancestors 'self'; object-src 'none'; base-uri 'self'");
		if (structKeyExists(cgi, "https") && lCase(cgi.https & "") EQ "on") {
			cfheader(name="Strict-Transport-Security", value="max-age=31536000; includeSubDomains");
		}
	}

}
