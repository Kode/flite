package openfl._internal.graphics;

import haxe.crypto.BaseCode;
import haxe.io.Bytes;
import openfl._internal.app.Future;
import openfl._internal.graphics.utils.ImageCanvasUtil;
import openfl._internal.graphics.utils.ImageDataUtil;
import openfl.geom.Rectangle;
import openfl.geom.Point;
import openfl.utils.Endian;
import openfl.display.BitmapDataChannel;
import openfl._internal.HTTPRequest;
import js.lib.Uint8Array;
import js.lib.Uint8ClampedArray;
import js.html.CanvasRenderingContext2D;
import js.html.CanvasElement;
import js.html.Image in JSImage;
import js.html.ImageData;
import js.Browser;

enum ImageType {
	CANVAS;
	DATA;
}

@:allow(openfl._internal.graphics.util.ImageCanvasUtil)
@:allow(openfl._internal.graphics.util.ImageDataUtil)
@:access(openfl._internal.HTTPRequest)
class Image {
	static inline final __base64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
	static var __base64Encoder:BaseCode;

	public final width:Int;
	public final height:Int;
	public var dirty:Bool;
	public var rect(get, never):Rectangle;
	public var src(get, never):Dynamic;
	public var transparent:Bool = true; // TODO, modify data to set transparency
	public var type:ImageType;
	public var version:Int;
	public var stride(get, never):Int;

	var data:Uint8Array;
	var __srcCanvas:CanvasElement;
	var __srcContext:CanvasRenderingContext2D;
	var __srcImage:JSImage;
	var __srcImageData:ImageData;

	public static function fromColor(width:Int, height:Int, fillColor:Int, transparent:Bool):Image {
		if (transparent) {
			if ((fillColor & 0xFF000000) == 0) {
				fillColor = 0;
			}
		} else {
			fillColor = (0xFF << 24) | (fillColor & 0xFFFFFF);
		}

		fillColor = (fillColor << 8) | ((fillColor >> 24) & 0xFF);

		var image = new Image(width, height);
		image.transparent = transparent;
		image.createCanvas();
		if (fillColor != 0) {
			image.fillRect(new Rectangle(0, 0, width, height), fillColor, RGBA32);
		}
		return image;
	}

	public static function fromCanvas(canvas:CanvasElement):Image {
		var image = new Image(canvas.width, canvas.height);
		image.__srcCanvas = canvas;
		image.__srcContext = canvas.getContext2d();
		return image;
	}

	public static function fromHTMLImage(htmlImage:JSImage):Image {
		var image = new Image(htmlImage.width, htmlImage.height);
		image.__srcImage = htmlImage;
		return image;
	}

	function new(width:Int, height:Int) {
		this.width = width;
		this.height = height;

		version = 0;
		type = CANVAS;
	}

	public function sync() {
		if (type == CANVAS) {
			ImageCanvasUtil.convertToCanvas(this, false);
		} else {
			ImageCanvasUtil.convertToData(this);
		}
	}

	function createCanvas() {
		__srcCanvas = Browser.document.createCanvasElement();
		__srcCanvas.width = width;
		__srcCanvas.height = height;
		if (!transparent) {
			__srcCanvas.setAttribute("moz-opaque", "true");
			__srcContext = __srcCanvas.getContext2d({alpha: false});
		} else {
			__srcContext = __srcCanvas.getContext2d();
		}
		openfl._internal.renderer.canvas.CanvasSmoothing.setEnabled(__srcContext, false);
	}

	function createImageData() {
		if (__srcImageData == null) {
			if (data == null) {
				__srcImageData = __srcContext.getImageData(0, 0, width, height);
			} else {
				__srcImageData = __srcContext.createImageData(width, height);
				__srcImageData.data.set(cast /* TODO: remove the cast on latest Haxe */ data);
			}
			data = new Uint8Array(__srcImageData.data.buffer);
		}
	}

	public function clone():Image {
		sync();

		var image = new Image(width, height);
		image.version = version;
		image.type = type;

		if (data != null) {
			image.data = new Uint8Array(data.length);
			image.data.set(new Uint8Array(data));
		} else if (__srcImageData != null) {
			image.__srcCanvas = Browser.document.createCanvasElement();
			image.__srcContext = image.__srcCanvas.getContext2d();
			image.__srcCanvas.width = __srcImageData.width;
			image.__srcCanvas.height = __srcImageData.height;
			image.__srcImageData = image.__srcContext.createImageData(__srcImageData.width, __srcImageData.height);
			image.__srcImageData.data.set(new Uint8ClampedArray(__srcImageData.data));
		} else if (__srcCanvas != null) {
			image.__srcCanvas = Browser.document.createCanvasElement();
			image.__srcContext = image.__srcCanvas.getContext2d();
			image.__srcCanvas.width = __srcCanvas.width;
			image.__srcCanvas.height = __srcCanvas.height;
			image.__srcContext.drawImage(__srcCanvas, 0, 0);
		} else {
			image.__srcImage = __srcImage;
		}

		return image;
	}

