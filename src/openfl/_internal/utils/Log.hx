package openfl._internal.utils;

import haxe.PosInfos;

class Log {
	public static var level:LogLevel = #if no_traces NONE #elseif verbose VERBOSE #elseif debug DEBUG #else INFO #end;
	public static var throwErrors = true;

	public static function debug(message:String, ?info:PosInfos):Void {
		if (level >= LogLevel.DEBUG) {
			js.Browser.console.debug("[" + info.className + "] " + message);
		}
	}

	public static function error(message:String, ?info:PosInfos):Void {
		if (level >= LogLevel.ERROR) {
			var message = "[" + info.className + "] ERROR: " + message;
			if (throwErrors) {
				throw message;
			} else {
				js.Browser.console.error(message);
			}
		}
	}

	public static function info(message:String, ?info:PosInfos):Void {
		if (level >= LogLevel.INFO) {
			js.Browser.console.info("[" + info.className + "] " + message);
		}
	}

	public static inline function print(message:String):Void {
		js.Browser.console.log(message);
	}

	public static inline function println(message:String):Void {
		js.Browser.console.log(message);
	}

	public static function verbose(message:String, ?info:PosInfos):Void {
		if (level >= LogLevel.VERBOSE) {
			println("[" + info.className + "] " + message);
		}
	}

	public static function warn(message:String, ?info:PosInfos):Void {
		if (level >= LogLevel.WARN) {
			js.Browser.console.warn("[" + info.className + "] WARNING: " + message);
		}
	}
}

enum abstract LogLevel(Int) {
	var NONE;
	var ERROR;
	var WARN;
	var INFO;
	var DEBUG;
	var VERBOSE;

	@:op(A > B) static function gt(a:LogLevel, b:LogLevel):Bool;
	@:op(A >= B) static function gte(a:LogLevel, b:LogLevel):Bool;
	@:op(A < B) static function lt(a:LogLevel, b:LogLevel):Bool;
	@:op(A <= B) static function lte(a:LogLevel, b:LogLevel):Bool;
}
