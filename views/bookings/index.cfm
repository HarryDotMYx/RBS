<!---================= Room Booking System / https://github.com/neokoenig =======================--->
<cfoutput>
<cfparam name="params.key" default="">
<cfset cal=application.rbs.setting>
<!--- Main Index --->
<cfif cal.showlocationfilter>
    #includePartial(partial="locations", locations=locations)#
</cfif>
    #panel(title="Calendar", theclass="panel-primary no-top-rounded")#
        <div id="calendar"
            data-eventsurl="/index.cfm?controller=eventdata&action=getevents&type=#params.action#&key=#params.key#&format=json"
            data-eventurl="/index.cfm?controller=eventdata&action=getevent"
            data-addurl="#urlFor(controller='bookings', action='add')#"
            data-urlrewriting="off"></div>

        <div id="settings"
                data-headerleft="#cal.calendarHeaderleft#"
                data-headercenter="#cal.calendarHeadercenter#"
                data-headerright="#cal.calendarHeaderright#"
                data-weekends=#iif(val(cal.calendarWeekends),de('true'),de('false'))#
                data-firstDay=#cal.calendarFirstday#
                data-slotDuration="#cal.calendarSlotMinutes#"
                data-minTime="#cal.calendarMintime#"
                data-maxTime="#cal.calendarMaxtime#"
                data-timeFormat="#cal.calendarTimeformat#"
                data-hiddenDays=#cal.calendarHiddenDays#
                data-weekNumbers=#iif(val(cal.calendarWeekNumbers),de('true'),de('false'))#
                data-allDaySlot=#iif(val(cal.calendarAllDaySlot),de('true'),de('false'))#
                data-allDayText="#cal.calendarAllDayText#"
                data-defaultView="#cal.calendarDefaultView#"
                data-axisFormat="#cal.calendarAxisFormat#"
                data-slotEventOverlap=#iif(val(cal.calendarSlotEventOverlap),de('true'),de('false'))#
                data-height="auto"
                data-columnFormatmonth="#cal.calendarColumnFormatMonth#"
                data-columnFormatweek="#cal.calendarColumnFormatWeek#"
                data-columnFormatday="#cal.calendarColumnFormatDay#"
                data-key="#params.key#"
        ></div>
    #panelend()#
#includePartial("eventmodal")#
</cfoutput>