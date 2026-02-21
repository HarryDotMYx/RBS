<!---================= Room Booking System / https://github.com/neokoenig =======================--->
<!--- Initial Install --->
<cfinclude template="functions.cfm">
<cfsilent>

	<cfscript>
		c=1;
		request.dsn="roombooking";
		request.showadminform=false;

		if(structKeyExists(form, "email")){
			createInitialAdminUser(request.dsn);
		}

		request.checks=[];
		request.checks[c]["name"]="Check Authentication Key";
		request.checks[c]["result"]=false;
		c++;
		request.checks[c]["name"]="Create Authentication Key";
		request.checks[c]["result"]=false;
		c++;
		request.checks[c]["name"]="Check DSN #request.dsn#";
		request.checks[c]["result"]=false;
		c++;
		request.checks[c]["name"]="Check for Primary Admin User";
		request.checks[c]["result"]=false;
		c++;

		// Auth Key
		if(checkAuthKey()){
			request.checks[1]["result"]=true;
			request.checks[1]["msg"]="Auth key file found";
			request.checks[2]["result"]=true;
			request.checks[2]["msg"]="Skipped as previous step was successful";
		} else {
			if(createAuthKey()){
				request.checks[1]["msg"]="Auth key file not found - will attempt to create";
				request.checks[2]["result"]=true;
				request.checks[2]["msg"]="New Auth Key Created";
			}
		}

		// DSN
		if(testDSN(request.dsn)){
			request.checks[3]["result"]=true;
			request.checks[3]["msg"]="Database schema successfully verified/created.";
			if(checkPrimaryAdmin(request.dsn)){
				request.checks[4]["result"]=true;
				request.checks[4]["msg"]="At least one user in admin role found.";

			} else {
				request.showadminform=true;
				request.checks[4]["msg"]="No user with role admin found: please create one using the form below";
			}
		} else {
			request.checks[3]["msg"]="Database schema creation failed: please check #request.dsn# exists.";
		}

	</cfscript>
</cfsilent>
<cfoutput>
<!DOCTYPE html>
<!--[if lt IE 7]>      <html class="no-js lt-ie9 lt-ie8 lt-ie7"> <![endif]-->
<!--[if IE 7]>         <html class="no-js lt-ie9 lt-ie8"> <![endif]-->
<!--[if IE 8]>         <html class="no-js lt-ie9"> <![endif]-->
<!--[if gt IE 8]><!--> <html class="no-js"> <!--<![endif]-->
<head>
	<meta charset="utf-8">
	<meta http-equiv="X-UA-Compatible" content="IE=edge">
	<title>Installer</title>
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<meta name="HandheldFriendly" content="true">
	<meta name="apple-mobile-web-app-capable" content="yes"><!-- try to forces full-screen for apple devices -->
	<link href="/stylesheets/rbs.min.css" media="all" rel="stylesheet" type="text/css" />
</head>
    <body>
<!-----------------------------HEADER--------------------------->
 <div class="navbar navbar-default">
      <div class="container">
        <div class="navbar-header">
          <button type="button" class="navbar-toggle" data-toggle="collapse" data-target=".navbar-collapse">
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
          </button>
          <a class="navbar-brand" href="/">Roombooking Installer</a>
        </div>
      </div>
    </div>
<!-----------------------------/HEADER--------------------------->

<!-----------------------------CONTENT--------------------------->
	<!--[if lt IE 7]>
		<p class="browsehappy">You are using an <strong>outdated</strong> browser. Please <a href="http://browsehappy.com/">upgrade your browser</a> to improve your experience.</p>
	<![endif]-->
	<section id="main" class="container">

		<cfloop from="1" to="#arraylen(request.checks)#" index="i">
			<div class="box">
				<h4>#request.checks[i]["name"]#</h4>
				<cfif request.checks[i]["result"]>
					<div class="alert alert-success"><p><strong>Success</strong>
				<cfelse>
					<div class="alert alert-danger"><p><strong>Failed</strong>
				</cfif>
				<cfif structKeyExists(request.checks[i], "msg")>
					 <br />#request.checks[i]["msg"]#

				</cfif></p>
				</div>
			</div>
		</cfloop>

 		<cfif request.checks[1]["result"]
	 		AND request.checks[2]["result"]
	 		AND request.checks[3]["result"]
	 		AND request.checks[4]["result"]>
            <cfset fileWrite(expandPath("../config/install.lock"), "installed")>
	 		<div class="alert alert-success">
	 			<h2>Installation Complete!</h2>
	 			<p><strong>All checks passed and the database schema has been successfully configured.</strong></p>
                <p><br/><a href="/?reload=true" class="btn btn-success btn-lg">Click here to start using Room Booking System</a><br/><br/></p>
	 			<p>Other recommended changes once you login:</p>
	 			<ul>
	 				<li>Update the Main Application Settings (Email, Logo)</li>
	 				<li>Update/Add the default locations</li>
	 				<li>Update the default permissions to suit</li>
	 			</ul>
	 		</div>
 		</cfif>

		<cfif request.showadminform>

		<!--- Create Initial Admin User --->
		<div class="well">
		<form method="POST" action="">
			<fieldset>
				<legend>Create Main Admin Account</legend>
				<div class="row">
					<div class="col-md-4">
				<div class="form-group">
					<label for="firstname">firstname</label>
					<input type="text" class="form-control" name="firstname" placeholder="i.e Joe">
				</div>
					</div>
					<div class="col-md-4">
				<div class="form-group">
					<label for="lastname">lastname</label>
					<input type="text" class="form-control" name="lastname" placeholder="i.e Bloggs">
				</div>
					</div>
					<div class="col-md-4">
				<div class="form-group">
					<label for="email">Email address</label>
					<input type="email" class="form-control" name="email" placeholder="i.e admin@domain.com">
				</div>
					</div>
				</div>

				<div class="row">
					<div class="col-md-4">
				<div class="form-group">
					<label for="password">Password</label>
					<input type="password" class="form-control" name="password" placeholder="Password">
				</div>
					</div>
					<div class="col-md-4">
				<div class="form-group">
					<label for="password">Retype Password</label>
					<input type="password" class="form-control" name="password2" placeholder="Re-type Password to confirm">
				</div>
					</div>
				</div>
				<button type="submit" class="btn btn-default">Submit</button>
			</fieldset>
			</form>
			</div>
		</cfif>

	</section>
<!----------------------------/CONTENT--------------------------->

<!-----------------------------Scripts--------------------------->
<script src="../javascripts/rbs.js" type="text/javascript"></script>

    </body>
</html>

</cfoutput>

