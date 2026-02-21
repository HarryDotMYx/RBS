//================= Room Booking System / https://github.com/neokoenig =======================--->
component extends="Model" hint="Resources Model"
{
	/**
	 * @hint Constructor
	 */
	private function config() {
		// Associations
		hasMany("eventresources");
	}

}