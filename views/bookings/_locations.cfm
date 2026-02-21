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
	<cfif len(colour)>
		.#class# { background-color: #colour# !important; border-color: #colour# !important; color: ##ffffff !important; }
		.pending.#class# { color: #colour# !important; }
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
			#linkTo(controller="bookings", action="building", key=toTagSafe(building), class="#iif(params.key EQ toTagSafe(building), '"active"', '')# btn btn-sm btn-primary location-filter", data_id="#toTagSafe(building)#", text="#building#")#
		</cfloop>
	</cfif>
	</div>
	<div class="location-row">
		<cfloop query="locations">
			#linkTo(controller="bookings", action="location", key=id, class="all #toTagSafe(building)# btn btn-sm location-filter #class# location#id#", text="<b>#name#</b><br /><small>#description#</small>", encode=false)#
		</cfloop>
	</div>
</div>
</cfoutput>