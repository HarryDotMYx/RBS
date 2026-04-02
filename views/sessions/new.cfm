<!--- Login Vars--->
<cfparam name="params.email" default="#request.cookie.username#">
<cfparam name="savedemail" default="false">

<!--- Create Vars --->

<Cfset request.pagetitle="Sign In">
<cfif len(params.email)>
	<cfset savedemail = true>
</cfif>
<cfoutput>
<div class="row">
	<div class="col-md-6 col-md-offset-3">
	
		<div class="alert alert-info shadow-sm" role="alert" style="border-radius: 10px; border-left: 5px solid ##31708f; text-align: center; background-color: rgba(217, 237, 247, 0.85); margin-bottom: 25px;">
			<h4 style="color: ##31708f; margin-top: 5px; font-weight: bold;"><i class="fa fa-id-card-o"></i> Don't have an account?</h4>
			<p style="color: ##31708f; font-size: 15px; margin-bottom: 15px;">Please register your personal account in our system to easily request and manage your room bookings.</p>
			<a href="#URLFor(route='register')#" class="btn btn-primary" style="font-weight:bold; border-radius: 20px; padding: 6px 20px;">Register Account Now</a>
		</div>

		#panel(title="Sign In")#
			#includePartial("signin")#
		 #panelend()#
	</div>

</div>


</cfoutput>