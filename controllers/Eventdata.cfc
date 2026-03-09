//================= Room Booking System / https://github.com/neokoenig =======================--->
component extends="Controller" hint="Misc Event Data"
{
	/**
	 * @hint Constructor.
	 */
	private function config() {
		
		// super.config() disabled during migration;
// legacy super.init removed for CFWheels2+
		protectsFromForgery(with="exception");

		// Additional Permissions
		filters(through="checkPermissionAndRedirect", permission="accesscalendar");
		//filters(through="_isValidAjax");

		// Data
		filters(through="_getResources", only="getevent");

		// Verification
		verifies(only="getevent", params="key", paramsTypes="integer", route="home", error="Sorry, that event can't be found");


		// Formats
		provides("html,json");
		usesLayout(template=false, only="getevent");
		filters(through="_setModelType");
	}

/******************** Public***********************/
	/**
	*  @hint Get Events For the provided range via ajax
	*
	* 		 There are three main type of calendar view:
	* 			index - basically everything
	* 			building - a collection of locations
	* 			location - a specific location
	*/
	public void function getevents() {
		param name="params.type" default="";
		if(
			!structKeyExists(params, "start")
			OR !structKeyExists(params, "end")
			OR !isDate(params.start)
			OR !isDate(params.end)
		){
			renderText("[]");
			return;
		}

		var parsedStart = parseDateTime(params.start);
		var parsedEnd = parseDateTime(params.end);
		var sd = createDateTime(year(parsedStart), month(parsedStart), day(parsedStart), 0, 0, 0);
		var ed = createDateTime(year(parsedEnd), month(parsedEnd), day(parsedEnd), 0, 0, 0);
		var safeType = lCase(trim(params.type & ""));
		var sql = "
			SELECT
				e.id,
				e.title,
				e.locationid,
				e.class,
				e.start,
				e.end,
				e.allday,
				e.status
			FROM events e
			INNER JOIN locations l ON l.id = e.locationid
			WHERE e.start >= ? AND e.end <= ?
		";
		var bindings = [sd, ed];

		if(safeType EQ "building"){
			if(!structKeyExists(params, "key") OR !len(trim(params.key & ""))){
				renderText("[]");
				return;
			}
			sql &= " AND l.building = ?";
			arrayAppend(bindings, fromTagSafe(params.key));
		} else if(safeType EQ "location"){
			if(!structKeyExists(params, "key") OR !isNumeric(params.key)){
				renderText("[]");
				return;
			}
			sql &= " AND e.locationid = ?";
			arrayAppend(bindings, val(params.key));
		}

		sql &= " ORDER BY e.start ASC";
		data = queryExecute(
			sql,
			bindings,
			{datasource=application.wheels.datasourcename}
		);
		events=prepeventdata(data);
		renderText(serializeJSON(events));
	}

	/**
	*  @hint get single event via ajax, i.e for modals
	*/
	public void function getevent() {
		event=model("location").findAll(where="events.id = #val(params.key)#", include="events(eventresources)");
		if (!isQuery(event) OR !event.recordcount) {
			renderText('<div class="alert alert-warning"><strong>Event not found.</strong></div>');
			return;
		}
		renderView(action="getevent", layout=false);
	}
/******************** Private *********************/
 	/**
 	*  @hint Sort out event data
 	*/
 	private array function prepeventdata(data) {
 		var events=[];
 		var c=1;

 		for(event in arguments.data){
			events[c]["id"]=event.id;
			events[c]["title"]=event.title;
			events[c]["start"]=_f_d(event.start);
			events[c]["end"]=_f_d(event.end);
			events[c]["allDay"]=event.allDay;
			events[c]["className"]=event.class & ' ' & event.status;
			c++;
 		}
 		return events;
 	}
 	/**
 	*  @hint Experimental date format
 	*/
 	private string function _f_d(str) {
 	 return dateFormat(arguments.str, "YYYY-MM-DD") & "T" & timeFormat(arguments.str, "HH:MM:00");
 	}

 		/**
	*  @hint Sets the model type to use with Custom Fields + Templates
	*/
	public void function _setModelType() {
		request.modeltype="event";
	}
}
