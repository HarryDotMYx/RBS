<cfscript>
// Keep backward compatibility only if Application.cfc did not set a name.
if (!structKeyExists(this, "name") || !len(trim(this.name & ""))) {
	this.name = "RoomBooking-W3";
}
</cfscript>
