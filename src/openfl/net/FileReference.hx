package openfl.net;

import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.IOErrorEvent;
import openfl.events.ProgressEvent;
import openfl.utils.ByteArray;

class FileReference extends EventDispatcher {
	public var creationDate(default, null):Date;
	public var creator(default, null):String;
	public var data(default, null):ByteArray;
	public var modificationDate(default, null):Date;
	public var name(default, null):String;
	public var size(default, null):Int;
	public var type(default, null):String;

	private var __data:ByteArray;
	private var __path:String;
	private var __urlLoader:URLLoader;

	public function new() {
		super();
	}

	public function browse(typeFilter:Array<FileFilter> = null):Bool {
		__data = null;
		__path = null;
		return false;
	}

	public function cancel():Void {
		if (__urlLoader != null) {
			__urlLoader.close();
		}
	}

	public function download(request:URLRequest, defaultFileName:String = null):Void {
		__data = null;
		__path = null;

		__urlLoader = new URLLoader();
		__urlLoader.addEventListener(Event.COMPLETE, urlLoader_onComplete);
		__urlLoader.addEventListener(IOErrorEvent.IO_ERROR, urlLoader_onIOError);
		__urlLoader.addEventListener(ProgressEvent.PROGRESS, urlLoader_onProgress);
		__urlLoader.load(request);
	}

	public function load():Void {}

	public function save(data:Dynamic, defaultFileName:String = null):Void {
		__data = null;
		__path = null;
	}

	public function upload(request:URLRequest, uploadDataFieldName:String = "Filedata", testUpload:Bool = false):Void {
		openfl.Lib.notImplemented();
	}

	private function urlLoader_onComplete(event:Event):Void {
		dispatchEvent(event);
	}

	private function urlLoader_onIOError(event:IOErrorEvent):Void {
		dispatchEvent(event);
	}

	private function urlLoader_onProgress(event:ProgressEvent):Void {
		dispatchEvent(event);
	}
}
