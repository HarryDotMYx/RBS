//================= Room Booking System / https://github.com/neokoenig =======================--->
component extends="Controller" hint=""
{
	/**
	 * @hint Constructor.
	 */
	private function config() {
		
		// super.config() disabled during migration;
// Permission filters
		// legacy super.init removed for CFWheels2+
		protectsFromForgery(with="exception");
		filters(through="requirePostRequest", only="create,update");
		filters(through="redirectIfLoggedIn");
		filters(through="denyInDemoMode");
	}

/******************** Public***********************/
 	/**
 	*  @hint Create a pw reset email
 	*/
	public void function create() {
		if(!requirePostRequest()){
			return;
		}
		param name="params.email" default="";
	 	user = model("user").findOneByEmail(params.email);
		if ( isObject(user) ) {
			user.passwordResetTokenRaw = user.createPasswordResetToken();
			try {
				var mailArgs = {
					to=user.email,
					from="#application.rbs.setting.sitetitle# <#application.rbs.setting.siteemailaddress#>",
					subject="[#application.rbs.setting.sitetitle#] Password Reset Request",
					template="/email/passwordReset",
					user=user
				};
				structAppend(mailArgs, getMailDeliverySettings(), true);
				sendEmail(argumentCollection=mailArgs);
			} catch(any mailError){
				writeLog(
					file="application",
					type="error",
					text="[PASSWORD_RESET] Failed to send reset email to #user.email#: #mailError.message#"
				);
			}
		} else {
			addLogLine(type="Login", message="Password reset requested for unknown email #h(params.email)#");
		}
		flashInsert(success="If an account exists for that email, password reset instructions have been sent.");
		redirectTo(action="new");
	}

 	/**
 	*  @hint Update pw form
 	*/
	public void function edit() {
		user = _findUserByResetToken(params.key);
		if (!isObject(user)) {
			redirectTo(action="new", error="Password reset link is invalid or has already been used.");
			return;
		}
		if (!isDate(user.passwordResetAt) OR DateDiff("h", user.passwordResetAt, Now()) > 2) {
			redirectTo(action="new", error="Password reset has expired. [PR2]");
			return;
		}
		user.passwordToBlank();
	}

 	/**
 	*  @hint Update pw
 	*/
	public void function update() {
		if(!requirePostRequest()){
			return;
		}
		user = _findUserByResetToken(params.key);
		if(!isObject(user)){
			redirectTo(action="new", error="Password reset link is invalid or has already been used.");
			return;
		}
		if (!isDate(user.passwordResetAt) OR DateDiff("h", user.passwordResetAt, Now()) > 2) {
			redirectTo(action="new", error="Password reset has expired. [PR2]");
			return;
		}
		if(!structKeyExists(params, "user") OR !isStruct(params.user)){
			redirectTo(action="edit", key=params.key, error="Please enter a new password.");
			return;
		}

		// Invalidate token on successful reset to prevent replay.
		user.passwordResetToken = "";
		user.passwordResetAt = "";
		if ( user.update(params.user) ) {
			addLogLine(type="login", success="Password reset successfully.");
			_createUserInScope(user);
		}
		else {
			redirectTo(route="home", error="Sorry, that request failed [PR1]");
		}
 	}

	/**
	*  @hint Resolve a user by reset token (supports hashed tokens + legacy plain tokens).
	*/
	private any function _findUserByResetToken(required any tokenCandidate) {
		var rawToken = trim(arguments.tokenCandidate & "");
		var tokenHash = "";
		var tokenLookup = queryNew("");
		if(!len(rawToken)){
			return "";
		}

		tokenHash = model("user").hashResetToken(rawToken);
		tokenLookup = queryExecute(
			"SELECT id FROM users WHERE passwordResetToken = ? AND deletedat IS NULL LIMIT 1",
			[tokenHash],
			{datasource=application.wheels.datasourcename}
		);
		if(tokenLookup.recordCount){
			return model("user").findByKey(val(tokenLookup.id[1]));
		}

		// Backward compatibility for old plaintext tokens issued before hashing rollout.
		tokenLookup = queryExecute(
			"SELECT id FROM users WHERE passwordResetToken = ? AND deletedat IS NULL LIMIT 1",
			[rawToken],
			{datasource=application.wheels.datasourcename}
		);
		if(tokenLookup.recordCount){
			return model("user").findByKey(val(tokenLookup.id[1]));
		}

		return "";
	}
}
