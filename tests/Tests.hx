package tests;

import slog.Log;

class Tests {
	static function main() {
		Log.debug("a");
		Log.info("a");
		Log.warning("a");
		Log.error("a");
		Log.fatal("a");
		Log.close();
	}
}
