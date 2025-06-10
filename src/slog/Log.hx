package slog;

import haxe.PosInfos;

using StringTools;

class Log {
	public static var root(default, null) = new Logger("root", "log.txt");

	#if sys
	#if log
	static var loggers:Array<Logger> = [];
	#end

	public static function close() {
		#if log
		root.close();
		for (logger in loggers)
			logger.close();
		#end
	}
	#end

	extern public static inline function error(message:String) {
		root.error(message);
	}

	extern public static inline function debug(message:String) {
		root.debug(message);
	}

	extern public static inline function warning(message:String) {
		root.warning(message);
	}

	extern public static inline function info(message:String) {
		root.info(message);
	}

	extern public static inline function fatal(message:String) {
		root.fatal(message);
	}

	extern public static inline function trace(message:String, level:LogLevel = DEBUG, ?pos:PosInfo) {
		root.trace(message, level, pos);
	}

	extern public static inline function log(message:String, level:LogLevel = DEBUG) {
		root.log(message, level);
	}
}

@:access(slog.Log)
class Logger {
	extern static inline function logFormatted(value:String, ?values:{}) {
		#if js
		var styleMap = [
			"R" => "color: red;",
			"G" => "color: green;",
			"Y" => "color: goldenrod;",
			"O" => "color: orange;",
			"B" => "color: blue;",
			"W" => "font-weight: bold;"
		];

		inline function wrapStyle(flags:String, text:String):String {
			var styles = [
				for (i in 0...flags.length)
					if (styleMap.exists(flags.charAt(i))) styleMap.get(flags.charAt(i))
			];
			return '<span style="${styles.join("")}">$text</span>';
		}
		#elseif sys
		var ansiMap = [
			"R" => "\x1b[31m",
			"G" => "\x1b[32m",
			"Y" => "\x1b[38;5;226m",
			"O" => "\x1b[38;5;208m",
			"B" => "\x1b[34m",
			"W" => "\x1b[1m"
		];

		inline function wrapStyle(flags:String, text:String):String {
			var codes = [
				for (i in 0...flags.length)
					if (ansiMap.exists(flags.charAt(i))) ansiMap.get(flags.charAt(i))
			];
			return '${codes.join("")}$text\x1b[0m';
		}
		#end

		for (f in Reflect.fields(values))
			value = value.replace('{$f}', Std.string(Reflect.field(values, f)));

		var original = value;
		var regex = new EReg("%([RGBOYW]+)\\(([^\\)]*)\\)", "g");

		var formatted = regex.map(original, re -> {
			return wrapStyle(re.matched(1), re.matched(2));
		});

		var clear = regex.map(original, re -> re.matched(2));

		return {
			clear: clear,
			formatted: formatted
		}
	}

	public var name:String;

	public var level:LogLevel = DEBUG;
	public var format:String = "%B({datetime}) :{name}: {message}";

	#if sys
	var file:sys.io.FileOutput;
	var isClosed(get, never):Bool;

	public function new(name:String, ?file:String) {
		#if log
		this.name = name;
		if (file != null)
			open(file);
		Log.loggers?.push(this);
		#end
	}

	extern public inline function open(file:String) {
		#if log
		close();
		this.file = sys.io.File.write(file);
		#end
	}

	extern public inline function close() {
		#if log
		if (!isClosed) {
			file.close();
			file = null;
		}
		#end
	}
	#else
	public function new(name:String) {
		this.name = name;
	}
	#end

	extern public inline function debug(message:String) {
		log('%G($message)', DEBUG);
	}

	extern public inline function info(message:String) {
		log('%Y($message)', INFO);
	}

	extern public inline function warning(message:String) {
		log('%O($message)', WARNING);
	}

	extern public inline function error(message:String) {
		log('%R($message)', ERROR);
	}

	extern public inline function fatal(message:String) {
		log('%RW($message)', FATAL);
	}

	extern public inline function trace(message:String, level:LogLevel = DEBUG, ?pos:PosInfo) {
		log('$pos $message', level);
	}

	extern public inline function log(message:String, level:LogLevel = DEBUG) {
		#if log
		if (this.level <= level) {
			var output = logFormatted(format, {
				datetime: DateTools.format(Date.now(), "%H:%M:%S"),
				level: level.toString(),
				name: name,
				message: message
			});
			#if sys
			Sys.println(output.formatted);
			if (!isClosed)
				file.writeString('${output.clear}\n');
			#elseif js
			js.Lib.console.log(output.formatted);
			#end
		}
		#end
	}

	extern inline function get_isClosed() {
		return file == null;
	}
}

enum abstract LogLevel(Int) to Int {
	var DEBUG;
	var INFO;
	var WARNING;
	var ERROR;
	var FATAL;

	@:op(a == b)
	inline function eq(b:LogLevel) {
		return this == (b : Int);
	}

	@:op(a != b)
	inline function neq(b:LogLevel) {
		return this != (b : Int);
	}

	@:op(a < b)
	inline function lower(b:LogLevel) {
		return this < (b : Int);
	}

	@:op(a <= b)
	inline function lowerEq(b:LogLevel) {
		return this <= (b : Int);
	}

	@:op(a > b)
	inline function greater(b:LogLevel) {
		return this > (b : Int);
	}

	@:op(a >= b)
	inline function greaterEq(b:LogLevel) {
		return this >= (b : Int);
	}

	public inline function toString() {
		return switch this {
			case DEBUG: "DEBUG";
			case INFO: "INFO";
			case WARNING: "WARNING";
			case ERROR: "ERROR";
			case FATAL: "FATAL";
			default: Std.string(this);
		}
	}
}

@:forward()
private abstract PosInfo(PosInfos) from PosInfos {
	public function toString() {
		return '${this.fileName}:${this.lineNumber}';
	}
}
