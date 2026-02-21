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
	/**
	*  @hint Login procedure
	*/
	public void function new() {
		// Render login page
	}

	public void function denied() {
		// Render denied page
	}

	public void function attemptlogin() {
		var p={};
		if(structkeyexists(params, "email") AND structkeyexists(params, "password")){
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
					if(structkeyexists(params, "rememberme")){
						setCookieRememberUsername(params.email);
					}
					addlogline(type="Login", message="#user.email# successfully logged in", userid=user.id);
					_createUserInScope(user);
					return;
				}
				addLogline(type="Login", message="PW doesn't match hashed");
				RedirectTo(error="We could not sign you in. Please try that again.", route="login");
				return;
			}

			addLogline(type="Login", message="Bad Login [User isn't object, searched for #h(params.email)#]");
			RedirectTo(error="We could not sign you in. Please try that again.", route="login");
			return;
		}

		addLogline(type="Login", message="Bad Login [Need Email and Password]");
		RedirectTo(error="We could not sign you in. Please try that again.", route="login");
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
}
