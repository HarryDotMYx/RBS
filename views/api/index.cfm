<!---================= Room Booking System / https://github.com/neokoenig =======================--->
<cfoutput>
<cfparam name="locations">
<cfparam name="apiTokenValue" default="">
<cfset feedBaseUrl="">
<cfif structKeyExists(application, "env") AND structKeyExists(application.env, "APP_URL") AND len(trim(application.env["APP_URL"] & ""))>
	<cfset feedBaseUrl = reReplace(trim(application.env["APP_URL"] & ""), "/+$", "", "all")>
</cfif>
<cfif !len(apiTokenValue) AND structkeyexists(session, "currentuser") AND structKeyExists(session.currentuser, "apitoken")>
	<cfset apiTokenValue = trim(session.currentuser.apitoken & "")>
</cfif>
#panel(title="Data Feeds for your account")#
	<cfif !len(apiTokenValue)>
	<div class="alert alert-danger">You do not have an API token associated with your account.</div>
		<p>API useage requires a token to be created for your account. Administrators, or those with user creation privledges can create these for you on request.</p>
	<cfelse>
	<p><strong>Careful!</strong> These endpoints are read-only but still authenticated. Do not put API keys in URLs. Send your token in request headers instead.</p>
	<p><strong>Auth headers:</strong></p>
	<pre>X-API-Token: #h(apiTokenValue)#
Authorization: Bearer #h(apiTokenValue)#</pre>

<table class="table table-bordered table-condensed">
	<thead>
		<tr>
			<th>Feed Name</th>
			<th>RSS 2.0 Endpoint</th>
			<th>iCal Endpoint</th>
			<th>Display Endpoint (Next 5)</th>
			<th>Display Endpoint (Today)</th>
		</tr>
	</thead>
	<tbody>
	 <tr>
	 	<td>All Locations</td>
		<td><code>#h(feedBaseUrl & urlFor(controller="api", action="rss2", params="format=xml"))#</code></td>
		<td><code>#h(feedBaseUrl & urlFor(controller="api", action="ical"))#</code></td>
		<td><code>#h(feedBaseUrl & urlFor(controller="api", action="display"))#</code></td>
		<td><code>#h(feedBaseUrl & urlFor(controller="api", action="display", params="today=1"))#</code></td>
	 </tr>
	 <cfloop query="locations">
	 <tr>
	 	<td>#h(name)#</td>
		<td><code>#h(feedBaseUrl & urlFor(controller="api", action="rss2", params="format=xml&location=#id#"))#</code></td>
		<td><code>#h(feedBaseUrl & urlFor(controller="api", action="ical", params="location=#id#"))#</code></td>
		<td><code>#h(feedBaseUrl & urlFor(controller="api", action="display", params="location=#id#"))#</code></td>
		<td><code>#h(feedBaseUrl & urlFor(controller="api", action="display", params="today=1&location=#id#"))#</code></td>
	 </tr>
	</cfloop>
	</tbody>
</table>
#panelEnd()#
	</cfif>
</cfoutput>
