<!---================= Room Booking System / https://github.com/neokoenig =======================--->
<cfoutput>
<cfparam name="resources">
<cfif application.rbs.setting.approveBooking>

	<!--- Notification of status --->
	<cfif event.status EQ "denied">
		<div class="alert alert-danger">
			<strong><i class="glyphicon glyphicon-remove"></i> Denied</strong> This booking has been denied.
		</div>
	</cfif>

	<cfif event.status EQ "pending">
		<div class="alert alert-warning">
			<strong><i class="glyphicon glyphicon-warning-sign"></i> Pending Approval</strong> This booking is pending approval from an administrator.
		</div>

		<!--- Approvals--->
		<cfif checkPermission("allowApproveBooking")>
			<div class="btn-group btn-group-justified">
				#linkTo(action="approve", key=event.eventid, text="<span class='glyphicon glyphicon-ok'></span> Approve?", controller="bookings", class="btn btn-success btn-sm", encode=false)#
				#linkTo(action="deny", key=event.eventid, text="<span class='glyphicon glyphicon-remove'></span> Deny", controller="bookings", class="btn btn-danger btn-sm", encode=false)#
				#linkTo(action="deny", key=event.eventid, text="<span class='glyphicon glyphicon-trash'></span> Deny & Delete", controller="bookings", class="btn btn-danger btn-sm", params="delete=1", encode=false)#
			</div>
		</cfif>
	</cfif>



</cfif>

<!--- Editing --->
<cfif checkPermission("allowRoomBooking")>
	<div class="btn-group btn-group-justified">
		#linkTo(action="edit", key=event.eventid, text="<span class='glyphicon glyphicon-pencil'></span> Edit", controller="bookings", class="btn btn-info btn-sm", encode=false)#
		#linkTo(action="clone", key=event.eventid, text="<span class='glyphicon glyphicon-repeat'></span> Clone", controller="bookings", class="btn btn-warning btn-sm", encode=false)#
		#linkTo(action="delete", key=event.eventid, text="<span class='glyphicon glyphicon-trash'></span> Delete", controller="bookings", class="btn btn-danger btn-sm", confirm="Are you sure?", encode=false)#
	</div>
</cfif>
<cfif checkPermission("viewRoomBooking")>
	<!--- Wheels 3 migration: render details directly (shortcode output pipeline is unstable) --->
	<h4>#h(event.title)#</h4>
	<div class="row">
		<div class="col-sm-2"><p><strong>From</strong></p></div>
		<div class="col-sm-10">#dateFormat(event.start, "dd mmm yyyy")# #timeFormat(event.start, "HH:mm")#</div>
	</div>
	<div class="row">
		<div class="col-sm-2"><p><strong>To</strong></p></div>
		<div class="col-sm-10">#dateFormat(event.end, "dd mmm yyyy")# #timeFormat(event.end, "HH:mm")#</div>
	</div>
	<div class="row">
		<div class="col-sm-2"><p><strong>Location</strong></p></div>
		<div class="col-sm-10">#h(event.name)#<cfif len(trim(event.description))>, #h(event.description)#</cfif> <cfif len(trim(event.layoutstyle))>(#h(event.layoutstyle)# style)</cfif></div>
	</div>
	<div class="row">
		<div class="col-sm-2"><p><strong>Status</strong></p></div>
		<div class="col-sm-10">#h(event.status)#</div>
	</div>
	<p><strong>Contact:</strong> #h(event.contactname)# <cfif len(trim(event.contactemail))>(#h(event.contactemail)#)</cfif> <cfif len(trim(event.contactno))>(#h(event.contactno)#)</cfif></p>
	<cfif len(trim(event.eventdescription))>
		<div class='well'>#h(event.eventdescription)#</div>
	</cfif>

<!---================= Resources =================--->
	<cfif application.rbs.setting.allowResources AND len(event.resourceid)>
	<hr />
	<h4>Requested Resources:</h4>
		<cfloop query="event">
			<cfloop query="resources">
				<cfif event.resourceid EQ resources.id[currentrow]>
					<p><strong>#h(name)#</strong><br /><small>#h(description)#</small></p>
				</cfif>
			</cfloop>
		</cfloop>
	</cfif>



<cfelse>
	<p>You're not allowed to view the booking details</p>
</cfif></cfoutput>
