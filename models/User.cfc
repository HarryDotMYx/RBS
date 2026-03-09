//================= Room Booking System / https://github.com/neokoenig =======================--->
component extends="Model" hint="User Model"
{
	/**
	 * @hint Constructor
	 */
	private function config() {
		property(name="fullname", sql="CONCAT(firstname, ' ', lastname)");
		beforeSave("sanitize,securePassword");
		validatesFormatOf(property="email", type="email");
		validatesFormatOf(property="password",
			regEx="^.*(?=.{6,})(?=.*\d)(?=.*[a-z]).*$",
			message="Your password must be at least 6 characters long and contain a mixture of numbers and letters.");
		validatesPresenceOf("firstname,lastname,email");
		validatesPresenceOf(property="password", when="onCreate", message="You must enter a password");
		validate(method="validatePasswordMatch");
		validatesUniquenessOf("email");
	}

	/**
	*  @hint Sanitize inputs
	*/
	public void function sanitize() {
		this.firstname = htmlEditFormat(this.firstname);
		this.lastname = htmlEditFormat(this.lastname);
		this.address1 = htmlEditFormat(this.address1);
		this.address2 = htmlEditFormat(this.address2);
		this.state = htmlEditFormat(this.state);
		this.postcode = htmlEditFormat(this.postcode);
		this.country = htmlEditFormat(this.country);
		this.tel = htmlEditFormat(this.tel);
	}

	/**
	*  @hint Secure Password
	*/
	public void function securePassword() {
		var hasPassword = structKeyExists(this, "password");
		var passwordValue = hasPassword ? trim(toString(this.password)) : "";
		var alreadyHashedThisRequest = structKeyExists(variables, "passwordHashedThisRequest") AND variables.passwordHashedThisRequest;
		var passwordLooksStored = _looksLikeStoredPasswordHash(passwordValue);

		if (alreadyHashedThisRequest AND passwordLooksStored) {
			return;
		}

		// Only hash when a non-empty password is explicitly supplied.
		if (len(passwordValue)) {
			if (!isPasswordChanging() AND passwordLooksStored) {
				return;
			}
			variables.pendingPasswordPlain = passwordValue;
			variables.passwordHashedThisRequest = true;
	     	this.password = _generateAdaptivePasswordHash(passwordValue);
	     	// Keep legacy salt column blank once account is migrated to PBKDF2.
	     	this.salt = "";
	     } else {
			structDelete(variables, "pendingPasswordPlain");
			structDelete(variables, "passwordHashedThisRequest");
		}
	}

	/**
	*  @hint Create PBKDF2 hash for password storage.
	*/
	private string function _generateAdaptivePasswordHash(required string passwordValue) {
		var secureRandom = createObject("java", "java.security.SecureRandom");
		var saltBytes = secureRandom.generateSeed(16);
		var iterations = 210000;
		var keySpec = createObject("java", "javax.crypto.spec.PBEKeySpec").init(
			createObject("java", "java.lang.String").init(arguments.passwordValue & "").toCharArray(),
			saltBytes,
			iterations,
			256
		);
		var skf = createObject("java", "javax.crypto.SecretKeyFactory").getInstance("PBKDF2WithHmacSHA256");
		var derivedBytes = skf.generateSecret(keySpec).getEncoded();
		return "pbkdf2_sha256$#iterations#$#binaryEncode(saltBytes, 'base64')#$#binaryEncode(derivedBytes, 'base64')#";
	}

	public boolean function isPasswordChanging() {
		var hasConfirm = structKeyExists(this, "passwordConfirmation");
		var confirmLen = hasConfirm ? len(trim(toString(this.passwordConfirmation))) : 0;
		return (hasConfirm AND confirmLen GT 0);
	}

	/**
	*  @hint Custom validation for password matching
	*/
	public void function validatePasswordMatch() {
		// Only run validation if we are intending to change the password
		if (isPasswordChanging()) {
			var passwordValue = structKeyExists(variables, "pendingPasswordPlain")
				? trim(variables.pendingPasswordPlain & "")
				: (structKeyExists(this, "password") ? trim(toString(this.password)) : "");
			var confirmationValue = structKeyExists(this, "passwordConfirmation") ? trim(toString(this.passwordConfirmation)) : "";
			if (passwordValue NEQ confirmationValue) {
				addError(property="passwordConfirmation", message="Your passwords must match!");
			}
		}
	}

	/**
	*  @hint Password to blank
	*/
	public void function passwordToBlank() {
		if ( StructKeyExists(variables, "pendingPasswordPlain") ) {
			structDelete(variables, "pendingPasswordPlain");
		}
		if ( StructKeyExists(variables, "passwordHashedThisRequest") ) {
			structDelete(variables, "passwordHashedThisRequest");
		}
		if ( StructKeyExists(this, "password") ){
			this.password = "";
		}
		if ( StructKeyExists(this, "passwordConfirmation") ) {
			this.passwordConfirmation = "";
		}
	}

	private boolean function _looksLikeStoredPasswordHash(required string value) {
		var candidate = trim(arguments.value & "");
		if (!len(candidate)) {
			return false;
		}
		if (left(candidate, 14) EQ "pbkdf2_sha256$") {
			return true;
		}
		return reFindNoCase("^[0-9a-f]{128}$", candidate) EQ 1;
	}

	/**
	*  @hint Set Email conf token (not actually used)
	*/
	public void function setEmailConfirmationToken() {
		this.emailConfirmationToken = generateToken();
	}

	/**
	*  @hint Set PW reset token
	*/
	public string function createPasswordResetToken() {
		var rawToken = generateToken();
		this.passwordResetToken = hashResetToken(rawToken);
		this.passwordResetAt = Now();
		this.save();
		return rawToken;
	}

	/**
	*  @hint make unique token
	*/
	public string function generateToken() {
		var secureRandom = createObject("java", "java.security.SecureRandom");
		return lCase(binaryEncode(secureRandom.generateSeed(32), "hex"));
	}

	/**
	*  @hint Hash reset token before storing in DB.
	*/
	public string function hashResetToken(required string rawToken) {
		return "sha256$" & lCase(hash(arguments.rawToken & "", "SHA-256"));
	}
}
