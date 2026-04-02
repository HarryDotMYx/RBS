//================= Room Booking System / https://github.com/neokoenig =======================--->
component extends="Controller" hint="Registrations Controller"
{
	/**
	 * @hint Constructor.
	 */
	private function config() {
		protectsFromForgery(with="exception", except="create");
		filters(through="requirePostRequest", only="create", verifyCsrf=false);
		filters(through="redirectIfLoggedIn", only="new,create,confirm");
	}

	/**
	*  @hint Display Registration Form
	*/
	public void function new() {
		user = model("user").new();
	}

	/**
	*  @hint Process Account Creation
	*/
	public void function create() {
		if(!requirePostRequest()){
			return;
		}
		if(structkeyexists(params, "user")){
	    	user = model("user").new(params.user);
			// Security measure: Force role to standard user
			user.role = "user";
			user.emailConfirmed = 0;
			user.setEmailConfirmationToken();
			
			if ( user.save() ) {
				addLogline(type="Registration", message="#user.email# successfully registered.", userid=user.id);
				
				try {
					var mailArgs = {
						to=user.email,
						from="#application.rbs.setting.sitetitle# <#application.rbs.setting.siteemailaddress#>",
						subject="[#application.rbs.setting.sitetitle#] Confirm your email address",
						template="/email/emailconfirmation",
						user=user
					};
					structAppend(mailArgs, getMailDeliverySettings(), true);
					sendEmail(argumentCollection=mailArgs);
				} catch(any mailError){
					writeLog(
						file="application",
						type="error",
						text="[REGISTRATION] Failed to send confirmation email to #user.email#: #mailError.message#"
					);
				}
				
				redirectTo(route="login", success="🚀 Registration successful! A verification link has been sent to your inbox. Please verify your email address to activate your account.");
			}
	        else {
				renderView(action="new");
			}
		} else {
            redirectTo(route="register", error="Please provide user details.");
        }
	}

	/**
	*  @hint Confirm Email
	*/
	public void function confirm() {
		if(!structKeyExists(params, "key") OR !len(params.key)){
			redirectTo(route="login", error="❌ Invalid confirmation link. Please check your email and try again.");
			return;
		}
		user = model("user").findOneByEmailConfirmationToken(params.key);
		if(isObject(user)){
			user.update(emailConfirmed=1, emailConfirmationToken="");
			redirectTo(route="login", success="🎉 Email successfully verified! Welcome aboard. Your account is now fully active and you may log in.");
		} else {
			redirectTo(route="login", error="❌ This confirmation link is invalid or has already been used. Please contact support if you need assistance.");
		}
	}
}
