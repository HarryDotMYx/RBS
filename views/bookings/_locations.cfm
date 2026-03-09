<!---================= Room Booking System / https://github.com/neokoenig =======================--->
<cfoutput>
<cfparam name="locations">

<!--- Get Buildings --->
<cfquery dbtype="query" name="buildings">
	SELECT DISTINCT building FROM locations WHERE building IS NOT NULL;
</cfquery>

<!--- Inline CSS with !important to ensure room colors show up over btn-default --->
<cfif application.rbs.setting.showlocationcolours>
<style>
<cfloop query="locations">
	<cfset safeCssClass = reReplaceNoCase(class & "", "[^a-z0-9_-]", "", "all")>
	<cfset safeColour = trim(colour & "")>
	<cfif reFindNoCase("^##?[0-9a-f]{3}([0-9a-f]{3})?$", safeColour)>
		<cfif left(safeColour, 1) NEQ "##"><cfset safeColour = "##" & safeColour></cfif>
	</cfif>
	<cfif len(safeCssClass) AND reFindNoCase("^##[0-9a-f]{3}([0-9a-f]{3})?$", safeColour)>
		.#safeCssClass# { background-color: #lCase(safeColour)# !important; border-color: #lCase(safeColour)# !important; color: ##ffffff !important; }
		.pending.#safeCssClass# { color: #lCase(safeColour)# !important; }
	</cfif>
</cfloop>
/* Flex layout for location buttons to prevent overlap */
.building-row, .location-row {
    display: flex !important;
    flex-wrap: wrap;
    gap: 5px;
    margin-bottom: 10px;
}
.location-filter {
    flex: 1 1 auto;
    white-space: nowrap;
    text-align: center;
    border-radius: 4px !important;
}
</style>
</cfif>

<div id="location-filter">
	<div class="building-row">
	#linkTo(action="index",  class="btn btn-primary btn-sm location-filter", data_id="all", text="All")#
	<cfif buildings.recordcount>
		<cfloop query="buildings">
			<cfset safeBuildingTag = reReplaceNoCase(toTagSafe(building), "[^a-z0-9_-]", "", "all")>
			#linkTo(controller="bookings", action="building", key=safeBuildingTag, class="#iif(params.key EQ safeBuildingTag, '"active"', '')# btn btn-sm btn-primary location-filter", data_id="#safeBuildingTag#", text="#h(building)#", encode=false)#
		</cfloop>
	</cfif>
	</div>
	<div class="location-row">
		<cfloop query="locations">
			<cfset safeBuildingClass = reReplaceNoCase(toTagSafe(building), "[^a-z0-9_-]", "", "all")>
			<cfset safeLocationClass = reReplaceNoCase(class & "", "[^a-z0-9_-]", "", "all")>
			#linkTo(controller="bookings", action="location", key=id, class="all #safeBuildingClass# btn btn-sm location-filter #safeLocationClass# location#id#", text="<b>#h(name)#</b><br /><small>#h(description)#</small>", encode=false)#
		</cfloop>
	</div>
</div>
</cfoutput>
