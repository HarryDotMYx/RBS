<cfoutput>
<table class="table table-condensed ">
		<thead>
			<tr>
				<th>Name</th>
				<th>Email</th>
				<th>Role</th>
				<th>API Token</th>
                <th colspan=4>Actions</th>
			</tr>
		</thead>
		<tbody>
			<cfloop query="arguments.users">
				<tr>
					<td>#linkTo(text="#firstname# #lastname#",   controller="users",  action="edit", key=id)#</td>
					<td>#linkTo(text="#email#",   controller="users",  action="edit", key=id)#</td>
					<td>#role#</td>
					<td>#tickorcross(len(apitoken))#</td>
					<td>#_formatDate(createdAt)#</td>
                   <td>

                   	<!-- Split button -->
					<div class="btn-group">
					 #linkTo(text="<span class='glyphicon glyphicon-edit'></span> Edit",   controller="users",  action="edit", key=id, class="btn btn-xs btn-primary", encode=false)#
					  <button type="button" class="btn btn-xs btn-primary dropdown-toggle" data-toggle="dropdown">
					    <span class="caret"></span>
					  </button>
					  <ul class="dropdown-menu" role="menu">
					  	<li>#linkTo(text="<span class='glyphicon glyphicon-edit'></span> Edit",   controller="users",  action="edit", key=id, class="", encode=false)#</li>
					  <cfif role NEQ "admin" AND userisInRole("admin")>
					  	<li>#buttonTo(text="<span class='glyphicon glyphicon-user'></span> Assume", controller="users", action="assumeUser", key=id, inputClass="btn btn-link btn-block text-left", encode=false)#</li>
					  </cfif>
					  <cfif !len(apitoken)>
					  	<li>#buttonTo(text="<span class='glyphicon glyphicon-phone'></span> Generate API Key", controller="users", action="generateAPIKey", key=id, inputClass="btn btn-link btn-block text-left", encode=false)#</li>
					  	<cfelse>
						<li>#buttonTo(text="<span class='glyphicon glyphicon-phone'></span> Re-Generate API Key", controller="users", action="generateAPIKey", key=id, inputClass="btn btn-link btn-block text-left", encode=false)#</li>
					  </cfif>
					  <cfif checkPermission("accessLogfiles")>
					  		<li>#linkTo(text="<span class='glyphicon glyphicon-th'></span> Activity", controller="logfiles",  action="index", params="type=&userid=#id#&rows=1000", encode=false)#</li>
					  </cfif>
					    <li class="divider"></li>
					    <li>#buttonTo(text="<span class='glyphicon glyphicon-trash'></span> Delete Permanently", controller="users", action="delete", key=id, inputClass="btn btn-link btn-block text-left text-danger", inputOnclick="return confirm('Are you sure? This will permanently delete this account and cannot be undone.');", encode=false)#</li>
					  </ul>
					</div>


					</td>
				</tr>
			</cfloop>
		</tbody>
	</table>
</Cfoutput>
