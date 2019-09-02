package openfl._internal.graphics.color;

abstract ARGB(UInt) from Int to Int {
	public var a(get, set):Int;
	public var b(get, set):Int;
	public var g(get, set):Int;
	public var r(get, set):Int;

	public inline function set(a:Int, r:Int, g:Int, b:Int):Void {
		this = ((a & 0xFF) << 24) | ((r & 0xFF) << 16) | ((g & 0xFF) << 8) | (b & 0xFF);
	}

	@:from private static inline function __fromRGBA(rgba:RGBA):ARGB {
		var argb:ARGB = 0;
		argb.set(rgba.a, rgba.r, rgba.g, rgba.b);
		return argb;
	}

	// Get & Set Methods

	private inline function get_a():Int {
		return (this >> 24) & 0xFF;
	}

	private inline function set_a(value:Int):Int {
		set(value, r, g, b);
		return value;
	}

	private inline function get_b():Int {
		return this & 0xFF;
	}

	private inline function set_b(value:Int):Int {
		set(a, r, g, value);
		return value;
	}

	private inline function get_g():Int {
		return (this >> 8) & 0xFF;
	}

	private inline function set_g(value:Int):Int {
		set(a, r, value, b);
		return value;
	}

	private inline function get_r():Int {
		return (this >> 16) & 0xFF;
	}

	private inline function set_r(value:Int):Int {
		set(a, value, g, b);
		return value;
	}
}