	public function copyChannel(sourceImage:Image, sourceRect:Rectangle, destPoint:Point, sourceChannel:BitmapDataChannel, destChannel:BitmapDataChannel) {
		sourceRect = __clipRect(sourceRect);
		if (sourceRect == null)
			return;
		if (destChannel == ALPHA && !transparent)
			return;
		if (sourceRect.width <= 0 || sourceRect.height <= 0)
			return;
		if (sourceRect.x + sourceRect.width > sourceImage.width)
			sourceRect.width = sourceImage.width - sourceRect.x;
		if (sourceRect.y + sourceRect.height > sourceImage.height)
			sourceRect.height = sourceImage.height - sourceRect.y;

		ImageCanvasUtil.convertToData(this);
		ImageCanvasUtil.convertToData(sourceImage);
		ImageDataUtil.copyChannel(this, sourceImage, sourceRect, destPoint, sourceChannel, destChannel);
	}

	public function copyPixels(sourceImage:Image, sourceRect:Rectangle, destPoint:Point, alphaImage:Image = null, alphaPoint:Point = null, mergeAlpha:Bool = false) {
		if (sourceImage == null)
			return;
		if (sourceRect.width <= 0 || sourceRect.height <= 0)
			return;
		if (width <= 0 || height <= 0)
			return;

		if (sourceRect.x + sourceRect.width > sourceImage.width)
			sourceRect.width = sourceImage.width - sourceRect.x;
		if (sourceRect.y + sourceRect.height > sourceImage.height)
			sourceRect.height = sourceImage.height - sourceRect.y;

		if (sourceRect.x < 0) {
			sourceRect.width += sourceRect.x;
			sourceRect.x = 0;
		}

		if (sourceRect.y < 0) {
			sourceRect.height += sourceRect.y;
			sourceRect.y = 0;
		}

		if (destPoint.x + sourceRect.width > width)
			sourceRect.width = width - destPoint.x;
		if (destPoint.y + sourceRect.height > height)
			sourceRect.height = height - destPoint.y;

		if (destPoint.x < 0) {
			sourceRect.width += destPoint.x;
			sourceRect.x -= destPoint.x;
			destPoint.x = 0;
		}

		if (destPoint.y < 0) {
			sourceRect.height += destPoint.y;
			sourceRect.y -= destPoint.y;
			destPoint.y = 0;
		}

		if (sourceImage == this && destPoint.x < sourceRect.right && destPoint.y < sourceRect.bottom) {
			// TODO: Optimize further?
			sourceImage = clone();
		}

		switch (type) {
			case CANVAS:
				if (alphaImage != null || sourceImage.type != CANVAS) {
					ImageCanvasUtil.convertToData(this);
					ImageCanvasUtil.convertToData(sourceImage);
					if (alphaImage != null)
						ImageCanvasUtil.convertToData(alphaImage);

					ImageDataUtil.copyPixels(this, sourceImage, sourceRect, destPoint, alphaImage, alphaPoint, mergeAlpha);
				} else {
					ImageCanvasUtil.convertToCanvas(this);
					ImageCanvasUtil.convertToCanvas(sourceImage);
					ImageCanvasUtil.copyPixels(this, sourceImage, sourceRect, destPoint, alphaImage, alphaPoint, mergeAlpha);
				}

			case DATA:
				ImageCanvasUtil.convertToData(this);
				ImageCanvasUtil.convertToData(sourceImage);
				if (alphaImage != null)
					ImageCanvasUtil.convertToData(alphaImage);

				ImageDataUtil.copyPixels(this, sourceImage, sourceRect, destPoint, alphaImage, alphaPoint, mergeAlpha);
		}
	}

	public function fillRect(rect:Rectangle, color:Int, format:PixelFormat) {
		rect = __clipRect(rect);
		if (rect == null)
			return;

		switch (type) {
			case CANVAS:
				ImageCanvasUtil.fillRect(this, rect, color, format);

			case DATA:
				ImageCanvasUtil.convertToData(this);

				if (data.length == 0)
					return;

				ImageDataUtil.fillRect(this, rect, color, format);
		}
	}

