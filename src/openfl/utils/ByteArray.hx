package openfl.utils;

import haxe.io.Bytes;
import haxe.io.BytesData;
import haxe.io.FPHelper;
import openfl._internal.utils.compress.Deflate;
import openfl._internal.utils.compress.LZMA;
import openfl._internal.utils.compress.Zlib;
import openfl.errors.EOFError;

@:access(haxe.io.Bytes)
@:access(openfl.utils.ByteArrayData)
@:forward(bytesAvailable, endian, objectEncoding, position, clear, compress, deflate, inflate, readBoolean, readByte, readBytes, readDouble, readFloat,
	readInt, readMultiByte, readShort, readUnsignedByte, readUnsignedInt, readUnsignedShort, readUTF, readUTFBytes, toString, uncompress, writeBoolean,
	writeByte, writeBytes, writeDouble, writeFloat, writeInt, writeMultiByte, writeShort, writeUnsignedInt, writeUTF, writeUTFBytes)
abstract ByteArray(ByteArrayData) from ByteArrayData to ByteArrayData {
	public static var defaultObjectEncoding:UInt;

	public var length(get, set):Int;

	public inline function new(length:Int = 0):Void {
		this = new ByteArrayData(length);
	}

	@:arrayAccess inline function get(index:Int):Int {
		return this.get(index);
	}

	@:arrayAccess inline function set(index:Int, value:Int):Int {
		this.__resize(index + 1);
		this.set(index, value);
		return value;
	}

	@:from public static function fromBytes(bytes:Bytes):ByteArray {
		if (bytes == null)
			return null;

		if (Std.is(bytes, ByteArrayData)) {
			return cast bytes;
		} else {
			return ByteArrayData.fromBytes(bytes);
		}
	}

	@:from public static function fromBytesData(bytesData:BytesData):ByteArray {
		if (bytesData == null)
			return null;

		return ByteArrayData.fromBytes(Bytes.ofData(bytesData));
	}

	@:to inline function toBytes():Bytes {
		return this;
	}

	@:to inline function toBytesData():BytesData {
		return this.getData();
	}

	// Get & Set Methods

	inline function get_length():Int {
		return this.length;
	}

	function set_length(value:Int):Int {
		if (value > 0) {
			this.__resize(value);
			if (value < this.position)
				this.position = value;
		}

		this.length = value;

		return value;
	}
}

