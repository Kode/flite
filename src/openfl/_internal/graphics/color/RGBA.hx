package openfl._internal.graphics.color;

import js.lib.Uint8Array;

@:allow(openfl._internal.graphics.color)
abstract RGBA(UInt) from Int to Int from UInt to UInt {
	public var a(get, set):Int;
	public var b(get, set):Int;
	public var g(get, set):Int;
	public var r(get, set):Int;

	public inline function new(rgba:Int = 0) {
		this = rgba;
	}

	public static inline function create(r:Int, g:Int, b:Int, a:Int):RGBA {
		var rgba = new RGBA();
		rgba.set(r, g, b, a);
		return rgba;
	}

	public inline function readUInt8(data:Uint8Array, offset:Int):Void {
		set(data[offset], data[offset + 1], data[offset + 2], data[offset + 3]);
	}

	public inline function set(r:Int, g:Int, b:Int, a:Int):Void {
		this = ((r & 0xFF) << 24) | ((g & 0xFF) << 16) | ((b & 0xFF) << 8) | (a & 0xFF);
	}

	public inline function writeUInt8(data:Uint8Array, offset:Int):Void {
		data[offset] = r;
		data[offset + 1] = g;
		data[offset + 2] = b;
		data[offset + 3] = a;
	}

	@:from private static inline function __fromARGB(argb:ARGB):RGBA {
		return RGBA.create(argb.r, argb.g, argb.b, argb.a);
	}

	// Get & Set Methods

	private inline function get_a():Int {
		return this & 0xFF;
	}

	private inline function set_a(value:Int):Int {
		set(r, g, b, value);
		return value;
	}

	private inline function get_b():Int {
		return (this >> 8) & 0xFF;
	}

	private inline function set_b(value:Int):Int {
		set(r, g, value, a);
		return value;
	}

	private inline function get_g():Int {
		return (this >> 16) & 0xFF;
	}

	private inline function set_g(value:Int):Int {
		set(r, value, b, a);
		return value;
	}

	private inline function get_r():Int {
		return (this >> 24) & 0xFF;
	}

	private inline function set_r(value:Int):Int {
		set(value, g, b, a);
		return value;
	}
}
