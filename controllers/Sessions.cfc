//================= Room Booking System / https://github.com/neokoenig =======================--->
component extends="Controller" hint="Sessions Controller"
{
	/**
	 * @hint Constructor.
	 */
	private function config() {
		
		// super.config() disabled during migration;
// Permission filters - NB, doesn't go via super.init()
		protectsFromForgery(with="exception");
		filters(through="requirePostRequest", only="attemptlogin,logout");
		filters(through="redirectIfLoggedIn", only="new,attemptlogin");
	}



/******************** Public***********************/
	public void function new() {
		// Render login page
	}

	public void function denied() {
		// Render denied page
	}

	public void function attemptlogin() {
		if(!requirePostRequest()){
			return;
		}
		var enteredPassword = "";
		var user = "";
		var normalizedEmail = structKeyExists(params, "email") ? lCase(trim(params.email & "")) : "";
		var clientIp = getIPAddress();
		if(structKeyExists(params, "email") AND structKeyExists(params, "password")){
			if(_isLoginLockedOut(emailKey=normalizedEmail, ipAddress=clientIp)){
				_denyLogin(
					logMessage="Login throttled: too many failed attempts for #h(normalizedEmail)# from #h(clientIp)#.",
					emailKey=normalizedEmail,
					ipAddress=clientIp,
					skipFailureRecord=true,
					userMessage="Too many sign-in attempts. Please wait 10 minutes and try again."
				);
				return;
			}
			enteredPassword = params.password & "";
			user = model("user").findOneByEmail(params.email);

			if(isObject(user)){
				if(
					_verifyPasswordAgainstStoredHash(
						plainPassword=enteredPassword,
						storedHash=user.password & "",
						legacySalt=structKeyExists(user, "salt") ? (user.salt & "") : ""
					)
				){
					_upgradePasswordHashIfNeeded(userId=user.id, plainPassword=enteredPassword, storedHash=user.password & "");
					if(structKeyExists(params, "rememberme")){
						setCookieRememberUsername(params.email);
					}
					_clearFailedLoginAttempts(emailKey=normalizedEmail, ipAddress=clientIp);
					addlogline(type="Login", message="#user.email# successfully logged in", userid=user.id);
					_createUserInScope(user);
					return;
				}
				_denyLogin(
					logMessage="Login failed: password verification mismatch for #h(params.email)#.",
					emailKey=normalizedEmail,
					ipAddress=clientIp
				);
				return;
			}

			_denyLogin(
				logMessage="Login failed: account not found for #h(params.email)#.",
				emailKey=normalizedEmail,
				ipAddress=clientIp
			);
			return;
		}
		_denyLogin(
			logMessage="Login failed: missing email or password.",
			emailKey=normalizedEmail,
			ipAddress=clientIp
		);
	}

	/**
	*  @hint Logout a user
	*/
	public void function logout() {
		if(!requirePostRequest()){
			return;
		}
		StructDelete(session, "currentUser");
		redirectTo(route="home", success="You have been successfully signed out");
	}

	/**
	*  @hint Forget Users cookie
	*/
	public void function forgetme() {
		setCookieForgetUsername();
		redirectTo(route="login");
	}

	/**
	* @hint Prevent logged-in users from hitting login actions
	*/
	public void function redirectIfLoggedIn() {
		if (isLoggedIn()) {
			location(url="/", addToken=false, statusCode=302);
			abort;
		}
	}

	/**
	* @hint Log and reject an invalid login attempt with consistent user-facing message
	*/
	private void function _denyLogin(
		required string logMessage,
		string emailKey="",
		string ipAddress="",
		boolean skipFailureRecord=false,
		string userMessage="We couldn't sign you in. Please check your email and password, then try again."
	) {
		addLogline(type="Login", message=arguments.logMessage);
		if(!arguments.skipFailureRecord){
			_recordFailedLoginAttempt(arguments.emailKey, arguments.ipAddress);
		}
		// Small fixed delay slows brute-force attempts without blocking legitimate users for long.
		sleep(700);
		redirectTo(
			error=arguments.userMessage,
			route="login"
		);
	}

	/**
	* @hint Returns true when a login key is currently locked due to repeated failures.
	*/
	private boolean function _isLoginLockedOut(required string emailKey, required string ipAddress) {
		var throttleKey = _buildLoginThrottleKey(arguments.emailKey, arguments.ipAddress);
		var isLocked = false;
		var nowTs = now();
		lock name="rbs-login-throttle" type="exclusive" timeout="5" {
			_ensureLoginThrottleStore();
			if(structKeyExists(application.loginThrottle, throttleKey)){
				var bucket = application.loginThrottle[throttleKey];
				if(structKeyExists(bucket, "lockUntil") AND isDate(bucket.lockUntil) AND dateCompare(bucket.lockUntil, nowTs) GTE 0){
					isLocked = true;
				} else if(
					structKeyExists(bucket, "firstFailAt")
					AND isDate(bucket.firstFailAt)
					AND dateDiff("n", bucket.firstFailAt, nowTs) GT _loginThrottleWindowMinutes()
				){
					structDelete(application.loginThrottle, throttleKey);
				}
			}
		}
		return isLocked;
	}

	/**
	* @hint Track one failed login attempt and lock key after threshold.
	*/
	private void function _recordFailedLoginAttempt(required string emailKey, required string ipAddress) {
		var throttleKey = _buildLoginThrottleKey(arguments.emailKey, arguments.ipAddress);
		var nowTs = now();
		lock name="rbs-login-throttle" type="exclusive" timeout="5" {
			_ensureLoginThrottleStore();
			if(
				!structKeyExists(application.loginThrottle, throttleKey)
				OR !isStruct(application.loginThrottle[throttleKey])
			){
				application.loginThrottle[throttleKey] = {failCount=0, firstFailAt=nowTs, lockUntil=""};
			}
			var bucket = application.loginThrottle[throttleKey];
			if(
				structKeyExists(bucket, "firstFailAt")
				AND isDate(bucket.firstFailAt)
				AND dateDiff("n", bucket.firstFailAt, nowTs) GT _loginThrottleWindowMinutes()
			){
				bucket.failCount = 0;
				bucket.firstFailAt = nowTs;
				bucket.lockUntil = "";
			}
			bucket.failCount = val(bucket.failCount) + 1;
			if(bucket.failCount GTE _loginThrottleMaxAttempts()){
				bucket.lockUntil = dateAdd("n", _loginThrottleLockMinutes(), nowTs);
				bucket.failCount = 0;
				bucket.firstFailAt = nowTs;
			}
			application.loginThrottle[throttleKey] = bucket;
		}
	}

	/**
	* @hint Clear failed login counters on successful authentication.
	*/
	private void function _clearFailedLoginAttempts(required string emailKey, required string ipAddress) {
		var throttleKey = _buildLoginThrottleKey(arguments.emailKey, arguments.ipAddress);
		lock name="rbs-login-throttle" type="exclusive" timeout="5" {
			_ensureLoginThrottleStore();
			if(structKeyExists(application.loginThrottle, throttleKey)){
				structDelete(application.loginThrottle, throttleKey);
			}
		}
	}

	/**
	* @hint Ensure throttle store exists in application scope.
	*/
	private void function _ensureLoginThrottleStore() {
		if(!structKeyExists(application, "loginThrottle") OR !isStruct(application.loginThrottle)){
			application.loginThrottle = {};
		}
	}

	/**
	* @hint Build stable throttle key using email + source IP.
	*/
	private string function _buildLoginThrottleKey(required string emailKey, required string ipAddress) {
		var safeEmail = len(trim(arguments.emailKey & "")) ? lCase(trim(arguments.emailKey & "")) : "_blank";
		var safeIp = len(trim(arguments.ipAddress & "")) ? trim(arguments.ipAddress & "") : "unknown";
		return safeEmail & "|" & safeIp;
	}

	private numeric function _loginThrottleMaxAttempts() {
		return 5;
	}

	private numeric function _loginThrottleWindowMinutes() {
		return 10;
	}

	private numeric function _loginThrottleLockMinutes() {
		return 10;
	}

	/**
	* @hint Rehash legacy password rows to PBKDF2 on successful login.
	*/
	private void function _upgradePasswordHashIfNeeded(
		required numeric userId,
		required string plainPassword,
		required string storedHash
	) {
		var shouldUpgrade = _passwordHashNeedsUpgrade(arguments.storedHash);
		if(!shouldUpgrade){
			return;
		}
		try {
			var newHash = _generateAdaptivePasswordHash(arguments.plainPassword);
			queryExecute(
				"UPDATE users SET password = ?, salt = '' WHERE id = ? LIMIT 1",
				[newHash, val(arguments.userId)],
				{datasource=application.wheels.datasourcename}
			);
		} catch(any e) {
			writeLog(
				file="application",
				type="warning",
				text="[PASSWORD_UPGRADE] Failed to upgrade password hash for user ##arguments.userId##: ##e.message##"
			);
		}
	}

	/**
	* @hint Returns true when stored hash is legacy or below target work factor.
	*/
	private boolean function _passwordHashNeedsUpgrade(required string storedHash) {
		var hashValue = trim(arguments.storedHash & "");
		if(left(hashValue, 14) NEQ "pbkdf2_sha256$"){
			return true;
		}
		var parts = listToArray(hashValue, "$");
		if(arrayLen(parts) LT 4){
			return true;
		}
		return (val(parts[2]) LT 210000);
	}

	/**
	* @hint Verify a plain password against stored hash (supports legacy SHA-512 rows).
	*/
	private boolean function _verifyPasswordAgainstStoredHash(
		required string plainPassword,
		required string storedHash,
		string legacySalt = ""
	) {
		var hashValue = trim(arguments.storedHash & "");
		if(left(hashValue, 14) EQ "pbkdf2_sha256$"){
			return _verifyPbkdf2Password(arguments.plainPassword, hashValue);
		}

		var saltValue = trim(arguments.legacySalt & "");
		if(len(saltValue)){
			try {
				saltValue = decrypt(saltValue, getAuthKey(), "CFMX_COMPAT");
			} catch(any e) {
				// Some legacy rows may already contain plain salt.
			}
			return (hash(arguments.plainPassword & saltValue, "SHA-512") EQ hashValue);
		}
		return (hash(arguments.plainPassword, "SHA-512") EQ hashValue);
	}

	/**
	* @hint Verify PBKDF2 hash in constant time.
	*/
	private boolean function _verifyPbkdf2Password(required string plainPassword, required string storedHash) {
		var parts = listToArray(arguments.storedHash, "$");
		if(arrayLen(parts) LT 4){
			return false;
		}
		var iterations = val(parts[2]);
		if(iterations LTE 0){
			return false;
		}

		var saltBytes = binaryDecode(parts[3], "base64");
		var expectedBytes = binaryDecode(parts[4], "base64");
		var keyLengthBits = len(expectedBytes) * 8;
		if(keyLengthBits LTE 0){
			return false;
		}

		var keySpec = createObject("java", "javax.crypto.spec.PBEKeySpec").init(
			createObject("java", "java.lang.String").init(arguments.plainPassword & "").toCharArray(),
			saltBytes,
			iterations,
			keyLengthBits
		);
		var skf = createObject("java", "javax.crypto.SecretKeyFactory").getInstance("PBKDF2WithHmacSHA256");
		var computedBytes = skf.generateSecret(keySpec).getEncoded();
		return createObject("java", "java.security.MessageDigest").isEqual(expectedBytes, computedBytes);
	}

	/**
	* @hint Create PBKDF2 hash string.
	*/
	private string function _generateAdaptivePasswordHash(required string plainPassword) {
		var secureRandom = createObject("java", "java.security.SecureRandom");
		var saltBytes = secureRandom.generateSeed(16);
		var iterations = 210000;
		var keySpec = createObject("java", "javax.crypto.spec.PBEKeySpec").init(
			createObject("java", "java.lang.String").init(arguments.plainPassword & "").toCharArray(),
			saltBytes,
			iterations,
			256
		);
		var skf = createObject("java", "javax.crypto.SecretKeyFactory").getInstance("PBKDF2WithHmacSHA256");
		var derivedBytes = skf.generateSecret(keySpec).getEncoded();
		return "pbkdf2_sha256$#iterations#$#binaryEncode(saltBytes, 'base64')#$#binaryEncode(derivedBytes, 'base64')#";
	}
}
