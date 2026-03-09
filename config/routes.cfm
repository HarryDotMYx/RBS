<cfscript>
	mapper()
		.get(name="home", pattern="/", controller="bookings", action="index")
		.post(name="updateaccount", pattern="/my/account/u", controller="users", action="updateaccount")
		.get(name="myaccount", pattern="/my/account", controller="users", action="myaccount")
		.post(name="updatepassword", pattern="/my/password/u", controller="users", action="updatepassword")
		.get(name="mypassword", pattern="/my/password", controller="users", action="mypassword")
		.get(name="login", pattern="/login", controller="sessions", action="new")
		.post(name="attemptlogin", pattern="/login/a", controller="sessions", action="attemptlogin")
		.post(name="logout", pattern="/logout", controller="sessions", action="logout")
		.get(name="forgetme", pattern="/forgetme", controller="sessions", action="forgetme")
	.get(name="denied", pattern="/denied", controller="sessions", action="denied")
	.get(name="getEvents", pattern="/eventdata/getevents/[type]/[key]", controller="eventdata", action="getevents")
	.get(name="getEvent", pattern="/eventdata/getevent/[key]", controller="eventdata", action="getevent")
	.wildcard()
	.root(to="bookings##index")
	.end();
</cfscript>
