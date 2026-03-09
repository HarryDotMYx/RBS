//================= Room Booking System / https://github.com/neokoenig =======================--->
component extends="Controller" hint="Main Events/Bookings Controller"
{
	/**
	 * @hint Constructor.
	 */
	private function config() {
		
		// super.config() disabled during migration;
// legacy super.init removed for CFWheels2+

		// Additional Permissions
		filters(through="checkPermissionAndRedirect", permission="accesscalendar");
		filters(through="checkPermissionAndRedirect", permission="allowRoomBooking", except="index,list,day,building,location,check");
		filters(through="checkPermissionAndRedirect", permission="viewRoomBooking", only="list,view");
		filters(through="checkPermissionAndRedirect", permission="allowApproveBooking", only="approve,deny");

		// Verification
		verifies(only="approve,deny,view,clone,edit,update,delete", params="key", paramsTypes="integer", route="home", error="Sorry, that event can't be found");

		// Data
		filters(through="_getLocations", only="index,building,location,add,edit,clone,create,update,list,day");
		filters(through="_getResources", only="index,building,location,add,edit,clone,create,update,list,view");
		filters(through="_setModelType");

		// Ajax
		usesLayout(template=false, only="check");
	}

	public void function index() {
		locations=model("location").findAll(order="building,name");
		resources=model("resource").findAll(order="type,name");
	}

/******************** Views ***********************/
	/**
	*  @hint Static display of a single event, mainly used in RSS permalinks etc
	*/
	public void function view() {
		event=model("location").findAll(where="events.id = #params.key#", include="events(eventresources)");
		customfields=getCustomFields(objectname=request.modeltype, key=event.id);
	}

	/**
	*  @hint By Building
	*/
	public void function building() {
		renderView(action="index");
	}
	/**
	*  @hint By Location
	*/
	public void function location() {
		renderView(action="index");
	}
	/**
	*  @hint Shows Agenda style view table for a given month
	*/
	public void function list() {
		param name="params.datefrom" default="#dateFormat(now(), 'DD/MM/YYYY')#";
		param name="params.dateto" 	 default="#dateFormat(dateAdd('m', 1, now()), 'DD/MM/YYYY')#";
		param name="params.location" default="";
		param name="params.q"		 default="";
		locations=model("location").findAll(order="building,name");
		resources=model("resource").findAll(order="type,name");
		events=model("location").findAll(where="#_agendaListWC()#", include="events", order="start");
	}

	/**
	*  @hint Alternative Day View: deprecated in 1.2
	*/
	public void function day() {
		param name="params.y" default=year(now());
		param name="params.m" default=month(now());
		param name="params.d" default=day(now());

		var slotMin=application.rbs.setting.calendarSlotMinutes;
		var calStart=application.rbs.setting.calendarMinTime;
		var calEnd=application.rbs.setting.calendarMaxTime;

		events=model("event").findAll(where="#_dayListWC()#", order="start", include="location");
		allDay=model("event").findAll(where="#_dayListWC(allday=1)#", order="start", include="location");

		day={
			thedate=createDate(params.y, params.m, params.d),
			starttime=createDateTime(params.y, params.m, params.d, timeFormat(calStart, 'H'),timeFormat(calStart, 'M'),0),
			endtime=createDateTime(params.y, params.m, params.d, timeFormat(calEnd, 'H'),timeFormat(calEnd, 'M'),0)
		};
		day.yesterday=dateAdd("d", -1, day.thedate);
		day.tomorrow=dateAdd("d", 	1, day.thedate);
		// Placeholder arrays
		m=[];
		e=[];
		tempid=0;

		for(location in locations){
			day.counter=day.starttime;
			do {
				t={
					timeslot=createDateTime(year(day.thedate), month(day.thedate), day(day.thedate), TimeFormat(day.counter, "H"), TimeFormat(day.counter, "m"), 0)
				};
			    eventsQ = new Query();
			    eventsQ.setDBType('query');
			    eventsQ.setAttributes(rs=events); // needed for QoQ
			    eventsQ.addParam(name='locationid', value=location.id, cfsqltype='cf_sql_numeric');
			    eventsQ.addParam(name='start', value=t.timeslot, cfsqltype='cf_sql_timestamp');
			    eventsQ.addParam(name='end', value=t.timeslot, cfsqltype='cf_sql_timestamp');
			    eventsQ.setSQL('SELECT * FROM rs WHERE locationid =:locationid AND start <= :start AND [end] > :end AND allday = 0');
			    locationEvents = eventsQ.execute().getResult();
 				if(locationEvents.recordcount){
					 if(tempid NEQ locationEvents.id){
					 	// Check for multiday event
					 	if(day(locationEvents.start) != day(locationEvents.end)){
					 		t.isMultiday=true;
					 	} else {
					 		t.isMultiday=false;
					 	}
					 	// Check for multiday event with specific end time
					 	if(t.isMultiday	AND	(day(day.thedate) EQ day(locationEvents.end))){
					 		t.duration=DateDiff("n", t.timeslot, locationEvents.end);
					 	} else if(t.isMultiday AND (day(day.thedate) EQ day(locationEvents.start))) {
							t.duration=DateDiff("n",day.thedate, locationEvents.start);
					 	} else {
					 		t.duration=DateDiff("n", locationEvents.start, locationEvents.end);
					 	}
					 	// Set rowspan dependent on duration
						t.rowspan=ceiling(t.duration / timeFormat(SlotMin, 'M'));
						t.content="<strong>"
						& linkTo( class="remote-modal", route='getEvent',  key=locationEvents.id, text=h(locationEvents.title))
						& "</strong><br />"
						& h(locationEvents.name) & "<br />";
						if(t.isMultiday){
							t.content=t.content & "Multiday event";
						} else {
							t.content=t.content & "#timeFormat(locationEvents.start, "HH:MM")# - #timeFormat(locationEvents.end, "HH:MM")# "
									& _durationString(t.duration);
						}
						t.class="booked first #location.class# #locationEvents.status#";
						if(locationEvents.recordcount GT 1) {
							t.content=t.content & "<br /><span class='label label-danger'><i class='glyphicon glyphicon-warning-sign'></i> Overlapping Event!</span>";
						}
					 } else {
						// Subsequent cells
						t.content="";
						t.class="booked #location.class#";
						t.rowspan=0;
					}
					tempid=locationEvents.id;
				}
				else {
					// Empty Cell
					t.class="free";
					t.content="";
					t.rowspan=1;
				}
				arrayAppend(e, t);
				day.counter = dateAdd('n',15,day.counter);
				// end nested loop
			} while(day.counter LTE day.endtime);

		arrayAppend(m, e);
		e=[];
		// end location loop
		}
	}

/******************** Admin ***********************/
	/**
	*  @hint Add a new booking
	*/
	 public void function add() {
		locations=model("location").findAll(order="building,name");
		resources=model("resource").findAll(order="type,name");
		 nEventResources=model("eventresource").new();
	    	 event=model("event").new(eventresources=nEventResources);
	    	 customfields=getCustomFields(objectname="event", key=event.key());
	    	 // Prefill contact details from logged-in user
	    	 if (isLoggedIn()) {
	    	 	var cu = currentUser();
	    	 	var userTel = "";
	    	 	if (structKeyExists(cu, "firstname") || structKeyExists(cu, "lastname")) {
	    	 		event.contactname = trim((structKeyExists(cu, "firstname") ? cu.firstname : "") & " " & (structKeyExists(cu, "lastname") ? cu.lastname : ""));
	    	 	}
	    	 	if (structKeyExists(cu, "email")) {
	    	 		event.contactemail = cu.email;
	    	 	}
	    	 	if (structKeyExists(cu, "tel") && len(trim(cu.tel & ""))) {
	    	 		userTel = trim(cu.tel & "");
	    	 	} else if (structKeyExists(cu, "id") && isNumeric(cu.id)) {
	    	 		var fullUser = model("user").findOne(where="id = #val(cu.id)#");
	    	 		if (isObject(fullUser) && structKeyExists(fullUser, "tel") && len(trim(fullUser.tel & ""))) {
	    	 			userTel = trim(fullUser.tel & "");
	    	 		}
	    	 	}
	    	 	if (len(userTel)) {
	    	 		event.contactno = userTel;
	    	 	}
	    	 	event.emailcontact = 1;
	    	 }
	    	 // Listen out for event date & location passed in URL via JS
	    	 if(structKeyExists(params, "d")){
	    	 	var malaysiaNow = createObject("java", "java.time.ZonedDateTime").now(
	    	 		createObject("java", "java.time.ZoneId").of("Asia/Kuala_Lumpur")
	    	 	);
	    	 	qDate=createDateTime(
	    	 		listFirst(params.d, '-'),
	    	 		ListGetAt(params.d, 2, '-'),
	    	 		ListGetAt(params.d, 3, '-'),
	    	 		malaysiaNow.getHour(),
	    	 		0,
	    	 		0
	    	 	);
	    	 	// Use picker-native format to avoid ambiguous parsing on browser side.
	    	 	event.start=dateFormat(qDate, "MM/DD/YYYY") & ' ' & timeFormat(qDate, "hh:mm tt");
	    	 }
    	 if(structKeyExists(params, "key") AND isNumeric(params.key)){
    	 	event.locationid=params.key;
    	}
	}

	/**
	*  @hint Approve a listing
	*/
	public void function approve() {
		event=model("event").findOne(where="id = #params.key#");
		if(isObject(event)){
			event.status="approved";
			event.save();
			notifyContact(event);
		}
		redirectTo(success="#event.title# was approved", back=true);
	}

	/**
	*  @hint Deny a listing (can also delete)
	*/
	public void function deny() {
		event=model("event").findOne(where="id = #params.key#");
		if(isObject(event)){
			event.status="denied";
			event.save();
			// Notify Contact if Appropriate
			notifyContact(event);
			if(structKeyExists(params, "delete") AND params.delete){
				event.delete();
				redirectTo(success="#event.title# was denied & deleted", back=true);
			} else {
				redirectTo(success="#event.title# was denied", back=true);
			}
		}
	}

	/**
	*  @hint Shortcut to duplicating a booking
	*/
	public void function clone() {
		locations=model("location").findAll(order="building,name");
		resources=model("resource").findAll(order="type,name");
	 	event=model("event").findOne(where="id = #params.key#", include="eventresources");
		_normalizeEventDateFieldsForPicker(event);
    	customfields=getCustomFields(objectname="event", key=event.key());
        renderView(action="add");
	}

	/**
	*  @hint Event CRUD
	*/
	public void function edit() {
		if(!_checkEventOwnerOrAdmin()){
			return;
		}
		locations=model("location").findAll(order="building,name");
		resources=model("resource").findAll(order="type,name");
		event=model("event").findOne(where="id = #val(params.key)#", include="eventresources");
		_normalizeEventDateFieldsForPicker(event);
		customfields=getCustomFields(objectname=request.modeltype, key=params.key);
	}

	/**
	*  @hint Event CRUD
	*/
	public void function create() {
		if(structkeyexists(params, "event")){
			var creatorUserId = 0;
			var hasEventUserIdColumn = _eventsTableHasUserId();
			if(
				structKeyExists(params.event, "start")
				AND len(trim(params.event.start))
				AND isDate(params.event.start)
			){
				var submittedStart = parseDateTime(params.event.start);
				var submittedStartDate = createDate(year(submittedStart), month(submittedStart), day(submittedStart));
				var todayDate = createDate(year(now()), month(now()), day(now()));
					if(dateCompare(submittedStartDate, todayDate) EQ -1){
						redirectTo(action="add", error="Start date cannot be in the past.");
						return;
					}
				}
				if (isLoggedIn() && hasEventUserIdColumn) {
					var cu = currentUser();
					if (structKeyExists(cu, "id") && isNumeric(cu.id)) {
						creatorUserId = val(cu.id);
						params.event.userid = creatorUserId;
					}
				}
				event = model("event").new(params.event);
				if ( event.save() ) {
					// Persist creator ownership explicitly (works even if ORM metadata was cached before schema change).
					if (creatorUserId GT 0 && hasEventUserIdColumn) {
						queryExecute(
							"UPDATE events SET userid = ? WHERE id = ?",
							[creatorUserId, event.key()],
							{datasource=application.wheels.datasourcename}
						);
					}
					if(structKeyExists(params, "customfields") AND isStruct(params.customfields)){
						updateCustomFields(objectname=request.modeltype, key=event.key(), customfields=params.customfields);
					}
				// Update approval status if allowed to bypass
				if(application.rbs.setting.approveBooking AND checkPermission("bypassApproveBooking")){
					event.status="approved";
					event.save();
				}

				// Check for bulk create events
				if(structKeyExists(params, "repeat")
					AND params.repeat NEQ "none"
					AND structKeyExists(params, "repeatno")
					AND isnumeric(params.repeatno)
					AND params.repeatno GTE 1)
				{
					for (i = 1; i lte params.repeatno; i = i + 1){
						//create placeholderevent
						nevent = model("event").new(params.event);
						//increment date as appropriate
						if(params.repeat EQ "week"){
							nevent.start = dateAdd("d", (i * 7), nevent.start);
							if(isDate(nevent.end)){
								nevent.end = dateAdd("d", (i * 7), nevent.end);
							}

						}
						if(params.repeat EQ "month"){
							nevent.start = dateAdd("m", i, nevent.start);
							if(isDate(nevent.end)){
						  		nevent.end = dateAdd("m", i, nevent.end);
						  	}
						}
							// Save the child event: NB, repeated events can't/don't save customfield metadata
							nevent.save();
							if (creatorUserId GT 0 && hasEventUserIdColumn) {
								queryExecute(
									"UPDATE events SET userid = ? WHERE id = ?",
									[creatorUserId, nevent.key()],
									{datasource=application.wheels.datasourcename}
								);
							}
						}
					}
				// Send Confirmation email if appropriate
				if(structKeyExists(params.event, "emailContact") AND params.event.emailContact){
					notifyContact(event);
				}
				redirectTo(action="index", success="Event successfully created");
			}
	        else {
				renderView(action="add", error="There were problems creating that event");
			}
		}
	}

	/**
	*  @hint Email to send on approval/denial etc.
	*/
	public void function notifyContact(required struct event) {
		if( isValid("email", arguments.event.contactemail)
			AND !application.rbs.setting.isDemoMode){
			// Get the location for reference
			eventlocation=model("location").findOne(where="id = #arguments.event.locationid#");
			try{
				var mailArgs = {
				    to="#arguments.event.contactname# <#arguments.event.contactemail#>",
				    bcc=iif(application.rbs.setting.bccAllEmail, '"#application.rbs.setting.bccAllEmailTo#"', ''),
				    from="#application.rbs.setting.sitetitle# <#application.rbs.setting.siteEmailAddress#>",
				    template="/email/bookingNotify",
				    subject="Room Booking Notification (#event.status#)",
				    event=arguments.event
				};
				structAppend(mailArgs, getMailDeliverySettings(), true);
				sendEmail(argumentCollection=mailArgs);
			} catch(any mailError){
				writeLog(file="application", type="error", text="[BOOKING_NOTIFY] Failed to send email for event ##arguments.event.key()##: ##mailError.message##");
			}
		}
	}

	/**
	*  @hint Event CRUD
	*/
	public void function update() {
		if(!_checkEventOwnerOrAdmin()){
			return;
		}
		if(structkeyexists(params, "event")){
			event = model("event").findOne(where="id = #val(params.key)#", include="eventresources");
			if(structKeyExists(params.event, "userid")){
				structDelete(params.event, "userid");
			}
			event.update(params.event);
			if ( event.save() )  {
				if(structKeyExists(params, "customfields") AND isStruct(params.customfields)){
					customfields=updateCustomFields(objectname=request.modeltype, key=event.key(), customfields=params.customfields);
				}
				redirectTo(action="index", success="event successfully updated");
			}
	        else {
				renderView(action="edit", error="There were problems updating that event");
			}
		}
	}

	/**
	*  @hint Event CRUD
	*/
	public void function delete() {
		if(!_checkEventOwnerOrAdmin()){
			return;
		}
	    	event = model("event").findOne(where="id = #val(params.key)#", include="eventresources");
		if ( event.delete() )  {
			redirectTo(action="index", success="event successfully deleted");
		}
        else {
			redirectTo(action="index", error="There were problems deleting that event");
		}
	}
	/******************** Private *********************/
	/**
	*  @hint Restrict edit/update/delete to event owner or admin.
	*/
	private boolean function _checkEventOwnerOrAdmin() {
		if (!isLoggedIn() || !structKeyExists(params, "key") || !isNumeric(params.key)) {
			redirectTo(route="denied", error="Only the event owner or an administrator can edit this booking.");
			return false;
		}

		var ownershipRow = queryExecute(
			"SELECT userid, contactemail FROM events WHERE id = ? LIMIT 1",
			[val(params.key)],
			{datasource=application.wheels.datasourcename}
		);

		if (!ownershipRow.recordCount) {
			redirectTo(route="home", error="Sorry, that event can't be found");
			return false;
		}

		if (
			!_currentUserCanManageEvent(
				ownerUserId=ownershipRow.userid[1],
				ownerContactEmail=ownershipRow.contactemail[1]
			)
		) {
			redirectTo(route="denied", error="Only the event owner or an administrator can edit this booking.");
			return false;
		}
		return true;
	}

	/**
	*  @hint Returns true when current user is admin or owns the event.
	*/
	private boolean function _currentUserCanManageEvent(any ownerUserId="", string ownerContactEmail="") {
		var cu = {};
		var ownerId = 0;

		if (userIsInRole("admin")) {
			return true;
		}

		if (!isLoggedIn()) {
			return false;
		}

		cu = currentUser();
		if (!structKeyExists(cu, "id") || !isNumeric(cu.id)) {
			return false;
		}

		if (isNumeric(arguments.ownerUserId)) {
			ownerId = val(arguments.ownerUserId);
			if (ownerId GT 0) {
				return (ownerId EQ val(cu.id));
			}
		}

		// Legacy fallback for records created before userid ownership was tracked.
		if (
			len(trim(arguments.ownerContactEmail & ""))
			&& structKeyExists(cu, "email")
		) {
			return lCase(trim(arguments.ownerContactEmail & "")) EQ lCase(trim(cu.email & ""));
		}

		return false;
	}

	/**
	*  @hint Detect whether events.userid exists.
	*/
	private boolean function _eventsTableHasUserId() {
		try {
			queryExecute(
				"SELECT userid FROM events LIMIT 1",
				[],
				{datasource=application.wheels.datasourcename}
			);
			return true;
		} catch(any e) {
			return false;
		}
	}

	/**
	*  @hint Ensure event date values match UI picker format to avoid browser-side misparsing (e.g. year 0026).
	*/
	private void function _normalizeEventDateFieldsForPicker(required any eventRecord) {
		if (!isObject(arguments.eventRecord)) {
			return;
		}
		if (structKeyExists(arguments.eventRecord, "start")) {
			arguments.eventRecord.start = _toPickerDateTime(arguments.eventRecord.start);
		}
		if (structKeyExists(arguments.eventRecord, "end")) {
			arguments.eventRecord.end = _toPickerDateTime(arguments.eventRecord.end);
		}
	}

	/**
	*  @hint Convert a datetime-ish value into picker format MM/DD/YYYY hh:mm AM/PM.
	*/
	private string function _toPickerDateTime(required any value) {
		var parsedValue = "";
		if (isDate(arguments.value)) {
			parsedValue = parseDateTime(arguments.value);
			return dateFormat(parsedValue, "MM/DD/YYYY") & " " & timeFormat(parsedValue, "hh:mm tt");
		}
		try {
			parsedValue = parseDateTime(arguments.value);
			return dateFormat(parsedValue, "MM/DD/YYYY") & " " & timeFormat(parsedValue, "hh:mm tt");
		} catch(any e) {
			return arguments.value & "";
		}
	}

	/**
	*  @hint Conditional Where Clause for Day Listing: deprecated in 1.2
	*/
	private string function _dayListWC(numeric allday="0") {
		var sd="";
	 		var td="";
			var wc=[];
			// Date Filter

				if(structKeyExists(params, "m")
					AND structKeyExists(params, "y")
					AND structKeyExists(params, "d")
					AND len(params.m) GT 0
					AND len(params.y) EQ 4
					AND len(params.d) GT 0
					AND isNumeric(params.m)
					AND isNumeric(params.y)
					AND isNumeric(params.d)
				){
					if(arguments.allday){
					// Get all day events from other days too...
						sd=createDateTime(params.y, params.m, params.d, 00,00,00);
						td=createDateTime(params.y, params.m, params.d, 23,59,59);
						arrayAppend(wc, "end > '#sd#'");
						arrayAppend(wc, "start < '#td#'");
					} else {
						sd=createDateTime(params.y, params.m, params.d, 00,00,00);
						td=createDateTime(params.y, params.m, params.d, 23,59,59);
						arrayAppend(wc, "end > '#sd#'");
						arrayAppend(wc, "start < '#td#'");
					}
				}

			arrayAppend(wc, "allday = #arguments.allday#");
			if(arrayLen(wc)){
				return arrayToList(wc, " AND ");
			} else {
				return "";
			}
	}

	/**
	*  @hint Custom Q for List view
	*/
	private string function _agendaListWC() {
		var sd="";
	 		var td="";
			var wc=[];
			var parsedFrom = "";
			var parsedTo = "";
			// Date Filter
			if(structKeyExists(params, "datefrom")
				AND structKeyExists(params, "dateto")
			){
				parsedFrom = _parseAgendaDateInput(params.datefrom);
				parsedTo = _parseAgendaDateInput(params.dateto);
				if (isDate(parsedFrom) AND isDate(parsedTo)) {
					sd=createDateTime(year(parsedFrom), month(parsedFrom), day(parsedFrom), 00,00,00);
					td=createDateTime(year(parsedTo), month(parsedTo), day(parsedTo), 23,59,59);
					arrayAppend(wc, "start >= '#sd#'");
					arrayAppend(wc, "start <= '#td#'");
				}
			}
			// Status Filter
			if(structKeyExists(params, "status") AND len(params.status)){
				arrayAppend(wc, "status = '#params.status#'");
			}

			// Location Filter
			if(structKeyExists(params, "location") AND len(params.location)){
				arrayAppend(wc, "FIND_IN_SET(locationid, '#params.location#')");
			}

			// Keyword filter
			if(structKeyExists(params, "q") AND len(params.q)){
				params.q=striptags(params.q);
				arrayAppend(wc, "(title LIKE '%#params.q#%' OR description LIKE '%#params.q#%')");

			}

			if(arrayLen(wc)){
				return arrayToList(wc, " AND ");
			} else {
				return "";
			}

	}

	/**
	*  @hint Parse agenda list date input safely. Supports DD/MM/YYYY and MM/DD/YYYY, defaults to DD/MM/YYYY when ambiguous.
	*/
	private any function _parseAgendaDateInput(required any value) {
		var raw = trim(arguments.value & "");
		var normalized = replace(raw, "-", "/", "all");
		var parts = [];
		var p1 = 0;
		var p2 = 0;
		var p3 = 0;

		if (!len(raw)) {
			return "";
		}

		// Handle manually entered day/month/year strings first so we can avoid locale ambiguity.
		if (reFind("^\d{1,2}/\d{1,2}/\d{4}$", normalized)) {
			parts = listToArray(normalized, "/");
			p1 = val(parts[1]);
			p2 = val(parts[2]);
			p3 = val(parts[3]);

			// If one side is > 12 we can infer format, otherwise default to DD/MM/YYYY.
			if (p1 > 12 AND p2 <= 12) {
				return createDateTime(p3, p2, p1, 0, 0, 0);
			}
			if (p2 > 12 AND p1 <= 12) {
				return createDateTime(p3, p1, p2, 0, 0, 0);
			}
			return createDateTime(p3, p2, p1, 0, 0, 0);
		}

		// Fallback for native date objects / unambiguous engine parsing.
		if (isDate(raw)) {
			return parseDateTime(raw);
		}

		return "";
	}


	/**
	*  @hint Sets the model type to use with Custom Fields + Templates
	*/
	public void function _setModelType() {
		request.modeltype="event";
	}

	/**
	*  @hint Remote concurrency Check
	*/
	public void function check() {
		if(structKeyExists(params, "start")
			AND structKeyExists(params, "end")
			AND structKeyExists(params, "location")
			AND structKeyExists(params, "id")){
			// We need to check for any events which overlap with the requested timerange
			// If editing, check we don't bring up the actual event
			// Don't register denied events
			if(len(params.id)){
				eCheck=model("event").findAll(where="status != 'denied' AND id != #params.id# AND start <= '#params.start#' AND end >= '#params.start#' AND locationid = #params.location#");
			} else {
				eCheck=model("event").findAll(where="status != 'denied' AND start <= '#params.start#' AND end >= '#params.start#' AND locationid = #params.location#");
			}

		}
	}
}
