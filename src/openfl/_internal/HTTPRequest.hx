package openfl._internal;

import haxe.io.Bytes;
import js.html.Event;
import js.html.AnchorElement;
import js.html.ErrorEvent;
import js.html.Image in JSImage;
import js.html.ProgressEvent;
import js.html.XMLHttpRequest;
import js.Browser;
import openfl._internal.app.Future;
import openfl._internal.app.Promise;
import openfl._internal.graphics.Image;
import openfl.net.URLRequestHeader;
import openfl.net.URLRequestMethod;

class HTTPRequest {
	public var contentType:String;
	public var data:Bytes;
	public var enableResponseHeaders:Bool;
	public var followRedirects:Bool;
	public var formData:Map<String, Dynamic>;
	public var headers:Array<URLRequestHeader>;
	public var method:URLRequestMethod;
	public var responseHeaders:Array<URLRequestHeader>;
	public var responseStatus:Int;
	public var timeout:Int;
	public var uri:String;
	public var userAgent:String;
	public var withCredentials:Bool;

	var binary:Bool;
	var request:XMLHttpRequest;

	static final validStatus0 = ~/Tizen/gi.match(Browser.window.navigator.userAgent);

	static var activeRequests = 0;
	static var originElement:AnchorElement;
	static var originHostname:String;
	static var originPort:String;
	static var originProtocol:String;
	static var requestLimit = 4;
	static var requestQueue = new List<QueueItem>();
	static var supportsImageProgress:Null<Bool>;

	public function new() {
		contentType = "application/x-www-form-urlencoded";
		followRedirects = true;
		enableResponseHeaders = false;
		formData = new Map();
		headers = [];
		method = GET;
		timeout = #if lime_default_timeout Std.parseInt(Compiler.getDefine("lime-default-timeout")) #else 30000 #end;
		withCredentials = false;
	}

	public function cancel() {
		if (request != null) {
			request.abort();
		}
	}

	public function loadBytes():Future<Bytes> {
		var promise = new Promise<Bytes>();
		if (activeRequests < requestLimit) {
			activeRequests++;
			__loadData(uri, promise);
		} else {
			requestQueue.add({
				instance: this,
				uri: uri,
				promise: promise,
				type: BINARY
			});
		}
		return promise.future;
	}

	public function loadText():Future<String> {
		var promise = new Promise<String>();
		if (activeRequests < requestLimit) {
			activeRequests++;
			__loadText(uri, promise);
		} else {
			requestQueue.add({
				instance: this,
				uri: uri,
				promise: promise,
				type: TEXT
			});
		}
		return promise.future;
	}

	function __loadData(uri:String, promise:Promise<Bytes>) {
		binary = true;
		load(uri, event -> promise.progress(event.loaded, event.total), function(_) {
			if (request.readyState != XMLHttpRequest.DONE)
				return;

			if (request.status != null && ((request.status >= 200 && request.status < 400) || (validStatus0 && request.status == 0))) {
				var bytes = null;

				if (request.responseType == NONE) {
					if (request.responseText != null) {
						bytes = Bytes.ofString(request.responseText);
					}
				} else if (request.response != null) {
					bytes = Bytes.ofData(request.response);
				}

				processResponse();
				promise.complete(bytes);
			} else {
				processResponse();
				promise.error(request.status);
			}

			request = null;

			activeRequests--;
			processQueue();
		});
	}

	function __loadText(uri:String, promise:Promise<String>) {
		binary = false;
		load(uri, event -> promise.progress(event.loaded, event.total), function(_) {
			if (request.readyState != XMLHttpRequest.DONE)
				return;

			if (request.status != null && ((request.status >= 200 && request.status <= 400) || (validStatus0 && request.status == 0))) {
				processResponse();
				promise.complete(request.responseText);
			} else {
				processResponse();
				promise.error(request.status);
			}

			request = null;

			activeRequests--;
			processQueue();
		});
	}

	static function loadImage(uri:String):Future<Image> {
		var promise = new Promise<Image>();
		if (activeRequests < requestLimit) {
			activeRequests++;
			__loadImage(uri, promise);
		} else {
			requestQueue.add({
				instance: null,
				uri: uri,
				promise: promise,
				type: IMAGE
			});
		}
		return promise.future;
	}

