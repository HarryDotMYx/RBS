<cfset sqlContent = "line1\n-- comment\nline3"><cfset sqlContent = REReplace(sqlContent, "(?m)^--.*$$", "", "ALL")><cfoutput>#sqlContent#</cfoutput>
