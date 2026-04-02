<!---================= Room Booking System / https://github.com/neokoenig =======================--->
<cfoutput>
<cfparam name="params.key" default="">
<cfset cal=application.rbs.setting>

<!--- Tunjuk kotak amaran pendaftaran untuk tetamu (belum log masuk) sahaja --->
<cfif NOT structKeyExists(session, "currentuser")>
	<div class="alert alert-info shadow-sm" role="alert" style="border-radius: 10px; border-left: 5px solid ##31708f; background-color: rgba(217, 237, 247, 0.85); margin-bottom: 25px; padding: 15px;">
		<h4 style="color: ##31708f; margin-top: 0; font-weight: bold;"><i class="fa fa-info-circle"></i> Welcome to the Room Booking System!</h4>
		<p style="color: ##31708f; font-size: 13.5px; margin-bottom: 12px; line-height: 1.5;">To check room availability and make your reservations, please create a personal account.</p>
		<a href="#URLFor(route='register')#" class="btn btn-primary btn-sm" style="font-weight:bold; border-radius: 20px; padding: 5px 20px; font-size: 13px;">Create an Account</a>
	</div>
</cfif>

<!--- Main Index --->
<cfif cal.showlocationfilter>
    #includePartial(partial="locations", locations=locations)#
</cfif>
    #panel(title="Calendar", theclass="panel-primary no-top-rounded")#
	        <div id="calendar"
	            data-eventsurl="#encodeForHTMLAttribute('/index.cfm?controller=eventdata&action=getevents&type=' & urlEncodedFormat(params.action & '') & '&key=' & urlEncodedFormat(params.key & '') & '&format=json')#"
            data-eventurl="/index.cfm?controller=eventdata&action=getevent"
            data-addurl="#urlFor(controller='bookings', action='add')#"
            data-urlrewriting="off"></div>

        <div id="settings"
                data-headerleft="#encodeForHTMLAttribute(cal.calendarHeaderleft & '')#"
                data-headercenter="#encodeForHTMLAttribute(cal.calendarHeadercenter & '')#"
                data-headerright="#encodeForHTMLAttribute(cal.calendarHeaderright & '')#"
                data-weekends="#iif(val(cal.calendarWeekends),de('true'),de('false'))#"
                data-firstDay="#encodeForHTMLAttribute(cal.calendarFirstday & '')#"
                data-slotDuration="#encodeForHTMLAttribute(cal.calendarSlotMinutes & '')#"
                data-minTime="#encodeForHTMLAttribute(cal.calendarMintime & '')#"
                data-maxTime="#encodeForHTMLAttribute(cal.calendarMaxtime & '')#"
                data-timeFormat="#encodeForHTMLAttribute(cal.calendarTimeformat & '')#"
                data-hiddenDays="#encodeForHTMLAttribute(cal.calendarHiddenDays & '')#"
                data-weekNumbers="#iif(val(cal.calendarWeekNumbers),de('true'),de('false'))#"
                data-allDaySlot="#iif(val(cal.calendarAllDaySlot),de('true'),de('false'))#"
                data-allDayText="#encodeForHTMLAttribute(cal.calendarAllDayText & '')#"
                data-defaultView="#encodeForHTMLAttribute(cal.calendarDefaultView & '')#"
                data-axisFormat="#encodeForHTMLAttribute(cal.calendarAxisFormat & '')#"
                data-slotEventOverlap="#iif(val(cal.calendarSlotEventOverlap),de('true'),de('false'))#"
                data-height="auto"
                data-columnFormatmonth="#encodeForHTMLAttribute(cal.calendarColumnFormatMonth & '')#"
                data-columnFormatweek="#encodeForHTMLAttribute(cal.calendarColumnFormatWeek & '')#"
                data-columnFormatday="#encodeForHTMLAttribute(cal.calendarColumnFormatDay & '')#"
	                data-key="#encodeForHTMLAttribute(params.key & '')#"
        ></div>
    #panelend()#
#includePartial("eventmodal")#
</cfoutput>
