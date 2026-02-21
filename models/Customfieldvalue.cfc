component extends="Model" hint=""
{
	/**
	 * @hint Constructor
	 */
	private function config() {
		// Associations
		hasMany(name="customfieldjoins");
	}

}