<!---================= Room Booking System / https://github.com/neokoenig =======================--->
<!--- Locations --->
<cfparam name="locations">
<Cfoutput>
#panel(title="All Locations")#
#linkTo(Text="<i class='glyphicon glyphicon-plus'></i> Create New Location", class="btn btn-primary", action="add")#
<cfif locations.recordcount>

<table class="table">
	<thead>
		<tr>
			<th>ID</th>
			<th>Building</th>
			<th>Name</th>
			<th>Description</th>
			<th>Actions</th>
		</tr>
	</thead>
	<tbody>
	<cfloop query="locations">
		<cfoutput>
		<tr>
			<td>#id#</td>
			<td>#h(building)#</td>
			<td>#h(name)#</td>
			<td>#h(description)#</td>
			<td>
					<div class="btn-group">
						#linkTo(text="<i class='glyphicon glyphicon-eye-open'></i> View", class="btn btn-xs btn-primary", action="view", key=id, encode=false)#
						#linkTo(text="<i class='glyphicon glyphicon-edit'></i> Edit", class="btn btn-xs btn-info", action="edit", key=id, encode=false)#
						#buttonTo(text="<i class='glyphicon glyphicon-trash'></i> Delete", style="display:inline-block", action="delete", key=id, inputClass="btn btn-xs btn-danger", inputOnclick="return confirm('Are you Sure?');", encode=false)#
					</div>
			</td>
		</tr>
		</cfoutput>
	</cfloop>

	</tbody>
</table>
	<cfelse>
		<p>No Locations available yet</p>
</cfif>
#panelEnd()#

</Cfoutput>
