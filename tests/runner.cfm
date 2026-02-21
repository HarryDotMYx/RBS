<cfscript>
// Hide test runner endpoint on this instance
location(url="/", addToken=false, statusCode=302);
abort;
</cfscript>
