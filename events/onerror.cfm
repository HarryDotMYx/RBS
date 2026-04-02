<!--- Production error handler --->
<cfscript>
var ex = structKeyExists(arguments, "exception") ? arguments.exception : {};
var exType = structKeyExists(ex, "type") ? (ex.type & "") : "";
var exMessage = structKeyExists(ex, "message") ? (ex.message & "") : "";
var exDetail = structKeyExists(ex, "detail") ? (ex.detail & "") : "";
var reqMethod = structKeyExists(cgi, "request_method") ? (cgi.request_method & "") : "";
var reqUri = structKeyExists(cgi, "request_uri") ? (cgi.request_uri & "") : "";
var queryString = structKeyExists(cgi, "query_string") ? (cgi.query_string & "") : "";
var routeController = structKeyExists(url, "controller") ? (url.controller & "") : (structKeyExists(form, "controller") ? (form.controller & "") : "");
var routeAction = structKeyExists(url, "action") ? (url.action & "") : (structKeyExists(form, "action") ? (form.action & "") : "");
var hasToken = structKeyExists(form, "authenticityToken") OR structKeyExists(url, "authenticityToken");
var isCsrfError = findNoCase("InvalidAuthenticityToken", exType) GT 0 OR findNoCase("valid authenticity token", exMessage) GT 0;

writeLog(
	file="application",
	type="error",
	text="[ONERROR] type=#exType# message=#exMessage# detail=#exDetail# method=#reqMethod# uri=#reqUri# query=#queryString# controller=#routeController# action=#routeAction# hasToken=#hasToken#"
);
</cfscript>

<cfif isCsrfError>
	<cfheader statuscode="403" statustext="Forbidden">
	<cfoutput>
		<div style="max-width:720px;margin:40px auto;font-family:Arial,sans-serif;line-height:1.5;">
			<h2>Request Expired</h2>
			<p>Your form token is no longer valid. Refresh the page and try again.</p>
		</div>
	</cfoutput>
	<cfabort>
</cfif>

<cfdump var="#arguments.exception#">