@:dox(hide) class ByteArrayData extends Bytes implements IDataInput implements IDataOutput {
	public var bytesAvailable(get, never):UInt;
	public var endian(get, set):Endian;
	public var objectEncoding:UInt;
	public var position:Int;

	var __endian:Endian;
	var __length:Int;

	public function new(length:Int = 0) {
		var bytes = Bytes.alloc(length);
		super(bytes.b.buffer);
		__length = length;
		endian = BIG_ENDIAN;
		position = 0;
	}

	public function clear():Void {
		length = 0;
		position = 0;
	}

	public function compress(algorithm:CompressionAlgorithm = ZLIB):Void {
		if (__length > length) {
			var cacheLength = length;
			this.length = __length;
			var data = Bytes.alloc(cacheLength);
			data.blit(0, this, 0, cacheLength);
			__setData(data);
			this.length = cacheLength;
		}

		var bytes = switch (algorithm) {
			case CompressionAlgorithm.DEFLATE: Deflate.compress(this);
			case CompressionAlgorithm.LZMA: LZMA.compress(this);
			default: Zlib.compress(this);
		}

		if (bytes != null) {
			__setData(bytes);

			length = __length;
			position = length;
		}
	}

	public function deflate():Void {
		compress(CompressionAlgorithm.DEFLATE);
	}

	public static function fromBytes(bytes:Bytes):ByteArrayData {
		var result = new ByteArrayData();
		result.__fromBytes(bytes);
		return result;
	}

	public function inflate() {
		uncompress(CompressionAlgorithm.DEFLATE);
	}

	public function readBoolean():Bool {
		if (position < length) {
			return (get(position++) != 0);
		} else {
			throw new EOFError();
		}
	}

	public function readByte():Int {
		var value = readUnsignedByte();

		if (value & 0x80 != 0) {
			return value - 0x100;
		} else {
			return value;
		}
	}

	public function readBytes(bytes:ByteArray, offset:Int = 0, length:Int = 0):Void {
		if (length == 0)
			length = this.length - position;

		if (position + length > this.length) {
			throw new EOFError();
		}

		if ((bytes : ByteArrayData).length < offset + length) {
			(bytes : ByteArrayData).__resize(offset + length);
		}

			(bytes : ByteArrayData).blit(offset, this, position, length);
		position += length;
	}

	public function readDouble():Float {
		var ch1 = readInt();
		var ch2 = readInt();

		if (endian == LITTLE_ENDIAN) {
			return FPHelper.i64ToDouble(ch1, ch2);
		} else {
			return FPHelper.i64ToDouble(ch2, ch1);
		}
	}

	public function readFloat():Float {
		return FPHelper.i32ToFloat(readInt());
	}

	public function readInt():Int {
		var ch1 = readUnsignedByte();
		var ch2 = readUnsignedByte();
		var ch3 = readUnsignedByte();
		var ch4 = readUnsignedByte();

		if (endian == LITTLE_ENDIAN) {
			return (ch4 << 24) | (ch3 << 16) | (ch2 << 8) | ch1;
		} else {
			return (ch1 << 24) | (ch2 << 16) | (ch3 << 8) | ch4;
		}
	}

	public function readMultiByte(length:Int, charSet:String):String {
		return readUTFBytes(length);
	}

	public function readShort():Int {
		var ch1 = readUnsignedByte();
		var ch2 = readUnsignedByte();

		var value;

		if (endian == LITTLE_ENDIAN) {
			value = ((ch2 << 8) | ch1);
		} else {
			value = ((ch1 << 8) | ch2);
		}

		if ((value & 0x8000) != 0) {
			return value - 0x10000;
		} else {
			return value;
		}
	}

	public function readUnsignedByte():Int {
		if (position < length) {
			return get(position++);
		} else {
			throw new EOFError();
		}
	}

	public function readUnsignedInt():Int {
		var ch1 = readUnsignedByte();
		var ch2 = readUnsignedByte();
		var ch3 = readUnsignedByte();
		var ch4 = readUnsignedByte();

		if (endian == LITTLE_ENDIAN) {
			return (ch4 << 24) | (ch3 << 16) | (ch2 << 8) | ch1;
		} else {
			return (ch1 << 24) | (ch2 << 16) | (ch3 << 8) | ch4;
		}
	}

	public function readUnsignedShort():Int {
		var ch1 = readUnsignedByte();
		var ch2 = readUnsignedByte();

		if (endian == LITTLE_ENDIAN) {
			return (ch2 << 8) + ch1;
		} else {
			return (ch1 << 8) | ch2;
		}
	}

	public function readUTF():String {
		var bytesCount = readUnsignedShort();
		return readUTFBytes(bytesCount);
	}

	public function readUTFBytes(length:Int):String {
		if (position + length > this.length) {
			throw new EOFError();
		}

		position += length;

		return getString(position - length, length);
	}

	public function uncompress(algorithm:CompressionAlgorithm = ZLIB):Void {
		if (__length > length) {
			var cacheLength = length;
			this.length = __length;
			var data = Bytes.alloc(cacheLength);
			data.blit(0, this, 0, cacheLength);
			__setData(data);
			this.length = cacheLength;
		}

		var bytes = switch (algorithm) {
			case CompressionAlgorithm.DEFLATE: Deflate.decompress(this);
			case CompressionAlgorithm.LZMA: LZMA.decompress(this);
			default: Zlib.decompress(this);
		};

		if (bytes != null) {
			__setData(bytes);
			length = __length;
		}

		position = 0;
	}

	public function writeBoolean(value:Bool):Void {
		this.writeByte(value ? 1 : 0);
	}

	public function writeByte(value:Int):Void {
		__resize(position + 1);
		set(position++, value & 0xFF);
	}

	public function writeBytes(bytes:ByteArray, offset:UInt = 0, length:UInt = 0):Void {
		if (bytes.length == 0)
			return;
		if (length == 0)
			length = bytes.length - offset;

		__resize(position + length);
		blit(position, (bytes : ByteArrayData), offset, length);

		position += length;
	}

	public function writeDouble(value:Float):Void {
		var int64 = FPHelper.doubleToI64(value);

		if (endian == LITTLE_ENDIAN) {
			writeInt(int64.low);
			writeInt(int64.high);
		} else {
			writeInt(int64.high);
			writeInt(int64.low);
		}
	}

	public function writeFloat(value:Float):Void {
		if (endian == LITTLE_ENDIAN) {
			__resize(position + 4);
			setFloat(position, value);
			position += 4;
		} else {
			var int = FPHelper.floatToI32(value);
			writeInt(int);
		}
	}

	public function writeInt(value:Int):Void {
		__resize(position + 4);

		if (endian == LITTLE_ENDIAN) {
			set(position++, value & 0xFF);
			set(position++, (value >> 8) & 0xFF);
			set(position++, (value >> 16) & 0xFF);
			set(position++, (value >> 24) & 0xFF);
		} else {
			set(position++, (value >> 24) & 0xFF);
			set(position++, (value >> 16) & 0xFF);
			set(position++, (value >> 8) & 0xFF);
			set(position++, value & 0xFF);
		}
	}

	public function writeMultiByte(value:String, charSet:String):Void {
		writeUTFBytes(value);
	}

	public function writeShort(value:Int):Void {
		__resize(position + 2);

		if (endian == LITTLE_ENDIAN) {
			set(position++, value);
			set(position++, value >> 8);
		} else {
			set(position++, value >> 8);
			set(position++, value);
		}
	}

	public function writeUnsignedInt(value:Int):Void {
		writeInt(value);
	}

	public function writeUTF(value:String):Void {
		var bytes = Bytes.ofString(value);

		writeShort(bytes.length);
		writeBytes(bytes);
	}

	public function writeUTFBytes(value:String):Void {
		writeBytes(Bytes.ofString(value));
	}

	private function __fromBytes(bytes:Bytes):Void {
		__setData(bytes);
		length = bytes.length;
	}

	private function __resize(size:Int) {
		if (size > __length) {
			var bytes = Bytes.alloc(((size + 1) * 3) >> 1);

			if (__length > 0) {
				var cacheLength = length;
				length = __length;
				bytes.blit(0, this, 0, __length);
				length = cacheLength;
			}

			__setData(bytes);
		}

		if (length < size) {
			length = size;
		}
	}

	inline function __setData(bytes:Bytes) {
		b = bytes.b;
		__length = bytes.length;
		data = bytes.data;
	}

	inline function get_bytesAvailable():Int {
		return length - position;
	}

	inline function get_endian():Endian {
		return __endian;
	}

	inline function set_endian(value:Endian):Endian {
		return __endian = value;
	}
}
