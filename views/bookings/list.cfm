<!---================= Room Booking System / https://github.com/neokoenig =======================--->
<cfparam name="events">
<cfoutput>
	#includePartial(partial = "list/filter")#
	#panel(title="Events (#events.recordcount#) records")#
 <cfif events.recordcount>
<cfif application.rbs.setting.showlocationcolours>
<style>
<cfloop query="locations">
	<cfset safeCssClass = reReplaceNoCase(class & "", "[^a-z0-9_-]", "", "all")>
	<cfset safeColour = trim(colour & "")>
	<cfif reFindNoCase("^##?[0-9a-f]{3}([0-9a-f]{3})?$", safeColour)>
		<cfif left(safeColour, 1) NEQ "##"><cfset safeColour = "##" & safeColour></cfif>
	</cfif>
	<cfif len(safeCssClass) AND reFindNoCase("^##[0-9a-f]{3}([0-9a-f]{3})?$", safeColour)>
.#safeCssClass# {border-left: 6px solid #lCase(safeColour)#; }
	</cfif>
</cfloop>
</style>
</cfif>
<table class="table table-condensed   table-striped">
	<thead>
		<tr>
			<th colspan=2>Date</th>
			<th>Location</th>
			<th>Title</th>
			<th>Layout</th>
			<th colspan=2>Description</th>
		</tr>
	</thead>
	<tbody>

	<!---
		For date output, we want to hide the date if the event after this one is on the same day and only show the time
		currentLoopDate is compared to current rows start date and uses alternative formatting if required
	--->
	<cfset currentLoopDate=_formatDate(events.start)>
	<cfset isDateRow=1>

	<cfloop query="events">

		<cfif len(eventid)>
			<cfif currentLoopDate NEQ _formatDate(start)>
				<cfset isDateRow=1>
			</cfif>
			<tr class="<cfif isDateRow>header-row</cfif>">
			<td width=100>
				<cfif isDateRow>
				#_formatDate(start)#
				</cfif>
			</td>
			<td width=100><cfif !allDay>#_formatTime(start)# - #_formatTime(end)#
				<cfelse>All Day
			</cfif></td>
			<td width=150 class="#h(class)#"><cfif len(building)>
				<small>#h(building)#</small><br />
			</cfif> #h(name)#<br /><small>#h(description)#</small></td>
			<td class="#h(status)#">
				#h(title)#
			</td>

			<td>#h(layoutstyle)#</td>
			<td>
			<cfif len(eventdescription)>
				#h(eventdescription)#<br />
			</cfif>
			<small>
			<cfif len(contactemail) AND len(contactname)>
				Contact: <a href="mailto:#h(contactemail)#">#h(contactname)#</a>
			<cfelseif len(contactname)>
				Contact: #h(contactname)#
			</cfif>
			<cfif len(contactno)>
				(#h(contactno)#)
			</cfif>
		</small></td>
		<td>
			<cfif checkPermission("allowRoomBooking")>
				<div class="btn-group">
				#linkTo(action="view", key=eventid, text="<span class='glyphicon glyphicon-eye-open'></span>", controller="bookings", class="btn btn-primary btn-xs", encode=false)#
				#linkTo(action="edit", key=eventid, text="<span class='glyphicon glyphicon-pencil'></span>", controller="bookings", class="btn btn-info btn-xs", encode=false)#

				</div>
			</cfif></td>
		</tr>
		</cfif>
		<cfset currentLoopDate=_formatDate(start)>
		<cfset  isDateRow=0>
	</cfloop>
	</tbody>
</table>
<cfelse>
<div class="alert alert-danger"><strong>Sorry!</strong>, No events returned for that date range.</div>
 </cfif>
 #panelEnd()#
</cfoutput>
