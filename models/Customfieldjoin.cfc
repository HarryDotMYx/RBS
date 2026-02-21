component extends="Model" hint=""
{
	/**
	 * @hint Constructor
	 */
	private function config() {
		// Associations
		belongsTo(name="customfield", joinType="left");
		belongsTo(name="customfieldvalue", joinType="left");
	}

}