<!---================= Room Booking System / https://github.com/neokoenig =======================--->
<!--- Alternative Day view a la MRBS --->
<cfparam name="locations">
<cfparam name="events">
<cfparam name="m" type="array">
<cfparam name="day" type="struct">
<cfparam name="isToday" default="false">
<cfif dateFormat(day.thedate, "yyyymmdd") EQ dateFormat(now(), "yyyymmdd")>
	<cfset isToday=true>
</cfif>
<cfif application.rbs.setting.showlocationcolours>
	<style>
	<cfloop query="locations"><cfoutput>
	<cfset safeCssClass = reReplaceNoCase(class & "", "[^a-z0-9_-]", "", "all")>
	<cfset safeColour = trim(colour & "")>
	<cfif reFindNoCase("^##?[0-9a-f]{3}([0-9a-f]{3})?$", safeColour)>
		<cfif left(safeColour, 1) NEQ "##"><cfset safeColour = "##" & safeColour></cfif>
	</cfif>
	<cfif len(safeCssClass) AND reFindNoCase("^##[0-9a-f]{3}([0-9a-f]{3})?$", safeColour)>
	.table-day th.#safeCssClass# {background: #lCase(safeColour)#; border-color: #lCase(safeColour)#; color:white; font-weight:normal; font-size:80%;}
	.table-day tr td.#safeCssClass# a {color: #lCase(safeColour)#;}
	.table-day tr td.#safeCssClass#.booked {border-right:1px solid #lCase(safeColour)#; border-left:1px solid #lCase(safeColour)#;}
	.table-day tr td.#safeCssClass#.first {border-top:4px solid #lCase(safeColour)#; font-size: 80%; border-bottom:2px solid #lCase(safeColour)#;}
	.table-day tr td.#safeCssClass#.allday {font-size: 80%; border-bottom:2px solid #lCase(safeColour)#;}
	</cfif>
	</cfoutput>
	</cfloop>
	</style>
</cfif>
<cfoutput>
#includePartial("day/header")#
<table class="table table-day">
	<thead>
		<tr>
			<th>Time</th>
			<cfloop query="locations">
				<cfset safeLocationClass = reReplaceNoCase(class & "", "[^a-z0-9_-]", "", "all")>
				<cfquery dbtype="query" name="locationEventsC">
				SELECT * FROM events WHERE locationid = <cfqueryparam cfsqltype="cf_sql_numeric" value="#id#">;
				</cfquery>
				<cfoutput>
				<th class="#safeLocationClass# #iif(!locationEventsC.recordcount, '"lower-op"', '')#">
					#h(name)# (#locationEventsC.recordcount#)
				</th>
				</cfoutput>
			</cfloop>
		</tr>
		<cfif application.rbs.setting.calendarAllDaySlot>
				<tr>
			<th>All Day</th>
			<cfloop query="locations">
				<cfset safeLocationClass = reReplaceNoCase(class & "", "[^a-z0-9_-]", "", "all")>
				<cfquery dbtype="query" name="locationEventsAllDay">
				SELECT * FROM allDay WHERE locationid = <cfqueryparam cfsqltype="cf_sql_numeric" value="#id#">;
				</cfquery>
				<cfoutput>
				<cfif locationEventsAllDay.recordcount>
					<td class="booked #safeLocationClass# allday">
						<cfloop query="locationEventsAllDay">
							#linkTo(class="remote-modal", controller='eventdata', action='getEvent', key=locationEventsAllDay.id, text=h(title))#<br />
						</cfloop>
					</td>
					<cfelse>
						<td>&nbsp;</td>
				</cfif>
				</cfoutput>
			</cfloop>
		</tr>
		</cfif>
	</thead>
	<tbody>
		<cfset counter=1>
		<cfloop from="#day.starttime#" to="#day.endtime#" index="i" step="#CreateTimeSpan(0,0,timeFormat(application.rbs.setting.calendarSlotMinutes, 'M'),0)#">
  			<cfoutput>
 				<cfif timeFormat(i, "MM") EQ "00">
 					<tr class="hour #iif(isToday AND (timeFormat(i, 'HH') EQ timeformat(now(), 'HH')), '"current"', '""')#">
	 				<th><strong>#timeFormat(i, "HH:MM")#</strong></th>
				<cfelse>
					<tr>
 					<th  class=""><small>#timeFormat(i, "HH:MM")#</small></th>
 				</cfif>
 				<cfloop from="1" to="#arraylen(m)#" index="z">
 					<cfoutput>
 					<cfif m[z][counter]["rowspan"] NEQ 0>
 						<td rowspan=#m[z][counter]["rowspan"]# class="#m[z][counter]['class']#">#m[z][counter]["content"]#</td>
 					</cfif>
 					</cfoutput>
 				</cfloop>
 			</tr>
	 		</cfoutput>
	 		<cfset counter++>
 		</cfloop>
	</tbody>
</table>

#includePartial("eventmodal")#
</cfoutput>
