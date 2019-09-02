package openfl.display3D;

enum abstract Context3DProgramType(Null<Int>) {
	public var FRAGMENT = 0;
	public var VERTEX = 1;

	@:from private static function fromString(value:String):Context3DProgramType {
		return switch (value) {
			case "fragment": FRAGMENT;
			case "vertex": VERTEX;
			default: null;
		}
	}

	@:to function toString():String {
		return switch (cast this) {
			case Context3DProgramType.FRAGMENT: "fragment";
			case Context3DProgramType.VERTEX: "vertex";
			default: null;
		}
	}
}
