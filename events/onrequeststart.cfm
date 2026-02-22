<!--- Place code here that should be executed on the "onRequestStart" event. --->
<cfscript>
	if (structKeyExists(application, "rbs") && structKeyExists(application.rbs, "isInstalled") && !application.rbs.isInstalled) {
		if (fileExists(expandPath("config/install.lock"))) {
			application.rbs.isInstalled = true;
		} else if (findNoCase("/install", cgi.script_name) EQ 0 AND findNoCase("/install", cgi.path_info) EQ 0) {
			location url="/install/index.cfm" addtoken="false";
		}
	}
</cfscript>

 <!--- Set defaults for non cookie enabled browsers--->
<cfset request.cookie=structnew()>
<cfset request.cookie.username="">

<!--- If cookie exists, get its values and update the request struct--->
<cfif !structkeyexists(cookie, 'RBS_UN')>
	<!--- Set initial cookie--->
	<cfcookie name = "RBS_UN" expires="360" value="" httponly="true">
<cfelse>
	<cfset request.cookie.username=cookie.RBS_UN>
</cfif>

<!--- trim form and url scopes --->
<cfscript>

	if(structCount(url)){
		for(key in url){
			url[key] = Trim(url[key]);
		}
	}
	if(StructCount(form)){
		for(key in form){
			if(isSimpleValue(form[key])){
				form[key] = Trim(form[key]);
			}
		}
	}
</cfscript>

<!--- Other default request level vars--->
<cfset request.showNavBar="true">