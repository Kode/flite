package openfl.system;

import openfl.desktop.Clipboard;

@:final class System {
	public static var totalMemory(get, never):Int;
	public static var useCodePage:Bool = false;
	public static var vmVersion(get, never):String;

	public static function exit(code:Int):Void {
		// not implemented for HTML5
	}

	public static function gc():Void {}

	public static function pause():Void {
		openfl.Lib.notImplemented();
	}

	public static function resume():Void {
		openfl.Lib.notImplemented();
	}

	public static function setClipboard(string:String):Void {
		Clipboard.generalClipboard.setData(TEXT_FORMAT, string);
	}

	public static inline function disposeXML(node:Dynamic) {}

	// Getters & Setters

	private static function get_totalMemory():Int {
		return untyped __js__("(window.performance && window.performance.memory) ? window.performance.memory.usedJSHeapSize : 0");
	}

	private static function get_vmVersion():String {
		return "1.0.0";
	}
}
