package openfl.display;

import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.events.ProgressEvent;
import openfl.events.UncaughtErrorEvents;
import openfl.net.URLLoader;
import openfl.net.URLLoaderDataFormat;
import openfl.net.URLRequest;
import openfl.net.URLRequestMethod;
import openfl.system.LoaderContext;
import openfl.utils.ByteArray;

@:access(openfl.display.LoaderInfo)
@:access(openfl.events.Event)
class Loader extends DisplayObjectContainer {
	public var content(default, null):DisplayObject;
	public var contentLoaderInfo(default, null):LoaderInfo;
	public var uncaughtErrorEvents(default, null):UncaughtErrorEvents;

	private var __path:String;
	private var __unloaded:Bool;

	public function new() {
		super();

		contentLoaderInfo = LoaderInfo.create(this);
		uncaughtErrorEvents = contentLoaderInfo.uncaughtErrorEvents;
	}

	public function close():Void {
		openfl.Lib.notImplemented();
	}

	public function load(request:URLRequest, context:LoaderContext = null):Void {
		contentLoaderInfo.loaderURL = Lib.current.loaderInfo.url;
		contentLoaderInfo.url = request.url;
		__unloaded = false;

		if (request.contentType == null || request.contentType == "") {
			var extension = "";
			__path = request.url;

			var queryIndex = __path.indexOf('?');
			if (queryIndex > -1) {
				__path = __path.substring(0, queryIndex);
			}

			while (StringTools.endsWith(__path, "/")) {
				__path = __path.substring(0, __path.length - 1);
			}

			var extIndex = __path.lastIndexOf('.');
			if (extIndex > -1) {
				extension = __path.substring(extIndex + 1);
			}

			contentLoaderInfo.contentType = switch (extension) {
				case "json": "application/json";
				case "swf": "application/x-shockwave-flash";
				case "jpg", "jpeg": "image/jpeg";
				case "png": "image/png";
				case "gif": "image/gif";
				case "js": "application/javascript";
				default:
					"application/x-www-form-urlencoded"; /*throw "Unrecognized file " + request.url;*/
			}
		} else {
			contentLoaderInfo.contentType = request.contentType;
		}

		if (contentLoaderInfo.contentType.indexOf("image/") > -1
			&& request.method == URLRequestMethod.GET
			&& (request.requestHeaders == null || request.requestHeaders.length == 0)
			&& request.userAgent == null) {
			BitmapData.loadFromFile(request.url)
				.onComplete(BitmapData_onLoad)
				.onError(BitmapData_onError)
				.onProgress(BitmapData_onProgress);
			return;
		}

		var loader = new URLLoader();
		loader.dataFormat = URLLoaderDataFormat.BINARY;

		if (contentLoaderInfo.contentType.indexOf("/json") > -1
			|| contentLoaderInfo.contentType.indexOf("/javascript") > -1
			|| contentLoaderInfo.contentType.indexOf("/ecmascript") > -1) {
			loader.dataFormat = TEXT;
		}

		loader.addEventListener(Event.COMPLETE, loader_onComplete);
		loader.addEventListener(IOErrorEvent.IO_ERROR, loader_onError);
		loader.addEventListener(ProgressEvent.PROGRESS, loader_onProgress);
		loader.load(request);
	}

	public function loadBytes(buffer:ByteArray, context:LoaderContext = null):Void {
		BitmapData.loadFromBytes(buffer).onComplete(BitmapData_onLoad).onError(BitmapData_onError);
	}

	public function unload():Void {
		if (!__unloaded) {
			while (numChildren > 0) {
				removeChildAt(0);
			}

			content = null;
			contentLoaderInfo.url = null;
			contentLoaderInfo.contentType = null;
			contentLoaderInfo.content = null;
			contentLoaderInfo.bytesLoaded = 0;
			contentLoaderInfo.bytesTotal = 0;
			contentLoaderInfo.width = 0;
			contentLoaderInfo.height = 0;
			__unloaded = true;

			contentLoaderInfo.dispatchEvent(new Event(Event.UNLOAD));
		}
	}

	public function unloadAndStop(gc:Bool = true):Void {
		if (content != null) {
			content.__stopAllMovieClips();
		}

		for (i in 0...numChildren) {
			getChildAt(i).__stopAllMovieClips();
		}

		unload();

		if (gc) {
			#if cpp
			cpp.vm.Gc.run(false);
			#elseif neko
			neko.vm.Gc.run(false);
			#end
		}
	}

	private function __dispatchError(text:String):Void {
		var event = new IOErrorEvent(IOErrorEvent.IO_ERROR);
		event.text = text;
		contentLoaderInfo.dispatchEvent(event);
	}

	// Event Handlers

	private function BitmapData_onError(error:Dynamic):Void {
		// TODO: Dispatch HTTPStatusEvent

		__dispatchError(Std.string(error));
	}

	private function BitmapData_onLoad(bitmapData:BitmapData):Void {
		// TODO: Dispatch HTTPStatusEvent

		content = new Bitmap(bitmapData);
		contentLoaderInfo.content = content;
		addChild(content);

		contentLoaderInfo.dispatchEvent(new Event(Event.COMPLETE));
	}

	private function BitmapData_onProgress(bytesLoaded:Int, bytesTotal:Int):Void {
		var event = new ProgressEvent(ProgressEvent.PROGRESS);
		event.bytesLoaded = bytesLoaded;
		event.bytesTotal = bytesTotal;
		contentLoaderInfo.dispatchEvent(event);
	}

	private function loader_onComplete(event:Event):Void {
		// TODO: Dispatch HTTPStatusEvent

		var loader:URLLoader = cast event.target;

		if (contentLoaderInfo.contentType != null
			&& (contentLoaderInfo.contentType.indexOf("/javascript") > -1 || contentLoaderInfo.contentType.indexOf("/ecmascript") > -1)) {
			content = new Sprite();
			contentLoaderInfo.content = content;
			addChild(content);

			js.Lib.eval('(function () {' + loader.data + '})()');

			contentLoaderInfo.dispatchEvent(new Event(Event.COMPLETE));
		} else {
			BitmapData.loadFromBytes(loader.data).onComplete(BitmapData_onLoad).onError(BitmapData_onError);
		}
	}

	private function loader_onError(event:IOErrorEvent):Void {
		// TODO: Dispatch HTTPStatusEvent

		event.target = contentLoaderInfo;
		contentLoaderInfo.dispatchEvent(event);
	}

	private function loader_onProgress(event:ProgressEvent):Void {
		event.target = contentLoaderInfo;
		contentLoaderInfo.dispatchEvent(event);
	}
}
