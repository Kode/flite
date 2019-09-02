package openfl._internal.utils.compress;

import haxe.io.Bytes;

class Zlib {
	public static function compress(bytes:Bytes):Bytes {
		return Bytes.ofData(Pako.deflate(bytes.getData()));
	}

	public static function decompress(bytes:Bytes):Bytes {
		return Bytes.ofData(Pako.inflate(bytes.getData()));
	}
}
