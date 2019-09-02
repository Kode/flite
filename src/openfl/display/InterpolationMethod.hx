package openfl.display;

enum abstract InterpolationMethod(Null<Int>) {
	public var LINEAR_RGB = 0;
	public var RGB = 1;

	@:from private static function fromString(value:String):InterpolationMethod {
		return switch (value) {
			case "linearRGB": LINEAR_RGB;
			case "rgb": RGB;
			default: null;
		}
	}

	@:to function toString():String {
		return switch (cast this) {
			case InterpolationMethod.LINEAR_RGB: "linearRGB";
			case InterpolationMethod.RGB: "rgb";
			default: null;
		}
	}
}
