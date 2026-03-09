component extends="Wheels" {
	/**
	 * @hint Recommended PBKDF2 iteration count.
	 */
	public numeric function passwordHashIterations() {
		return 210000;
	}

	// Auth helpers for model-level usage during Wheels 3 migration
	public string function getAuthKey() {
		var authkeyLocation = expandPath("config/auth.cfm");
		var authkeyDefault = createUUID();
		if (fileExists(authkeyLocation)) {
			return fileRead(authkeyLocation);
		}
		fileWrite(authkeyLocation, authkeyDefault);
		return authkeyDefault;
	}

	public string function _generateApiKey(){
		var sr = createObject("java", "java.security.SecureRandom");
		return lCase(binaryEncode(sr.generateSeed(32), "hex"));
	}

	public string function createSalt() {
		return encrypt(createUUID(), getAuthKey(), 'CFMX_COMPAT');
	}

	public string function decryptSalt(required string salt) {
		return decrypt(arguments.salt, getAuthKey(), 'CFMX_COMPAT');
	}

	public string function hashPassword(required string password, required string salt) {
		if(!len(trim(arguments.salt & ""))){
			return hash(arguments.password, 'SHA-512');
		}
		return hash(arguments.password & arguments.salt, 'SHA-512');
	}

	/**
	 * @hint Create a PBKDF2 password hash string.
	 */
	public string function generatePasswordHash(required string password) {
		var iterations = passwordHashIterations();
		var secureRandom = createObject("java", "java.security.SecureRandom");
		var saltBytes = secureRandom.generateSeed(16);
		var keySpec = createObject("java", "javax.crypto.spec.PBEKeySpec").init(
			createObject("java", "java.lang.String").init(arguments.password & "").toCharArray(),
			saltBytes,
			iterations,
			256
		);
		var skf = createObject("java", "javax.crypto.SecretKeyFactory").getInstance("PBKDF2WithHmacSHA256");
		var derivedBytes = skf.generateSecret(keySpec).getEncoded();
		return "pbkdf2_sha256$#iterations#$#binaryEncode(saltBytes, 'base64')#$#binaryEncode(derivedBytes, 'base64')#";
	}

	/**
	 * @hint Verify a plain password against stored hash (supports legacy SHA-512 rows).
	 */
	public boolean function verifyPasswordAgainstHash(
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
	 * @hint Return true when stored hash is legacy or below target work factor.
	 */
	public boolean function needsPasswordRehash(required string storedHash) {
		var hashValue = trim(arguments.storedHash & "");
		if(left(hashValue, 14) NEQ "pbkdf2_sha256$"){
			return true;
		}
		var parts = listToArray(hashValue, "$");
		if(arrayLen(parts) LT 4){
			return true;
		}
		return (val(parts[2]) LT passwordHashIterations());
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
}
