package openfl._internal.system;

import openfl._internal.app.Application;

class Clipboard {
	public static var text(default,null):String;

	public static function setText(value:String, syncSystemClipboard:Bool) {
		text = value;
		if (syncSystemClipboard) {
			Application.current.window.setClipboard(value);
		}
	}
}
