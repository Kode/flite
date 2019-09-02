package openfl._internal.utils.compress;

import haxe.io.Bytes;

class GZip {
	public static function compress(bytes:Bytes):Bytes {
		return Bytes.ofData(Pako.gzip(bytes.getData()));
	}

	public static function decompress(bytes:Bytes):Bytes {
		return Bytes.ofData(Pako.ungzip(bytes.getData()));
	}
}
