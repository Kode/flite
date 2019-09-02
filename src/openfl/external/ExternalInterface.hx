package openfl.external;

import haxe.DynamicAccess;
import haxe.Constraints.Function;

final class ExternalInterface {
	public static inline final available = true;
	public static var marshallExceptions = false;
	public static var objectID(default, null):String;

	public static function addCallback(functionName:String, closure:Function):Void {
		(cast kha.SystemImpl.khanvas : DynamicAccess<Function>)[functionName] = closure;
	}

	public static function call(functionName:String, ?p1:Dynamic, ?p2:Dynamic, ?p3:Dynamic, ?p4:Dynamic, ?p5:Dynamic):Dynamic {
		if (!~/^\(.+\)$/.match(functionName)) {
			var thisArg = functionName.split('.').slice(0, -1).join('.');
			if (thisArg.length > 0) {
				functionName += '.bind(${thisArg})';
			}
		}

		// Flash does not throw an error or attempt to execute
		// if the function does not exist.
		var fn:Function = try js.Lib.eval(functionName) catch (e:Any) return null;
		if (!Reflect.isFunction(fn)) return null;

		return
			if (p1 == null) fn()
			else if (p2 == null) fn(p1)
			else if (p3 == null) fn(p1, p2)
			else if (p4 == null) fn(p1, p2, p3)
			else if (p5 == null) fn(p1, p2, p3, p4)
			else fn(p1, p2, p3, p4, p5);
	}
}
