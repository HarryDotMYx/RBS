//================= Room Booking System / https://github.com/neokoenig =======================--->
component extends="Controller" hint="Misc Event Data"
{
	/**
	 * @hint Constructor.
	 */
	private function config() {
		
		// super.config() disabled during migration;
// legacy super.init removed for CFWheels2+

		// Additional Permissions
		filters(through="checkPermissionAndRedirect", permission="accesscalendar");
		//filters(through="_isValidAjax");

		// Data
		filters(through="_getResources", only="getevent");

		// Verification
		verifies(only="getevent", params="key", paramsTypes="integer", route="home", error="Sorry, that event can't be found");


		// Formats
		provides("html,json");
		usesLayout(template="modal", only="getevent");
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

		if(structkeyexists(params, "start") AND structkeyexists(params, "end")){

	    	var sd=createDateTime(year(params.start), month(params.start), day(params.start), 00,00,00);
	    	var ed=createDateTime(year(params.end), month(params.end), day(params.end), 00,00,00);

	    		// By building
	    		if(params.type EQ "building"){
	    			data=model("event").findAll(select="id, title, locationid,  class, start, end, allday, status",
	    			where="start >= '#sd#' AND end <= '#ed#' AND locations.building = '#fromTagSafe(params.key)#'", include="location",
	    			order="start ASC");
	    		// By location
	    		} else if(params.type EQ "location"){
					data=model("event").findAll(select="id, title, locationid,  class, start, end, allday, status",
	    			where="start >= '#sd#' AND end <= '#ed#' AND locationid = '#params.key#'", include="location",
	    			order="start ASC");
	    		// All
	    		} else {
	    			data=model("event").findAll(select="id, title, locationid,  class, start, end, allday, status",
	    			where="start >= '#sd#' AND end <= '#ed#'", include="location",
	    			order="start ASC");
	    		}

	    	events=prepeventdata(data);
		    renderText(serializeJSON(events));
		}
		else {
			abort;
		}
	}

	/**
	*  @hint get single event via ajax, i.e for modals
	*/
	public void function getevent() {
		var e = model("event").findOne(where="id = #params.key#", include="location,eventresources(resource)");
		if (!isObject(e)) {
			renderText('<div class="modal-header"><h4 class="modal-title">Event Detail</h4></div><div class="modal-body"><p>Event not found.</p></div>');
			return;
		}
		var html = '';
		html &= '<div class="modal-header">';
		html &= '<button type="button" class="close" data-dismiss="modal"><span aria-hidden="true">&times;</span></button>';
		html &= '<h4 class="modal-title">' & encodeForHTML(e.title) & '</h4>';
		html &= '</div>';
		html &= '<div class="modal-body">';
		html &= '<p><strong>From:</strong> ' & dateFormat(e.start,'dd mmm yyyy') & ' ' & timeFormat(e.start,'HH:mm') & '</p>';
		html &= '<p><strong>To:</strong> ' & dateFormat(e.end,'dd mmm yyyy') & ' ' & timeFormat(e.end,'HH:mm') & '</p>';
		html &= '<p><strong>Location:</strong> ' & encodeForHTML(e.location().name) & '</p>';
		html &= '<p><strong>Status:</strong> ' & encodeForHTML(e.status) & '</p>';
		if (len(trim(e.description))) {
			html &= '<hr><div class="well">' & encodeForHTML(e.description) & '</div>';
		}
		html &= '</div>';
		html &= '<div class="modal-footer"><button type="button" class="btn btn-default" data-dismiss="modal">Close</button></div>';
		renderText(html);
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
