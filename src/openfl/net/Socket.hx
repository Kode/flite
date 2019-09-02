package openfl.net;

import haxe.io.Bytes;
import haxe.Timer;
import openfl.errors.IOError;
import openfl.errors.SecurityError;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.IOErrorEvent;
import openfl.events.ProgressEvent;
import openfl.utils.ByteArray;
import openfl.utils.Endian;
import openfl.utils.IDataInput;
import openfl.utils.IDataOutput;
import js.html.WebSocket;
import js.lib.ArrayBuffer;
import js.Browser;

class Socket extends EventDispatcher implements IDataInput implements IDataOutput {
	public var bytesAvailable(get, never):Int;
	public var bytesPending(get, never):Int;
	public var connected(get, never):Bool;
	public var objectEncoding:UInt;
	public var secure:Bool;
	public var timeout:Int;
	public var endian(get, set):Endian;

	private var __buffer:Bytes;
	private var __connected:Bool;
	private var __endian:Endian;
	private var __host:String;
	private var __input:ByteArray;
	private var __inputBuffer:ByteArray;
	private var __output:ByteArray;
	private var __port:Int;
	private var __socket:WebSocket;
	private var __timestamp:Float;

	public function new(host:String = null, port:Int = 0) {
		super();

		endian = Endian.BIG_ENDIAN;
		timeout = 20000;

		__buffer = Bytes.alloc(4096);

		if (port > 0 && port < 65535) {
			connect(host, port);
		}
	}

	public function connect(host:String = null, port:Int = 0):Void {
		if (__socket != null) {
			close();
		}

		if (port < 0 || port > 65535) {
			throw new SecurityError("Invalid socket port number specified.");
		}

		__timestamp = Timer.stamp();

		__host = host;
		__port = port;

		__output = new ByteArray();
		__output.endian = __endian;

		__input = new ByteArray();
		__input.endian = __endian;

		__inputBuffer = new ByteArray();
		__inputBuffer.endian = __endian;

		if (Browser.location.protocol == "https:") {
			secure = true;
		}

		var schema = secure ? "wss" : "ws";
		var urlReg = ~/^(.*:\/\/)?([A-Za-z0-9\-\.]+)\/?(.*)/g;
		urlReg.match(host);
		var __webHost = urlReg.matched(2);
		var __webPath = urlReg.matched(3);

		__socket = new WebSocket(schema + "://" + __webHost + ":" + port + "/" + __webPath);
		__socket.binaryType = ARRAYBUFFER;
		__socket.onopen = socket_onOpen;
		__socket.onmessage = socket_onMessage;
		__socket.onclose = socket_onClose;
		__socket.onerror = socket_onError;

		Lib.current.addEventListener(Event.ENTER_FRAME, this_onEnterFrame);
	}

	public function close():Void {
		if (__socket != null) {
			__cleanSocket();
		} else {
			throw new IOError("Operation attempted on invalid socket.");
		}
	}

	public function flush():Void {
		if (__socket == null) {
			throw new IOError("Operation attempted on invalid socket.");
		}

		if (__output.length > 0) {
			try {
				var buffer:ArrayBuffer = __output;
				if (buffer.byteLength > __output.length)
					buffer = buffer.slice(0, __output.length);
				__socket.send(buffer);
				__output = new ByteArray();
				__output.endian = __endian;
			} catch (e:Dynamic) {
				throw new IOError("Operation attempted on invalid socket.");
			}
		}
	}

	public function readBoolean():Bool {
		if (__socket == null) {
			throw new IOError("Operation attempted on invalid socket.");
		}

		return __input.readBoolean();
	}

	public function readByte():Int {
		if (__socket == null) {
			throw new IOError("Operation attempted on invalid socket.");
		}

		return __input.readByte();
	}

	public function readBytes(bytes:ByteArray, offset:Int = 0, length:Int = 0):Void {
		if (__socket == null) {
			throw new IOError("Operation attempted on invalid socket.");
		}

		__input.readBytes(bytes, offset, length);
	}

	public function readDouble():Float {
		if (__socket == null) {
			throw new IOError("Operation attempted on invalid socket.");
		}

		return __input.readDouble();
	}

	public function readFloat():Float {
		if (__socket == null) {
			throw new IOError("Operation attempted on invalid socket.");
		}

		return __input.readFloat();
	}

	public function readInt():Int {
		if (__socket == null) {
			throw new IOError("Operation attempted on invalid socket.");
		}

		return __input.readInt();
	}

	public function readMultiByte(length:Int, charSet:String):String {
		if (__socket == null) {
			throw new IOError("Operation attempted on invalid socket.");
		}

		return __input.readMultiByte(length, charSet);
	}

	public function readShort():Int {
		if (__socket == null) {
			throw new IOError("Operation attempted on invalid socket.");
		}

		return __input.readShort();
	}

	public function readUnsignedByte():Int {
		if (__socket == null) {
			throw new IOError("Operation attempted on invalid socket.");
		}
		return __input.readUnsignedByte();
	}

	public function readUnsignedInt():Int {
		if (__socket == null) {
			throw new IOError("Operation attempted on invalid socket.");
		}

		return __input.readUnsignedInt();
	}

