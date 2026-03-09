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
		var rawStart = "";
		var rawEnd = "";
		if(structKeyExists(params, "start")){
			rawStart = params.start;
		} else if(structKeyExists(url, "start")){
			rawStart = url.start;
		} else if(structKeyExists(form, "start")){
			rawStart = form.start;
		}
		if(structKeyExists(params, "end")){
			rawEnd = params.end;
		} else if(structKeyExists(url, "end")){
			rawEnd = url.end;
		} else if(structKeyExists(form, "end")){
			rawEnd = form.end;
		}

		if(!len(trim(rawStart & "")) OR !len(trim(rawEnd & ""))){
			renderText("[]");
			return;
		}

		var parsedStart = _parseCalendarDate(rawStart);
		var parsedEnd = _parseCalendarDate(rawEnd);
		if(!isDate(parsedStart) OR !isDate(parsedEnd)){
			renderText("[]");
			return;
		}
		var sd = createDateTime(year(parsedStart), month(parsedStart), day(parsedStart), 0, 0, 0);
		var ed = createDateTime(year(parsedEnd), month(parsedEnd), day(parsedEnd), 0, 0, 0);
		var safeType = lCase(trim(params.type & ""));
		var sql = "
				SELECT
					e.id,
					e.title,
					e.locationid,
					e.className,
					l.class AS locationClass,
					e.start,
					e.end,
					e.allday,
					e.status
				FROM events e
				INNER JOIN locations l ON l.id = e.locationid
				WHERE e.deletedat IS NULL AND e.start >= ? AND e.end <= ?
		";
		var bindings = [
			{value=sd, cfsqltype="cf_sql_timestamp"},
			{value=ed, cfsqltype="cf_sql_timestamp"}
		];

			if(safeType EQ "building"){
				if(!structKeyExists(params, "key") OR !len(trim(params.key & ""))){
					renderText("[]");
					return;
				}
				sql &= " AND l.building = ?";
				arrayAppend(bindings, {value=fromTagSafe(params.key), cfsqltype="cf_sql_varchar"});
			} else if(safeType EQ "location"){
				if(!structKeyExists(params, "key") OR !isNumeric(params.key)){
					renderText("[]");
					return;
				}
				sql &= " AND e.locationid = ?";
				arrayAppend(bindings, {value=val(params.key), cfsqltype="cf_sql_integer"});
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
		var safeEventId = val(params.key);
		event = queryExecute(
			"
				SELECT
					e.id AS eventid,
					e.title,
					e.start,
					e.end,
					e.status,
					e.layoutstyle,
					e.contactname,
					e.contactemail,
					e.contactno,
					e.description AS eventdescription,
					e.locationid,
					0 AS locationmissing,
					l.name,
					COALESCE(l.description, '') AS description,
					er.resourceid
				FROM events e
				INNER JOIN locations l ON l.id = e.locationid
				LEFT JOIN eventresources er ON er.eventid = e.id
				WHERE e.deletedat IS NULL AND e.id = ?
				ORDER BY er.resourceid ASC
			",
			[
				{value=safeEventId, cfsqltype="cf_sql_integer"}
			],
			{datasource=application.wheels.datasourcename}
		);
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
				var eventCssClass = trim(event.className & "");
				var roomCssClass = reReplaceNoCase(event.locationClass & "", "[^a-z0-9_-]", "", "all");
				var statusCssClass = reReplaceNoCase(lCase(event.status & ""), "[^a-z0-9_-]", "", "all");

				events[c]["id"]=event.id;
				events[c]["title"]=event.title;
				events[c]["start"]=_f_d(event.start);
				events[c]["end"]=_f_d(event.end);
				events[c]["allDay"]=event.allDay;
				events[c]["className"]=trim(listAppend(listAppend(eventCssClass, roomCssClass, " "), statusCssClass, " "));
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

	private any function _parseCalendarDate(required any rawValue) {
		var v = trim(rawValue & "");
		if(!len(v)){
			return "";
		}

		if(isNumeric(v)){
			var n = val(v);
			// Accept Unix timestamp in either seconds or milliseconds.
			if(n GT 1000000000000){
				n = int(n / 1000);
			}
			return dateAdd("s", n, createDateTime(1970, 1, 1, 0, 0, 0));
		}

		try {
			return parseDateTime(v);
		} catch(any e) {
			return "";
		}
	}

 		/**
	*  @hint Sets the model type to use with Custom Fields + Templates
	*/
	public void function _setModelType() {
		request.modeltype="event";
	}
}
