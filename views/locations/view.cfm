<!---================= Room Booking System / https://github.com/neokoenig =======================--->
<!--- Location View--->
<cfparam name="location">
<cfparam name="customfields">
<cfoutput>
#panel(title="Location Details")#
<cfif structKeyExists(application.rbs.templates, "location") AND structKeyExists(application.rbs.templates.location, "output")>
	 #processShortCodes(application.rbs.templates.location.output)#
<cfelse>
	<div class="row">
		<div class="col-md-3">
			<cfif len(trim(location.name))>
				<p><strong>Name:</strong> #h(location.name)#</p>
			</cfif>
			<cfif len(trim(location.description))>
				<p><strong>Description:</strong> #h(location.description)#</p>
			</cfif>
			<cfif len(trim(location.class))>
				<p><strong>Class:</strong> #h(location.class)#</p>
			</cfif>
			<cfif len(trim(location.colour))>
				<p><strong>Colour:</strong> #h(location.colour)#</p>
			</cfif>
		</div>
		<div class="col-md-3">
			<cfif customfields.recordcount>
				<cfoutput>
					<cfloop query="customfields">
						<cfif len(trim(value))>
							<p><strong>#h(name)#:</strong> #h(value)#</p>
						</cfif>
					</cfloop>
				</cfoutput>
			</cfif>
		</div>
	</div>
</cfif>


#panelEnd()#
</cfoutput>
