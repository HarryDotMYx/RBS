<!---================= Room Booking System / https://github.com/neokoenig =======================--->
<cfscript>
	try{
		_loadSettings();
	} catch(any e){
		writeDump(var=e, format="text"); abort;
	}

	/**
	*  @hint Load Application Settings
	*/
	public void function _loadSettings() {
	 	// Application Specific settings
		if(structKeyExists(application, "rbs")){
			structDelete(application, "rbs");
		}

		application.rbs={
			versionNumber="2.0",
			setting={},
			permission={},
			//roles="admin,editor,user,guest",
			templates={},
			modeltypes="event,location",
			templatetypes="form,output"
		};

		var dsn = "roombooking";
		var installLockPath = expandPath("config/install.lock");
		var sysEnv = _systemEnv();
		var autoInstall = _isTruthy(_env(sysEnv, "AUTO_INSTALL", "false"));
		var dbState = _databaseState(dsn);

		// Primary installation state is schema-based, not lock-file based.
		if (dbState.schemaReady) {
			if (!fileExists(installLockPath)) {
				fileWrite(installLockPath, "installed");
			}
			application.rbs.isInstalled = true;
		} else if (autoInstall) {
			try {
				include "/install/functions.cfm";

				var adminEmail = _env(sysEnv, "ADMIN_EMAIL", "");
				if (!len(adminEmail)) {
					throw(message = "AUTO_INSTALL requires ADMIN_EMAIL to be set");
				}
				if (!dbState.reachable) {
					throw(
						message = "Unable to connect to datasource '#dsn#' during auto-install",
						detail = dbState.detail
					);
				}

				if (!checkAuthKey()) {
					createAuthKey();
				}

				// Only create schema when required.
				if (!runSqlFile(dsn)) {
					throw(message = "Schema initialization failed for datasource '#dsn#'");
				}

				dbState = _databaseState(dsn);
				if (!dbState.schemaReady) {
					throw(message = "Core schema not detected after initialization");
				}

				if (!checkPrimaryAdmin(dsn)) {
					var generatedPassword = _generateSecurePassword(24);
					form.email = adminEmail;
					form.firstname = "System";
					form.lastname = "Administrator";
					form.password = generatedPassword;
					form.password2 = generatedPassword;

					createInitialAdminUser(dsn);
					writeLog(
						type = "information",
						text = "RBS_AUTO_INSTALL_ADMIN email=#form.email# password=#generatedPassword#"
					);
				}

				fileWrite(installLockPath, "installed");
				application.rbs.isInstalled = true;
			} catch(any e) {
				writeLog(
					type = "error",
					text = "RBS_AUTO_INSTALL_FAILED message=#e.message# detail=#e.detail#"
				);
				application.rbs.isInstalled = false;
				return;
			}
		} else {
			if (!dbState.reachable && len(dbState.detail)) {
				writeLog(type = "error", text = "RBS_DB_UNAVAILABLE detail=#dbState.detail#");
			}
			application.rbs.isInstalled = false;
			return;
		}

		for(setting in model("setting").findAll()){
			application.rbs.setting['#setting.id#']=setting.value;
		}
		permissions=model("permission").findAll();
		rolelist=permissions.columnlist;
		rolelist=listDeleteAt(rolelist, 1);
		application.rbs.roles=listDeleteAt(rolelist, listlen(rolelist));
		for(permission in permissions){
			application.rbs.permission["#permission.id#"]={};
			for(role in listToArray(application.rbs.roles)){
				application.rbs.permission["#permission.id#"]["#role#"]=permission["#role#"];
			}
		}

		for(template in model("template").findAll()){
			if (!structKeyExists(application.rbs.templates, template.parentmodel)) {
				application.rbs.templates[template.parentmodel] = {};
			}
			// Ignore empty DB templates; fallback to built-in default templates in views
			if (len(trim(template.template))) {
				application.rbs.templates[template.parentmodel][template.type] = template.template;
			}
		}
	}

	public struct function _systemEnv() {
		try {
			return createObject("java", "java.lang.System").getenv();
		} catch (any e) {
			return {};
		}
	}

	public string function _env(required struct source, required string key, string defaultValue = "") {
		if (
			structKeyExists(arguments.source, arguments.key)
			&& len(trim(arguments.source[arguments.key] & ""))
		) {
			return trim(arguments.source[arguments.key] & "");
		}
		return arguments.defaultValue;
	}

	public boolean function _isTruthy(any value) {
		var normalized = lCase(trim(arguments.value & ""));
		return listFind("1,true,yes,on", normalized) > 0;
	}

	public struct function _databaseState(required string dsn) {
		var result = {
			reachable = false,
			schemaReady = false,
			detail = ""
		};

		try {
			queryExecute("SELECT 1 AS ping", [], { datasource = arguments.dsn });
			result.reachable = true;

			var schemaCheck = queryExecute(
				"SELECT 1 AS has_table
				 FROM information_schema.tables
				 WHERE table_schema = DATABASE()
				   AND table_name = 'settings'
				 LIMIT 1",
				[],
				{ datasource = arguments.dsn }
			);
			result.schemaReady = schemaCheck.recordCount > 0;
		} catch(any e) {
			var errMessage = structKeyExists(e, "message") ? e.message : "";
			var errDetail = structKeyExists(e, "detail") ? e.detail : "";
			result.detail = trim(errMessage & " " & errDetail);
		}

		return result;
	}

	public string function _generateSecurePassword(numeric length = 24) {
		var secureRandom = "";
		var charset = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#$%*+=_-";
		var password = "";
		try {
			secureRandom = createObject("java", "java.security.SecureRandom").getInstanceStrong();
		} catch (any e) {
			secureRandom = createObject("java", "java.security.SecureRandom").init();
		}

		for (var i = 1; i <= arguments.length; i++) {
			var idx = secureRandom.nextInt(len(charset)) + 1;
			password &= mid(charset, idx, 1);
		}

		return password;
	}

	// Wheels 3 compatibility: register shortcode callbacks even when legacy global functions are not auto-included
	if (!structKeyExists(this, "field_callback")) {
		this.field_callback = function(attr, content="", tag="") {
			var result = "";
			savecontent variable="result" {
				include "/views/shortcodes/field.cfm";
			}
			return result;
		};
	}
	if (!structKeyExists(this, "output_callback")) {
		this.output_callback = function(attr, content="", tag="") {
			var result = "";
			savecontent variable="result" {
				include "/views/shortcodes/output.cfm";
			}
			return result;
		};
	}

	// Wheels 3 bootstrap timing: plugin mixins (addShortcode) may not be ready yet.
	// Register directly into application scope as fallback.
	if (!structKeyExists(application, "shortcodes") || !isStruct(application.shortcodes)) {
		application.shortcodes = {};
	}
	if (structKeyExists(this, "field_callback") && isCustomFunction(this.field_callback)) {
		application.shortcodes["field"] = this.field_callback;
	}
	if (structKeyExists(this, "output_callback") && isCustomFunction(this.output_callback)) {
		application.shortcodes["output"] = this.output_callback;
	}


</cfscript>
