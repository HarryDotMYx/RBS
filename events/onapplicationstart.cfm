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

        // Check if the system has been installed
        if (!fileExists(expandPath("config/install.lock"))) {
            // Check for Docker Auto Installation
            var sysEnv = createObject("java", "java.lang.System").getenv();
            var autoInstall = structKeyExists(sysEnv, "AUTO_INSTALL") ? sysEnv["AUTO_INSTALL"] : "false";

            if (autoInstall EQ "true") {
                try {
                    // Force zero-touch auto installation
                    include "/install/functions.cfm";
                    var dsn = "roombooking";

                    // 1. Create auth key if needed
                    if (!checkAuthKey()) {
                        createAuthKey();
                    }

                    // 2. Initialize database schema
                    runSqlFile(dsn);

                    // 3. Create initial admin user
                    if (!checkPrimaryAdmin(dsn)) {
                        // Populate form scope to reuse the existing function
                        form.email = structKeyExists(sysEnv, "ADMIN_EMAIL") ? sysEnv["ADMIN_EMAIL"] : "admin@domain.com";
                        form.firstname = "System";
                        form.lastname = "Administrator";
                        form.password = structKeyExists(sysEnv, "ADMIN_PASSWORD") ? sysEnv["ADMIN_PASSWORD"] : "roombooking123";
                        form.password2 = form.password;

                        createInitialAdminUser(dsn);
                    }

                    // 4. Mark as installed
                    fileWrite(expandPath("config/install.lock"), "installed");
                    application.rbs.isInstalled = true;
                } catch(any e) {
                    // Log error and fall back to manual installation if auto-install fails
                    writeLog(type="error", text="Auto-install failed: #e.message# #e.detail#");
                    application.rbs.isInstalled = false;
                    return;
                }
            } else {
                application.rbs.isInstalled = false;
                return;
            }
        } else {
            application.rbs.isInstalled = true;
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
