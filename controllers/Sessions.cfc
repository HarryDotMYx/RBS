//================= Room Booking System / https://github.com/neokoenig =======================--->
component extends="Controller" hint="Sessions Controller"
{
	/**
	 * @hint Constructor.
	 */
	private function config() {
		
		// super.config() disabled during migration;
// Permission filters - NB, doesn't go via super.init()
		filters(through="redirectIfLoggedIn", only="new,attemptlogin");
	}



/******************** Public***********************/
	public void function new() {
		// Render login page
	}

	public void function denied() {
		// Render denied page
	}

	public void function attemptlogin() {
		var p={};
		var user = "";
		if(structKeyExists(params, "email") AND structKeyExists(params, "password")){
			user = model("user").findOneByEmail(params.email);

			if(isObject(user)){
				try {
					p.salt.decrypted = decrypt(user.salt, getAuthKey(), 'CFMX_COMPAT');
				} catch(any e) {
					// fallback for edge legacy rows
					p.salt.decrypted = user.salt;
				}
				p.password.hashed = hash(params.password & p.salt.decrypted, 'SHA-512');
				if(p.password.hashed EQ user.password){
					if(structKeyExists(params, "rememberme")){
						setCookieRememberUsername(params.email);
					}
					addlogline(type="Login", message="#user.email# successfully logged in", userid=user.id);
					_createUserInScope(user);
					return;
				}
				_denyLogin("Login failed: password verification mismatch for #h(params.email)#.");
				return;
			}

			_denyLogin("Login failed: account not found for #h(params.email)#.");
			return;
		}

		_denyLogin("Login failed: missing email or password.");
	}

	/**
	*  @hint Logout a user
	*/
	public void function logout() {
		StructDelete(session, "currentUser");
		redirectTo(route="home", success="You have been successfully signed out");
	}

	/**
	*  @hint Forget Users cookie
	*/
	public void function forgetme() {
		setCookieForgetUsername();
		redirectTo(route="login");
	}

	/**
	* @hint Prevent logged-in users from hitting login actions
	*/
	public void function redirectIfLoggedIn() {
		if (isLoggedIn()) {
			location(url="/", addToken=false, statusCode=302);
			abort;
		}
	}

	/**
	* @hint Log and reject an invalid login attempt with consistent user-facing message
	*/
	private void function _denyLogin(required string logMessage) {
		addLogline(type="Login", message=arguments.logMessage);
		redirectTo(
			error="We couldn't sign you in. Please check your email and password, then try again.",
			route="login"
		);
	}
}
