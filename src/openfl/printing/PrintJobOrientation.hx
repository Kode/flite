package openfl.printing;

enum abstract PrintJobOrientation(Null<Int>) {
	public var LANDSCAPE = 0;
	public var PORTRAIT = 1;

	@:from private static function fromString(value:String):PrintJobOrientation {
		return switch (value) {
			case "landscape": LANDSCAPE;
			case "portrait": PORTRAIT;
			default: null;
		}
	}

	@:to function toString():String {
		return switch (cast this) {
			case PrintJobOrientation.LANDSCAPE: "landscape";
			case PrintJobOrientation.PORTRAIT: "portrait";
			default: null;
		}
	}
}
