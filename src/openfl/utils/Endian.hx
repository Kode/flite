package openfl.utils;

enum abstract Endian(Null<Int>) {
	var BIG_ENDIAN = 0;
	var LITTLE_ENDIAN = 1;

	@:from static function fromString(value:String):Endian {
		return switch (value) {
			case "bigEndian": BIG_ENDIAN;
			case "littleEndian": LITTLE_ENDIAN;
			default: null;
		}
	}

	@:to function toString():String {
		return switch (cast this) {
			case Endian.BIG_ENDIAN: "bigEndian";
			case Endian.LITTLE_ENDIAN: "littleEndian";
			default: null;
		}
	}
}
