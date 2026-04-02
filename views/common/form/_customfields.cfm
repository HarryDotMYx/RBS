<!--- Default Custom field loop --->
<cfparam name="customfields" default="#queryNew('id,name,parentmodel,type,options,class,description,required,customfieldsid,customfieldchildid,customfieldvalueid,value')#">
<cfif customfields.recordcount>
	<cfoutput>
		<cfsavecontent variable="customFieldTemplate">
			<fieldset>
			<legend>Additional Information</legend>
			<cfloop query="customfields">
				[field id=#id#]
			</cfloop>
		</fieldset>
		</cfsavecontent>
		#processShortCodes(customFieldTemplate)#

	</cfoutput>
</cfif>