	function load(uri:String, progress:ProgressEvent->Void, readyStateChange:Event->Void) {
		request = new XMLHttpRequest();

		if (method == POST) {
			request.upload.addEventListener("progress", progress, false);
		} else {
			request.addEventListener("progress", progress, false);
		}

		request.onreadystatechange = readyStateChange;

		var query = "";

		if (data == null) {
			for (key in formData.keys()) {
				if (query.length > 0)
					query += "&";
				query += StringTools.urlEncode(key) + "=" + StringTools.urlEncode(Std.string(formData.get(key)));
			}

			if (method == GET && query != "") {
				if (uri.indexOf("?") > -1) {
					uri += "&" + query;
				} else {
					uri += "?" + query;
				}

				query = "";
			}
		}

		request.open(method, uri, true);

		if (timeout > 0) {
			request.timeout = timeout;
		}

		if (binary) {
			request.responseType = ARRAYBUFFER;
		}

		var contentType = null;

		for (header in headers) {
			if (header.name == "Content-Type") {
				contentType = header.value;
			} else {
				request.setRequestHeader(header.name, header.value);
			}
		}

		if (this.contentType != null) {
			contentType = this.contentType;
		}

		if (contentType == null) {
			if (data != null) {
				contentType = "application/octet-stream";
			} else if (query != "") {
				contentType = "application/x-www-form-urlencoded";
			}
		}

		if (contentType != null) {
			request.setRequestHeader("Content-Type", contentType);
		}

		if (withCredentials) {
			request.withCredentials = true;
		}

		if (data != null) {
			request.send(data.getData());
		} else {
			request.send(query);
		}
	}

	static function processQueue() {
		if (activeRequests < requestLimit && requestQueue.length > 0) {
			activeRequests++;

			var queueItem = requestQueue.pop();
			switch (queueItem.type) {
				case IMAGE:
					__loadImage(queueItem.uri, queueItem.promise);
				case TEXT:
					queueItem.instance.__loadText(queueItem.uri, queueItem.promise);
				case BINARY:
					queueItem.instance.__loadData(queueItem.uri, queueItem.promise);
			}
		}
	}

	function processResponse() {
		if (enableResponseHeaders) {
			responseHeaders = [];
			for (line in request.getAllResponseHeaders().split("\n")) {
				var colonIndex = line.indexOf(":");
				var name = StringTools.trim(line.substr(0, colonIndex));
				if (name != "") {
					var value = StringTools.trim(line.substr(colonIndex + 1));
					responseHeaders.push(new URLRequestHeader(name, value));
				}
			}
		}
		responseStatus = request.status;
	}

	static function __fixHostname(hostname:String):String {
		return hostname == null ? "" : hostname;
	}

	static function __fixPort(port:String, protocol:String):String {
		if (port == null || port == "") {
			return switch (protocol) {
				case "ftp:": "21";
				case "gopher:": "70";
				case "http:": "80";
				case "https:": "443";
				case "ws:": "80";
				case "wss:": "443";
				default: "";
			}
		}
		return port;
	}

	static function __fixProtocol(protocol:String):String {
		return (protocol == null || protocol == "") ? "http:" : protocol;
	}

	static function __isSameOrigin(path:String):Bool {
		if (originElement == null) {
			originElement = Browser.document.createAnchorElement();
			originHostname = __fixHostname(Browser.location.hostname);
			originProtocol = __fixProtocol(Browser.location.protocol);
			originPort = __fixPort(Browser.location.port, originProtocol);
		}

		var a = originElement;
		a.href = path;

		if (a.hostname == "") {
			// Workaround for IE, updates other properties
			a.href = a.href;
		}

		var hostname = __fixHostname(a.hostname);
		var protocol = __fixProtocol(a.protocol);
		var port = __fixPort(a.port, protocol);

		var sameHost = (hostname == "" || (hostname == originHostname));
		var samePort = (port == "" || (port == originPort));

		return (protocol != "file:" && sameHost && samePort);
	}

	static function __loadImage(uri:String, promise:Promise<Image>) {
		var image = new JSImage();

		if (!__isSameOrigin(uri)) {
			image.crossOrigin = "Anonymous";
		}

		if (supportsImageProgress == null) {
			supportsImageProgress = js.Syntax.code("'onprogress' in image");
		}

		if (supportsImageProgress || StringTools.startsWith(uri, "data:")) {
			image.addEventListener("load", function(_) {
				var image = Image.fromHTMLImage(image);

				activeRequests--;
				processQueue();

				promise.complete(image);
			}, false);

			image.addEventListener("progress", function(event:ProgressEvent) {
				promise.progress(event.loaded, event.total);
			}, false);

			image.addEventListener("error", function(event:ErrorEvent) {
				activeRequests--;
				processQueue();

				promise.error(event.message);
			}, false);

			image.src = uri;
		} else {
			var request = new XMLHttpRequest();

			request.onload = function(_) {
				activeRequests--;
				processQueue();
				Image.fromBytes(Bytes.ofData(request.response), promise.complete);
			}

			request.onerror = function(event:ErrorEvent) {
				promise.error(event.message);
			}

			request.onprogress = function(event:ProgressEvent) {
				if (event.lengthComputable) {
					promise.progress(event.loaded, event.total);
				}
			}

			request.open("GET", uri, true);
			request.responseType = ARRAYBUFFER;
			request.overrideMimeType('text/plain; charset=x-user-defined');
			request.send(null);
		}
	}
}

private typedef QueueItem = {
	var instance:HTTPRequest;
	var type:AssetType;
	var promise:Dynamic;
	var uri:String;
}

private enum abstract AssetType(Int) {
	var BINARY;
	var IMAGE;
	var TEXT;
}
