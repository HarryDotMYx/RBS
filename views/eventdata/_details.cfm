<!---================= Room Booking System / https://github.com/neokoenig =======================--->
<style>
.event-popup-card{border:1px solid #e6eaef;border-radius:8px;background:#fff;overflow:hidden}
.event-popup-header{padding:16px 18px;background:linear-gradient(135deg,#f8fbff 0%,#eef5ff 100%);border-bottom:1px solid #e6eaef}
.event-popup-title{margin:0 0 4px;font-size:22px;line-height:1.25}
.event-popup-sub{margin:0;color:#6b7785}
.event-popup-body{padding:16px 18px 8px}
.event-popup-meta{margin-bottom:12px}
.event-popup-meta .meta-label{font-size:12px;letter-spacing:.04em;text-transform:uppercase;color:#7a8694;font-weight:700;margin-bottom:4px}
.event-popup-meta .meta-value{font-size:15px;color:#1f2d3d}
.event-popup-actions{padding:0 18px 18px}
.event-popup-actions .btn{margin-right:6px;margin-bottom:6px}
.event-popup-note{margin-top:10px}
.btn-inline{display:inline-block;margin:0 6px 6px 0}
.btn-inline .btn{margin:0}
</style>

<cfoutput>
<cfparam name="resources">
<cfset statusText=lCase(trim(event.status))>
<cfset statusClass="label-default">
<cfif statusText EQ "approved"><cfset statusClass="label-success"></cfif>
<cfif statusText EQ "pending"><cfset statusClass="label-warning"></cfif>
<cfif statusText EQ "denied"><cfset statusClass="label-danger"></cfif>

<cfif checkPermission("viewRoomBooking")>
	<div class="event-popup-card">
		<div class="event-popup-header">
			<h3 class="event-popup-title">#h(event.title)#</h3>
			<p class="event-popup-sub">
				<span class="label #statusClass#">#uCase(h(event.status))#</span>
				<cfif len(trim(event.layoutstyle))>
					&nbsp;<span class="label label-info">#h(event.layoutstyle)#</span>
				</cfif>
			</p>
		</div>

			<div class="event-popup-body">
				<cfif application.rbs.setting.approveBooking>
					<cfif event.status EQ "denied">
						<div class="alert alert-danger event-popup-note">
							<strong><i class="glyphicon glyphicon-remove"></i> Denied</strong> This booking has been denied.
					</div>
				</cfif>
					<cfif event.status EQ "pending">
						<div class="alert alert-warning event-popup-note">
							<strong><i class="glyphicon glyphicon-warning-sign"></i> Pending Approval</strong> This booking is pending approval from an administrator.
						</div>
					</cfif>
				</cfif>
				<cfif val(event.locationmissing)>
					<div class="alert alert-warning event-popup-note">
						<strong><i class="glyphicon glyphicon-warning-sign"></i> Room Removed</strong> This booking still exists, but its original room record has been deleted.
					</div>
				</cfif>

				<div class="row event-popup-meta">
					<div class="col-sm-6">
					<div class="meta-label"><i class="glyphicon glyphicon-time"></i> From</div>
					<div class="meta-value">#dateFormat(event.start, "dd mmm yyyy")# #timeFormat(event.start, "HH:mm")#</div>
				</div>
				<div class="col-sm-6">
					<div class="meta-label"><i class="glyphicon glyphicon-time"></i> To</div>
					<div class="meta-value">#dateFormat(event.end, "dd mmm yyyy")# #timeFormat(event.end, "HH:mm")#</div>
				</div>
			</div>

			<div class="row event-popup-meta">
				<div class="col-sm-6">
					<div class="meta-label"><i class="glyphicon glyphicon-map-marker"></i> Location</div>
					<div class="meta-value">#h(event.name)#<cfif len(trim(event.description))>, #h(event.description)#</cfif></div>
				</div>
				<div class="col-sm-6">
					<div class="meta-label"><i class="glyphicon glyphicon-user"></i> Contact</div>
					<div class="meta-value">
						#h(event.contactname)#
						<cfif len(trim(event.contactemail))><br><small>#h(event.contactemail)#</small></cfif>
						<cfif len(trim(event.contactno))><br><small>#h(event.contactno)#</small></cfif>
					</div>
				</div>
			</div>

			<cfif len(trim(event.eventdescription))>
				<div class="well well-sm">#h(event.eventdescription)#</div>
			</cfif>

			<cfif application.rbs.setting.allowResources AND len(event.resourceid)>
				<hr />
				<h4>Requested Resources</h4>
				<cfloop query="event">
					<cfloop query="resources">
						<cfif event.resourceid EQ resources.id[currentrow]>
							<p><strong>#h(name)#</strong><br><small>#h(description)#</small></p>
						</cfif>
					</cfloop>
				</cfloop>
			</cfif>
		</div>

			<div class="event-popup-actions">
				<cfif checkPermission("allowRoomBooking")>
					#linkTo(action="edit", key=event.eventid, text="<span class='glyphicon glyphicon-pencil'></span> Edit", controller="bookings", class="btn btn-info btn-sm", encode=false)#
					#linkTo(action="clone", key=event.eventid, text="<span class='glyphicon glyphicon-repeat'></span> Clone", controller="bookings", class="btn btn-warning btn-sm", encode=false)#
					#buttonTo(action="delete", key=event.eventid, text="<span class='glyphicon glyphicon-trash'></span> Delete", controller="bookings", class="btn-inline", inputClass="btn btn-danger btn-sm", inputOnclick="return confirm('Are you sure?');", encode=false)#
				</cfif>
				<cfif application.rbs.setting.approveBooking AND event.status EQ "pending" AND checkPermission("allowApproveBooking")>
					#buttonTo(action="approve", key=event.eventid, text="<span class='glyphicon glyphicon-ok'></span> Approve", controller="bookings", class="btn-inline", inputClass="btn btn-success btn-sm", encode=false)#
					#buttonTo(action="deny", key=event.eventid, text="<span class='glyphicon glyphicon-remove'></span> Deny", controller="bookings", class="btn-inline", inputClass="btn btn-danger btn-sm", encode=false)#
					#buttonTo(action="deny", key=event.eventid, text="<span class='glyphicon glyphicon-trash'></span> Deny & Delete", controller="bookings", class="btn-inline", inputClass="btn btn-danger btn-sm", inputOnclick="return confirm('Are you sure?');", params="delete=1", encode=false)#
				</cfif>
			</div>
	</div>
<cfelse>
	<div class="alert alert-danger">You're not allowed to view the booking details.</div>
</cfif>
</cfoutput>
