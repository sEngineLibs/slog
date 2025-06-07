package slog;

import haxe.PosInfos;

class Log {
	public static inline final INFO:Int = 1;
	public static inline final DEBUG:Int = 2;
	public static inline final ERROR:Int = 4;
	public static inline final WARNING:Int = 8;
	public static inline final ALL:Int = INFO | DEBUG | ERROR | WARNING;
	#if js
	public static inline final Red = "color: red;";
	public static inline final Green = "color: green;";
	public static inline final Yellow = "color: yellow;";
	public static inline final Blue = "color: blue;";
	#elseif sys
	public static inline final Red = "\x1b[31m";
	public static inline final Green = "\x1b[32m";
	public static inline final Yellow = "\x1b[33m";
	public static inline final Blue = "\x1b[34m";
	public static inline final Reset = "\x1b[0m";
	#end

	public static var level:Int = ALL;
	public static var stamp:Bool = false;

	public static function error(msg:String) {
		log(msg, Red, ERROR);
	}

	public static function debug(msg:String) {
		log(msg, Green, DEBUG);
	}

	public static function warning(msg:String) {
		log(msg, Yellow, WARNING);
	}

	public static function info(msg:String) {
		log(msg, Blue, INFO);
	}

	public static function fatal(msg:String) {
		log(msg, Red, Log.level);
	}

	public static function trace(msg:String, color:String, level:Int = 0, ?pos:PosInfo) {
		log('$pos $msg', color, level);
	}

	public static function log(data:String, color:String, level:Int = 0) {
		if (Log.level & level != 0) {
			var msg = stamp ? '[${DateTools.format(Date.now(), "%H:%M:%S")}]' : "";
			#if js
			js.Lib.global.console.log('$msg %c$data', color);
			#elseif sys
			Sys.println('$msg $color$data${Reset}');
			#end
		}
	}
}

@:forward()
private abstract PosInfo(PosInfos) from PosInfos {
	public function toString() {
		return '${this.fileName}:${this.lineNumber}';
	}
}
