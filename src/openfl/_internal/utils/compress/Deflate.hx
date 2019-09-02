package openfl._internal.utils.compress;

import haxe.io.Bytes;

class Deflate {
	public static function compress(bytes:Bytes):Bytes {
		return Bytes.ofData(Pako.deflateRaw(bytes.getData()));
	}

	public static function decompress(bytes:Bytes):Bytes {
		return Bytes.ofData(Pako.inflateRaw(bytes.getData()));
	}
}
