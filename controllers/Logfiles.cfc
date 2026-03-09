//================= Room Booking System / https://github.com/neokoenig =======================--->
component extends="Controller" hint="Manage Logfiles"
{
	/**
	 * @hint Constructor.
	 */
	private function config() {
		
		// super.config() disabled during migration;
// Permission filters
		// legacy super.init removed for CFWheels2+
		protectsFromForgery(with="exception");
		// Additional Permissions
		filters(through="checkPermissionAndRedirect", permission="accesslogfiles");
	}

/******************** Public***********************/
	/**
	*  @hint Log viewer
	*/
	public void function index() {
		param name="params.type" type="string" default="";
		param name="params.userid" default="";
		param name="params.rows" type="numeric" default=250;
		LogFileTypes=_getLogFileTypes();
		users=model("user").findAll(select="id,email", order="lastname");
		var wc = arrayNew(1);
		var safeType = "";
		var safeUserId = 0;
		if(
			structKeyExists(params, "type")
			AND len(params.type)
			AND listFindNoCase(LogFileTypes, trim(params.type))
		){
			safeType = lCase(trim(params.type));
			arrayAppend(wc, "type = '#safeType#'");
		}
		if(structKeyExists(params, "userid") AND isNumeric(params.userid) AND val(params.userid) GT 0){
			safeUserId = val(params.userid);
			arrayAppend(wc, "userid = #safeUserId#");
		}
		if(arrayLen(wc)){
			wc = arrayToList(wc, " AND ");
			logfiles=model("logfiles").findAll(where="#wc#", maxrows=params.rows, order="createdAt DESC");
		} else {
			logfiles=model("logfiles").findAll(maxrows=params.rows, order="createdAt DESC");
		}
	}
/******************** Admin ***********************/

/******************** Private *********************/
	/**
	*  @hint
	*/
	public string function _getLogFileTypes() {
		return "login,success,error,ajax,cookie";
	}
}