	public function floodFill(x:Int, y:Int, color:Int) {
		ImageCanvasUtil.convertToData(this);
		ImageDataUtil.floodFill(this, x, y, ((color & 0xFFFFFF) << 8) | ((color >> 24) & 0xFF));
	}

	public function getColorBoundsRect(mask:Int, color:Int, findColor:Bool = true, format:PixelFormat):Rectangle {
		switch (type) {
			case CANVAS:
				ImageCanvasUtil.convertToData(this);
				return ImageDataUtil.getColorBoundsRect(this, mask, color, findColor, format);

			case DATA:
				return ImageDataUtil.getColorBoundsRect(this, mask, color, findColor, format);
		}
	}

	public function getPixel(x:Int, y:Int, format:PixelFormat):Int {
		if (x < 0 || y < 0 || x >= width || y >= height)
			return 0;

		ImageCanvasUtil.convertToData(this);
		return ImageDataUtil.getPixel(this, x, y, format);
	}

	public function getPixel32(x:Int, y:Int, format:PixelFormat):Int {
		if (x < 0 || y < 0 || x >= width || y >= height)
			return 0;

		ImageCanvasUtil.convertToData(this);
		return ImageDataUtil.getPixel32(this, x, y, format);
	}

	public function getPixels(rect:Rectangle, format:PixelFormat):Bytes {
		ImageCanvasUtil.convertToData(this);
		return ImageDataUtil.getPixels(this, rect, format);
	}

	public static function loadFromBase64(base64:String, type:String):Future<Image> {
		if (base64 == null || type == null)
			return Future.withValue(null);

		return HTTPRequest.loadImage("data:" + type + ";base64," + base64);
	}

	public static function loadFromBytes(bytes:Bytes):Future<Image> {
		if (bytes == null)
			return Future.withValue(null);

		var type = "";

		if (__isPNG(bytes)) {
			type = "image/png";
		} else if (__isJPG(bytes)) {
			type = "image/jpeg";
		} else if (__isGIF(bytes)) {
			type = "image/gif";
		} else if (__isWebP(bytes)) {
			type = "image/webp";
		} else {
			// throw "Image tried to read PNG/JPG Bytes, but found an invalid header.";
			return Future.withValue(null);
		}

		return loadFromBase64(__base64Encode(bytes), type);
	}

	public static function loadFromFile(path:String):Future<Image> {
		if (path == null)
			return Future.withValue(null);
		return HTTPRequest.loadImage(path);
	}

	public function getData():Uint8Array {
		if (data == null && width > 0 && height > 0) {
			ImageCanvasUtil.convertToData(this);
		}
		return data;
	}

	public function merge(sourceImage:Image, sourceRect:Rectangle, destPoint:Point, redMultiplier:Int, greenMultiplier:Int, blueMultiplier:Int,
			alphaMultiplier:Int):Void {
		if (sourceImage == null)
			return;

		if (type == CANVAS) {
			ImageCanvasUtil.convertToCanvas(this);
		}
		ImageCanvasUtil.convertToData(this);
		ImageCanvasUtil.convertToData(sourceImage);
		ImageDataUtil.merge(this, sourceImage, sourceRect, destPoint, redMultiplier, greenMultiplier, blueMultiplier, alphaMultiplier);
	}

	public function scroll(x:Int, y:Int):Void {
		switch (type) {
			case CANVAS:
				ImageCanvasUtil.scroll(this, x, y);

			case DATA:
				copyPixels(this, rect, new Point(x, y));
		}
	}

	public function setPixel(x:Int, y:Int, color:Int, format:PixelFormat) {
		if (x < 0 || y < 0 || x >= width || y >= height)
			return;

		ImageCanvasUtil.convertToData(this);
		ImageDataUtil.setPixel(this, x, y, color, format);
	}

	public function setPixel32(x:Int, y:Int, color:Int, format:PixelFormat) {
		if (x < 0 || y < 0 || x >= width || y >= height)
			return;

		ImageCanvasUtil.convertToData(this);
		ImageDataUtil.setPixel32(this, x, y, color, format);
	}

	public function setPixels(rect:Rectangle, bytes:Bytes, format:PixelFormat, endian:Endian):Void {
		rect = __clipRect(rect);
		if (rect == null)
			return;
		ImageCanvasUtil.convertToData(this);
		ImageDataUtil.setPixels(this, rect, bytes, format, endian);
	}

