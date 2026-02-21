<cfscript>
try {
    flashInsert(error="This is a test error message.");
    writeOutput(flashMessages());
} catch(any e) {
    writeOutput(e.message);
}
</cfscript>
