package openfl.display;

enum abstract StageScaleMode(Null<Int>) {
	public var EXACT_FIT = 0;
	public var NO_BORDER = 1;
	public var NO_SCALE = 2;
	public var SHOW_ALL = 3;

	@:from private static function fromString(value:String):StageScaleMode {
		return switch (value) {
			case "exactFit": EXACT_FIT;
			case "noBorder": NO_BORDER;
			case "noScale": NO_SCALE;
			case "showAll": SHOW_ALL;
			default: null;
		}
	}

	@:to function toString():String {
		return switch (cast this) {
			case StageScaleMode.EXACT_FIT: "exactFit";
			case StageScaleMode.NO_BORDER: "noBorder";
			case StageScaleMode.NO_SCALE: "noScale";
			case StageScaleMode.SHOW_ALL: "showAll";
			default: null;
		}
	}
}