	public function threshold(sourceImage:Image, sourceRect:Rectangle, destPoint:Point, operation:String, threshold:Int, color:Int, mask:Int, copySource:Bool, format:PixelFormat):Int {
		if (sourceImage == null || sourceRect == null)
			return 0;

		ImageCanvasUtil.convertToData(this);
		ImageCanvasUtil.convertToData(sourceImage);
		return ImageDataUtil.threshold(this, sourceImage, sourceRect, destPoint, operation, threshold, color, mask, copySource, format);
	}

	public inline function encodePNG():Bytes {
		return __encode("image/png", null);
	}

	public inline function encodeJPEG(quality:Int):Bytes {
		return __encode("image/jpeg", quality / 100);
	}

	function __encode(type:String, encoderOptions:Dynamic):Null<Bytes> {
		ImageCanvasUtil.convertToCanvas(this, false);
		if (__srcCanvas == null) {
			return null;
		}

		var data = __srcCanvas.toDataURL("image/jpeg", encoderOptions);
		var buffer = js.Browser.window.atob(data.split(";base64,")[1]);
		var bytes = Bytes.alloc(buffer.length);

		for (i in 0...buffer.length) {
			bytes.set(i, StringTools.fastCodeAt(buffer, i));
		}

		return bytes;
	}

	private static function __base64Encode(bytes:Bytes):String {
		var extension = switch (bytes.length % 3) {
			case 1: "==";
			case 2: "=";
			default: "";
		}

		if (__base64Encoder == null) {
			__base64Encoder = new BaseCode(Bytes.ofString(__base64Chars));
		}

		return __base64Encoder.encodeBytes(bytes).toString() + extension;
	}

	private function __clipRect(r:Rectangle):Rectangle {
		if (r == null)
			return null;

		if (r.x < 0) {
			r.width -= -r.x;
			r.x = 0;

			if (r.x + r.width <= 0)
				return null;
		}

		if (r.y < 0) {
			r.height -= -r.y;
			r.y = 0;

			if (r.y + r.height <= 0)
				return null;
		}

		if (r.x + r.width >= width) {
			r.width -= r.x + r.width - width;

			if (r.width <= 0)
				return null;
		}

		if (r.y + r.height >= height) {
			r.height -= r.y + r.height - height;

			if (r.height <= 0)
				return null;
		}

		return r;
	}

	public static function fromBytes(bytes:Bytes, onload:Image->Void):Void {
		var type;
		if (__isPNG(bytes)) {
			type = "image/png";
		} else if (__isJPG(bytes)) {
			type = "image/jpeg";
		} else if (__isGIF(bytes)) {
			type = "image/gif";
		} else {
			trace("Image tried to read PNG/JPG Bytes, but found an invalid header.");
			return;
		}
		__fromBase64(__base64Encode(bytes), type, onload);
	}

	static function __fromBase64(base64:String, type:String, onload:Image->Void) {
		var image = new JSImage();
		image.addEventListener("load", _ -> onload(Image.fromHTMLImage(image)), false);
		image.src = "data:" + type + ";base64," + base64;
	}

	static function __isGIF(bytes:Bytes):Bool {
		if (bytes.length < 6)
			return false;

		var header = bytes.getString(0, 6);
		return (header == "GIF87a" || header == "GIF89a");
	}

	static function __isJPG(bytes:Bytes):Bool {
		if (bytes.length < 4)
			return false;

		return bytes.get(0) == 0xFF
			&& bytes.get(1) == 0xD8
			&& bytes.get(bytes.length - 2) == 0xFF
			&& bytes.get(bytes.length - 1) == 0xD9;
	}

	static function __isPNG(bytes:Bytes):Bool {
		if (bytes.length < 8)
			return false;

		return (bytes.get(0) == 0x89 && bytes.get(1) == "P".code && bytes.get(2) == "N".code && bytes.get(3) == "G".code && bytes.get(4) == "\r".code
			&& bytes.get(5) == "\n".code && bytes.get(6) == 0x1A && bytes.get(7) == "\n".code);
	}

	static function __isWebP(bytes:Bytes):Bool {
		if (bytes.length < 16)
			return false;

		return (bytes.getString(0, 4) == "RIFF" && bytes.getString(8, 4) == "WEBP");
	}

	// Get & Set Methods

	private function get_rect():Rectangle {
		return new Rectangle(0, 0, width, height);
	}

	function get_src():Dynamic {
		if (__srcImage != null)
			return __srcImage;
		return __srcCanvas;
	}

	inline function get_stride():Int {
		return width * 4;
	}
}
