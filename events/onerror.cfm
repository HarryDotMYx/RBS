<!--- Place HTML here that should be displayed when an error is encountered while running in "production" mode. --->

<cflog file="application" type="error" text="#arguments.exception.message# - #arguments.exception.detail#">
<cfdump var="#arguments.exception#">