	public function readUnsignedShort():Int {
		if (__socket == null) {
			throw new IOError("Operation attempted on invalid socket.");
		}

		return __input.readUnsignedShort();
	}

	public function readUTF():String {
		if (__socket == null) {
			throw new IOError("Operation attempted on invalid socket.");
		}

		return __input.readUTF();
	}

	public function readUTFBytes(length:Int):String {
		if (__socket == null) {
			throw new IOError("Operation attempted on invalid socket.");
		}

		return __input.readUTFBytes(length);
	}

	public function writeBoolean(value:Bool):Void {
		if (__socket == null) {
			throw new IOError("Operation attempted on invalid socket.");
		}

		__output.writeBoolean(value);
	}

	public function writeByte(value:Int):Void {
		if (__socket == null) {
			throw new IOError("Operation attempted on invalid socket.");
		}

		__output.writeByte(value);
	}

	public function writeBytes(bytes:ByteArray, offset:Int = 0, length:Int = 0):Void {
		if (__socket == null) {
			throw new IOError("Operation attempted on invalid socket.");
		}

		__output.writeBytes(bytes, offset, length);
	}

	public function writeDouble(value:Float):Void {
		if (__socket == null) {
			throw new IOError("Operation attempted on invalid socket.");
		}

		__output.writeDouble(value);
	}

	public function writeFloat(value:Float):Void {
		if (__socket == null) {
			throw new IOError("Operation attempted on invalid socket.");
		}

		__output.writeFloat(value);
	}

	public function writeInt(value:Int):Void {
		if (__socket == null) {
			throw new IOError("Operation attempted on invalid socket.");
		}

		__output.writeInt(value);
	}

	public function writeMultiByte(value:String, charSet:String):Void {
		if (__socket == null) {
			throw new IOError("Operation attempted on invalid socket.");
		}

		__output.writeUTFBytes(value);
	}

	// public function writeObject (object:Dynamic):Void {
	//
	// __output.writeObject (object);
	//
	// }

	public function writeShort(value:Int):Void {
		if (__socket == null) {
			throw new IOError("Operation attempted on invalid socket.");
		}

		__output.writeShort(value);
	}

	public function writeUnsignedInt(value:Int):Void {
		if (__socket == null) {
			throw new IOError("Operation attempted on invalid socket.");
		}

		__output.writeUnsignedInt(value);
	}

	public function writeUTF(value:String):Void {
		if (__socket == null) {
			throw new IOError("Operation attempted on invalid socket.");
		}

		__output.writeUTF(value);
	}

	public function writeUTFBytes(value:String):Void {
		if (__socket == null) {
			throw new IOError("Operation attempted on invalid socket.");
		}

		__output.writeUTFBytes(value);
	}

	private function __cleanSocket():Void {
		try {
			__socket.close();
		} catch (e:Dynamic) {}

		__socket = null;
		__connected = false;
		Lib.current.removeEventListener(Event.ENTER_FRAME, this_onEnterFrame);
	}

	// Event Handlers

	private function socket_onClose(_):Void {
		dispatchEvent(new Event(Event.CLOSE));
	}

	private function socket_onError(e):Void {
		dispatchEvent(new Event(IOErrorEvent.IO_ERROR));
	}

	private function socket_onMessage(msg:Dynamic):Void {
		if (Std.is(msg.data, String)) {
			__inputBuffer.position = __inputBuffer.length;
			var cachePosition = __inputBuffer.position;
			__inputBuffer.writeUTFBytes(msg.data);
			__inputBuffer.position = cachePosition;
		} else {
			var newData:ByteArray = (msg.data : ArrayBuffer);
			newData.readBytes(__inputBuffer, __inputBuffer.length);
		}

		if (__inputBuffer.bytesAvailable > 0) {
			var newInput = new ByteArray();
			var newDataLength = __inputBuffer.bytesAvailable;

			__input.readBytes(newInput, 0, __input.bytesAvailable);
			__inputBuffer.position = 0;
			__inputBuffer.readBytes(newInput, newInput.position, __inputBuffer.length);

			newInput.position = 0;

			__input = newInput;
			__input.endian = __endian;
			__inputBuffer.clear();

			dispatchEvent(new ProgressEvent(ProgressEvent.SOCKET_DATA, false, false, newDataLength, 0));
		}
	}

	private function socket_onOpen(_):Void {
		__connected = true;
		dispatchEvent(new Event(Event.CONNECT));
	}

	private function this_onEnterFrame(event:Event):Void {
		if (__socket != null) {
			flush();
		}
	}

	// Get & Set Methods

	private function get_bytesAvailable():Int {
		return __input.bytesAvailable;
	}

	private function get_bytesPending():Int {
		return __output.length;
	}

	private function get_connected():Bool {
		return __connected;
	}

	private function get_endian():Endian {
		return __endian;
	}

	private function set_endian(value:Endian):Endian {
		__endian = value;

		if (__input != null)
			__input.endian = value;
		if (__inputBuffer != null)
			__inputBuffer.endian = value;
		if (__output != null)
			__output.endian = value;

		return __endian;
	}
}
