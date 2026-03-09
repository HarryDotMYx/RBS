//================= Room Booking System / https://github.com/neokoenig =======================--->
component extends="Controller" hint="Main User Controller"
{
	/**
	 * @hint Constructor.
	 */
	private function config() {
		
		// super.config() disabled during migration;
// Permission filters
		// legacy super.init removed for CFWheels2+
		protectsFromForgery(with="exception");
		filters(through="_checkLoggedIn");
		filters(through="requirePostRequest", only="create,update,delete,assumeUser,generateAPIKey,updateaccount,updatepassword");
		filters(through="checkPermissionAndRedirect", permission="accessUsers", except="myaccount,updateaccount,updatepassword");
		filters(through="checkPermissionAndRedirect", permission="updateOwnAccount", only="myaccount,updateaccount,updatepassword");
		filters(through="denyInDemoMode", only="create,update,updateaccount,updatepassword,assumeuser,generateAPIKey");

		// Verification
		verifies(only="edit,update,delete,assumeUser,recover,generateAPIKey", params="key", paramsTypes="integer", route="home", error="Sorry, that user can't be found");


		// Data
		filters(through="getCurrentUser", only="myaccount,updateaccount,updatepassword");
		filters(through="_getRoles", only="index,add,edit,delete,update,create");
	}

	/**
	*  @hint Redirect to login if not logged in
	*/
	public void function _checkLoggedIn() {
		if(!StructKeyExists(session, "currentUser")) {
			redirectTo(route="login");
		}
	}


/******************** Public***********************/

	/**
	*  @hint User Dashboard / My Account
	*/
	public void function myaccount() {
		// user is already loaded via filter getCurrentUser
	}

	/**
	*  @hint Password Change View (renders myaccount)
	*/
	public void function mypassword() {
		renderView(action="myaccount");
	}

	/**
	*  @hint Main Account Update
	*/
	public void function updateaccount() {
		if(!requirePostRequest()){
			return;
		}
		if(structKeyExists(params, "password")){
			structDelete(params, "password");
			structDelete(params, "passwordConfirmation");
		}
		if(structKeyExists(params, "user")){
			structDelete(params.user, "password");
			structDelete(params.user, "passwordConfirmation");
			structDelete(params.user, "salt");
			structDelete(params.user, "role");
			user.update(params.user);
			// Extra defensive: ensure the loaded object doesn't have a confirmation property set by auto-binding or cleanup
			structDelete(user, "passwordConfirmation");
			if(user.save()){
				redirectTo(route="myaccount", success="Personal account details successfully updated");
			}
			else {
				renderView(action="myaccount");
			}
		}
	}

	/**
	*  @hint Seperate PW change update
	*/
	public void function updatepassword() {
		if(!requirePostRequest()){
			return;
		}
		if(structKeyExists(params, "password") AND structKeyExists(params, "passwordConfirmation")){
			user.update(
				password=params.password,
				passwordConfirmation=params.passwordConfirmation
			);
			if(user.save()){
				redirectTo(action="myaccount", success="Password successfully updated");
			}
			else {
				renderView(action="myaccount");
			}
		}
		else {
			redirectTo(action="myaccount", error="Please enter both password and confirmation");
		}
	}
/******************** Admin ***********************/
	/**
	*  @hint Login as targeted user
	*/
	public void function assumeUser() {
		if(!requirePostRequest()){
			return;
		}
		if(!userIsInRole("admin")){
			redirectTo(route="denied", error="Only administrators can assume another user.");
			return;
		}
		if(!application.rbs.setting.isdemomode){
				user=model("user").findOne(where="id = #val(params.key)#");
				_createUserInScope(user);
		}
		else {
			redirectTo( controller="users", action="index", success="Not allowed in demo mode");
		}
	}
	/**
	*  @hint Administrators only, account listings
	*/
	public void function index() {
		param name="params.page" default=1;
		users=model("user").findAll( group="id", includeSoftDeletes=false, perPage=25, page=params.page);
	}
	/**
	*  @hint Add New User
	*/
	public void function add() {
		user=model("user").new();
	}
	/**
	*  @hint Edit User
	*/
	public void function edit() {
		user=model("user").findOne(where="id = #val(params.key)#");
	}
	/**
	*  @hint Create Account
	*/
	public void function create() {
		if(!requirePostRequest()){
			return;
		}
		if(structkeyexists(params, "user")){
	    	user = model("user").new(params.user);
			if ( user.save() ) {
				redirectTo( controller="users", action="index", success="User account successfully created");
			}
	        else {
				renderView( controller="users", action="add", error="");
			}
		}
	}
	/**
	*  @hint
	*/
	public void function update() {
		if(!requirePostRequest()){
			return;
		}
		if(!application.rbs.setting.isdemomode){
			if(structkeyexists(params, "user")){
				user = model("user").findOne(where="id = #val(params.key)#");
				user.update(params.user);
				if ( user.save() )  {
					redirectTo( controller="users", action="index", success="User account successfully updated");
				}
				else {
					flashInsert(error="There were problems updating that user");
					renderView( controller="users", action="edit");
				}
			}
		} else {
			redirectTo( controller="users", action="index", success="Not updated in demo mode");
		}
	}
		/**
		*  @hint Hard Delete (Purge) an Account
		*/
		public void function delete() {
			if(!requirePostRequest()){
				return;
			}
			if(!application.rbs.setting.isdemomode){
				if(structKeyExists(params, "key") && isNumeric(params.key)){
					user = model("user").findOne(where="id = #val(params.key)#", includeSoftDeletes=true);
					if(!isObject(user)){
						redirectTo(controller="users", action="index", error="That user no longer exists.");
						return;
					}

					// Defensive guardrails for direct-URL calls.
					if(structKeyExists(user, "role") && lCase(user.role & "") EQ "admin"){
						redirectTo(controller="users", action="index", error="Admin accounts cannot be purged.");
						return;
					}
						if(structKeyExists(session, "currentUser") && structKeyExists(session.currentUser, "id") && val(session.currentUser.id) EQ val(params.key)){
							redirectTo(controller="users", action="index", error="You cannot purge your own account.");
							return;
						}

						_purgeUserById(val(params.key));
						redirectTo(controller="users", action="index", success="User permanently deleted.");
						return;
					}
			} else {
				redirectTo(controller="users", action="index", success="Not updated in demo mode");
			}
		}
		/**
		*  @hint Recover a deleted Account
		*/
		public void function recover() {
			redirectTo(controller="users", action="index", error="Recover is disabled. Accounts are permanently deleted.");
		}

/******************** Ajax/Remote/Misc*************/
	/**
	*  @hint Generates An API Key for a user account
	*/
	public void function generateAPIKey() {
			if(!requirePostRequest()){
				return;
			}
			if(!userIsInRole("admin")){
				redirectTo(route="denied", error="Only administrators can generate API keys for users.");
				return;
			}
			user=model("user").findOneByID(params.key);
			if(isObject(user)){
				user.apitoken=_generateApiKey();
				user.save();
				redirectTo(controller="users", action="index", success="Key generation successful");
			} else {
				redirectTo(controller="users", action="index", error="Key generation failed - User not found");
			}
	}
}
