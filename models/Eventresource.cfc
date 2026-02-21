//================= Room Booking System / https://github.com/neokoenig =======================--->
component extends="Model" hint="Event Resource Model"
{
	/**
	 * @hint Constructor
	 */
	private function config() {
		// Associations
		belongsTo("event");
		belongsTo("resource");
	}

}