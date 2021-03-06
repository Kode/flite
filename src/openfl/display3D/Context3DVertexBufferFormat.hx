package openfl.display3D;

enum abstract Context3DVertexBufferFormat(Null<Int>) {
	public var BYTES_4 = 0;
	public var FLOAT_1 = 1;
	public var FLOAT_2 = 2;
	public var FLOAT_3 = 3;
	public var FLOAT_4 = 4;

	@:from private static function fromString(value:String):Context3DVertexBufferFormat {
		return switch (value) {
			case "bytes4": BYTES_4;
			case "float1": FLOAT_1;
			case "float2": FLOAT_2;
			case "float3": FLOAT_3;
			case "float4": FLOAT_4;
			default: null;
		}
	}

	@:to function toString():String {
		return switch (cast this) {
			case Context3DVertexBufferFormat.BYTES_4: "bytes4";
			case Context3DVertexBufferFormat.FLOAT_1: "float1";
			case Context3DVertexBufferFormat.FLOAT_2: "float2";
			case Context3DVertexBufferFormat.FLOAT_3: "float3";
			case Context3DVertexBufferFormat.FLOAT_4: "float4";
			default: null;
		}
	}
}
