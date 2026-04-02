<cfparam name="user">
<cfset request.pagetitle="Register Account">
<cfoutput>
<div class="row">
	<div class="col-md-8 col-md-offset-2">
		#panel(title="Register Account")#
			#startFormTag(route="registerPost", id="registerForm")#
				#errorMessagesFor("user")#
				
				<div class="row">
					<div class="col-md-6">
						<h4>Personal Details</h4>
						#textField(objectname="user", property="firstname", label="First Name *", required="true", placeholder="e.g Joe")#
						#textField(objectname="user", property="lastname", label="Last Name *", required="true", placeholder="e.g Bloggs")#
						#textField(objectname="user", property="email", label="Email *", type="email", required="true", placeholder="joe@bloggs.com")#
						#textField(objectname="user", property="tel", label="Phone", placeholder="+44 (0) 0000 000000")#
					</div>
					<div class="col-md-6">
						<h4>Account Security</h4>
						#passwordField(objectname="user", property="password", label="Password *", required="true")#
						#passwordField(objectname="user", property="passwordConfirmation", label="Confirm Password *", required="true")#
					</div>
				</div>
				
				<hr/>
				
				#submitTag(value="Register and Login", class="btn btn-primary btn-block append")#
				
				<div class="text-center" style="margin-top: 15px;">
					Already have an account? #linkTo(text="Login here", route="login")#
				</div>
			#endFormTag()#
		#panelend()#
	</div>
</div>
</cfoutput>
