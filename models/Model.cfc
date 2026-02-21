component extends="Wheels" {
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
		return hash(createUUID() & getAuthKey(), 'SHA-512');
	}

	public string function createSalt() {
		return encrypt(createUUID(), getAuthKey(), 'CFMX_COMPAT');
	}

	public string function decryptSalt(required string salt) {
		return decrypt(arguments.salt, getAuthKey(), 'CFMX_COMPAT');
	}

	public string function hashPassword(required string password, required string salt) {
		return hash(arguments.password & arguments.salt, 'SHA-512');
	}
}
