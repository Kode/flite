package openfl._internal.sound;

import haxe.crypto.Base64;
import haxe.io.Bytes;
import haxe.io.UInt8Array;
import openfl._internal.app.Future;
import openfl._internal.app.Promise;
import openfl._internal.utils.Log;

class AudioBuffer {
	public var bitsPerSample:Int;
	public var channels:Int;
	public var data:UInt8Array;
	public var sampleRate:Int;
	public var src:Howl;

	public function new() {}

	public function dispose():Void {
		src.unload();
	}

	public static function fromBase64(base64String:String):AudioBuffer {
		if (base64String == null)
			return null;

		// if base64String doesn't contain codec data, add it.
		if (base64String.indexOf(",") == -1) {
			base64String = "data:" + __getCodec(Base64.decode(base64String)) + ";base64," + base64String;
		}

		var audioBuffer = new AudioBuffer();
		audioBuffer.src = new Howl({src: [base64String], html5: true, preload: false});
		return audioBuffer;
	}

	public static function fromBytes(bytes:Bytes):AudioBuffer {
		if (bytes == null)
			return null;

		var audioBuffer = new AudioBuffer();
		audioBuffer.src = new Howl({src: ["data:" + __getCodec(bytes) + ";base64," + Base64.encode(bytes)], html5: true, preload: false});

		return audioBuffer;
	}

	public static function fromFile(path:String):AudioBuffer {
		if (path == null)
			return null;

		var audioBuffer = new AudioBuffer();
		audioBuffer.src = new Howl({src: [path], preload: false});
		return audioBuffer;
	}

	public static function fromFiles(paths:Array<String>):AudioBuffer {
		var audioBuffer = new AudioBuffer();
		audioBuffer.src = new Howl({src: paths, preload: false});
		return audioBuffer;
	}

	public static function loadFromFile(path:String):Future<AudioBuffer> {
		var promise = new Promise<AudioBuffer>();

		var audioBuffer = AudioBuffer.fromFile(path);

		if (audioBuffer != null) {
			audioBuffer.src.on("load", function() {
				promise.complete(audioBuffer);
			});

			audioBuffer.src.on("loaderror", function(id, msg) {
				promise.error(msg);
			});

			audioBuffer.src.load();
		} else {
			promise.error(null);
		}

		return promise.future;
	}

	public static function loadFromFiles(paths:Array<String>):Future<AudioBuffer> {
		var promise = new Promise<AudioBuffer>();

		var audioBuffer = AudioBuffer.fromFiles(paths);

		if (audioBuffer != null) {
			audioBuffer.src.on("load", function() {
				promise.complete(audioBuffer);
			});

			audioBuffer.src.on("loaderror", function() {
				promise.error(null);
			});

			audioBuffer.src.load();
		} else {
			promise.error(null);
		}

		return promise.future;
	}

	private static function __getCodec(bytes:Bytes):String {
		var signature = bytes.getString(0, 4);

		switch (signature) {
			case "OggS":
				return "audio/ogg";
			case "fLaC":
				return "audio/flac";
			case "RIFF" if (bytes.getString(8, 4) == "WAVE"):
				return "audio/wav";
			default:
				switch ([bytes.get(0), bytes.get(1), bytes.get(2)]) {
					case [73, 68, 51] | [255, 251, _] | [255, 250, _]: return "audio/mp3";
					default:
				}
		}

		Log.error("Unsupported sound format");
		return null;
	}
}
