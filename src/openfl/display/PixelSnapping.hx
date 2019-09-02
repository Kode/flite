package openfl.display;

enum abstract PixelSnapping(Null<Int>) {
	public var ALWAYS = 0;
	public var AUTO = 1;
	public var NEVER = 2;

	@:from private static function fromString(value:String):PixelSnapping {
		return switch (value) {
			case "always": ALWAYS;
			case "auto": AUTO;
			case "never": NEVER;
			default: null;
		}
	}

	@:to function toString():String {
		return switch (cast this) {
			case PixelSnapping.ALWAYS: "always";
			case PixelSnapping.AUTO: "auto";
			case PixelSnapping.NEVER: "never";
			default: null;
		}
	}
}
