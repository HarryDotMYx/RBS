<!---================= Room Booking System / https://github.com/neokoenig =======================---->
<!--- Location Form--->
<cfif structKeyExists(application.rbs.templates, "location") AND structKeyExists(application.rbs.templates.location, "form")>
	<cfoutput>#processShortCodes(application.rbs.templates.location.form)#</cfoutput>
<cfelse>
	<!--- Default Template: render fields directly --->
	<cfoutput>
	#errorMessagesFor("location")#
	<div class="row">
		<div class="col-sm-4">
			#textField(objectName="location", property="name", label="Name *", class="form-control", placeholder="e.g. Seminar Room 1")#
		</div>
		<div class="col-sm-4">
			#textField(objectName="location", property="building", label="Building", class="form-control", placeholder="e.g. Main Building")#
		</div>
		<div class="col-sm-4">
			#textField(objectName="location", property="description", label="Description", class="form-control", placeholder="e.g. Ground Floor")#
		</div>
	</div>
	<div class="row" style="margin-top:12px;">
		<div class="col-md-3">
			#textField(objectName="location", property="class", label="CSS Class *", class="form-control", placeholder="e.g. avsuite")#
		</div>
		<div class="col-md-3">
			#textField(objectName="location", property="colour", label="HEX Colour *", class="form-control bscp", placeholder="e.g. ##FF5733")#
		</div>
		<div class="col-md-3">
			#textField(objectName="location", property="layouts", label="Layouts", class="form-control", placeholder="e.g. boardroom,lecture")#
		</div>
	</div>
	</cfoutput>
	<cfoutput>#includePartial(partial="/common/form/customfields")#</cfoutput>
</cfif>