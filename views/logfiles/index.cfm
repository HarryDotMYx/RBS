<!--- Log file output --->
<cfoutput>
#includePartial("filter")#
</cfoutput>
<cfif logfiles.recordcount>
	<table class="table table-condensed">
		<thead>
			<tr>
				<th>ID</th>
				<th>Message</th>
				<th>Type</th>
				<th>CreatedAt</th>
				<th>IP</th>
				<th>User</th>
				</tr>
			</thead>
			<tbody>
				<cfloop query="logfiles">
					<cfquery dbtype="query" name="thisuser">
						SELECT id, email FROM users WHERE id = <cfqueryparam cfsqltype="cf_sql_integer" value="#userid#">
					</cfquery>
					<cfoutput>
					<tr>

				<td><span class="label-#h(lcase(Type))# label">#ID#</span></td>
				<td>#h(Message)#</td>
				<td>#linkTo(params="type=#lcase(type)#&userid=&rows=1000", text="#h(Type)#", encode=false)#</td>
				<td>#dateFormat(CreatedAt, "dd mmm yyyy")# #timeFormat(createdAt, "HH:MM")#</td>
				<td>
					<cfif !application.rbs.setting.isdemomode>
						<a href="https://www.infosniper.net/index.php?ip_address=#encodeForHTMLAttribute(IPaddress & "")#&map_source=1&overview_map=1&lang=1&map_type=1&zoom_level=7" target="_blank" rel="noopener noreferrer">#h(IPaddress)#</a>
					<cfelse>
						DemoIP
					</cfif></td>
				<td>
					<cfif thisuser.recordcount>
						#linkTo(params="index?type=&userid=#userid#&rows=1000", text="#h(thisuser.email)#", encode=false)#
					<cfelse>
						#linkTo(params="index?type=&userid=#userid#&rows=1000", text="Anon")#
				</cfif>
			</td>

						</tr>
						</cfoutput>
				</cfloop>
				</tbody>
		</table>
	<Cfelse>
		<div class="alert">No log files available</div>
</cfif>
