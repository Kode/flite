package openfl;

import haxe.Constraints.Function;
import haxe.PosInfos;
import haxe.Timer;
import openfl._internal.utils.Log;
import openfl._internal.app.Application;
import openfl.display.Sprite;
import openfl.net.URLLoader;
import openfl.net.URLRequest;
import js.Browser;

@:access(openfl.display.Stage) class Lib {
	public static var application(get, never):Application;
	public static var current(default, null):Sprite;
	private static var __lastTimerID:UInt = 0;
	private static var __sentWarnings = new Map<String, Bool>();
	private static var __timers = new Map<UInt, Timer>();

	public static function as<T>(v:Dynamic, c:Class<T>):Null<T> {
		return Std.is(v, c) ? v : null;
	}

	public static function clearInterval(id:UInt):Void {
		if (__timers.exists(id)) {
			var timer = __timers[id];
			timer.stop();
			__timers.remove(id);
		}
	}

	public static function clearTimeout(id:UInt):Void {
		if (__timers.exists(id)) {
			var timer = __timers[id];
			timer.stop();
			__timers.remove(id);
		}
	}

	public static function getDefinitionByName(name:String):Class<Dynamic> {
		return Type.resolveClass(name);
	}

	public static function getQualifiedClassName(value:Dynamic):String {
		return Type.getClassName(Type.getClass(value));
	}

	public static function getQualifiedSuperclassName(value:Dynamic):String {
		var ref = Type.getSuperClass(Type.getClass(value));
		return (ref != null ? Type.getClassName(ref) : null);
	}

	public static function getTimer():Int {
		return Std.int(Browser.window.performance.now());
	}

	public static function getURL(request:URLRequest, target:String = null):Void {
		navigateToURL(request, target);
	}

	public static function navigateToURL(request:URLRequest, window:String = "_blank"):Void {
		var uri = request.url;

		if (Type.typeof(request.data) == TObject) {
			var query = "";
			var fields = Reflect.fields(request.data);

			for (field in fields) {
				if (query.length > 0)
					query += "&";
				query += StringTools.urlEncode(field) + "=" + StringTools.urlEncode(Std.string(Reflect.field(request.data, field)));
			}

			if (uri.indexOf("?") > -1) {
				uri += "&" + query;
			} else {
				uri += "?" + query;
			}
		}

		Browser.window.open(uri, window);
	}

	public static function notImplemented(?posInfo:PosInfos):Void {
		var api = posInfo.className + "." + posInfo.methodName;

		if (!__sentWarnings.exists(api)) {
			__sentWarnings.set(api, true);

			Log.warn(posInfo.methodName + " is not implemented", posInfo);
		}
	}

	public static function sendToURL(request:URLRequest):Void {
		var urlLoader = new URLLoader();
		urlLoader.load(request);
	}

	public static function setInterval(closure:Function, delay:Int, args:Array<Dynamic>):UInt {
		var id = ++__lastTimerID;
		var timer = new Timer(delay);
		__timers[id] = timer;
		timer.run = function() {
			Reflect.callMethod(closure, closure, args);
		};
		return id;
	}

	public static function setTimeout(closure:Function, delay:Int, args:Array<Dynamic>):UInt {
		var id = ++__lastTimerID;
		__timers[id] = Timer.delay(function() {
			Reflect.callMethod(closure, closure, args);
		}, delay);
		return id;
	}

	public static function trace(arg:Dynamic):Void {
		haxe.Log.trace(arg);
	}

	static inline function get_application():Application {
		return Application.current;
	}
}
