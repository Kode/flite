package openfl.display;

import openfl._internal.app.Future;
import openfl._internal.graphics.Image;
import openfl._internal.graphics.utils.ImageCanvasUtil;
import openfl._internal.graphics.utils.ImageDataUtil;
import openfl._internal.graphics.color.ARGB;
import kha.arrays.Float32Array;
import openfl._internal.renderer.canvas.CanvasSmoothing;
import openfl._internal.renderer.canvas.CanvasRenderSession;
import openfl._internal.utils.PerlinNoise;
import openfl.errors.Error;
import openfl.filters.BitmapFilter;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.utils.ByteArray;
import openfl.utils.Object;
import openfl.Vector;
import openfl._internal.renderer.opengl.batcher.TextureData;
import openfl._internal.renderer.opengl.batcher.QuadTextureData;
import js.html.webgl.GL;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;

@:access(openfl._internal.graphics.Image)
@:access(openfl._internal.renderer.opengl.GLRenderer)
@:access(openfl.display3D.textures.TextureBase)
@:access(openfl.display.DisplayObject)
@:access(openfl.display.Graphics)
@:access(openfl.filters.BitmapFilter)
@:access(openfl.geom.ColorTransform)
@:access(openfl.geom.Matrix)
@:access(openfl.geom.Point)
@:access(openfl.geom.Rectangle)
class BitmapData implements IBitmapDrawable {
	public var height(default, null):Int;
	public var rect(default, null):Rectangle;
	public var transparent(default, null):Bool;
	public var width(default, null):Int;

	var image:Image;
	var __readable:Bool;
	var __alpha:Float;
	var __visible:Bool;
	var __blendMode:BlendMode;
	var __isMask:Bool;
	var __isValid:Bool;
	var __renderable:Bool;
	var __pixelRatio:Float = 1.0;
	var __textureData:TextureData;
	var __quadTextureData:QuadTextureData;
	var __textureVersion:Int;
	var __ownsTexture:Bool;
	var __transform:Matrix;
	var __worldAlpha:Float;
	var __worldColorTransform:ColorTransform;
	var __worldTransform:Matrix;
	var __maskVertexBuffer:kha.graphics4.VertexBuffer;

	public function new(width:Int, height:Int, transparent:Bool = true, fillColor:UInt = 0xFFFFFFFF) {
		if (width == null || width < 0) width = 0;
		if (height == null || height < 0) height = 0;

		this.width = width;
		this.height = height;
		this.transparent = transparent;

		rect = new Rectangle(0, 0, width, height);

		if (width > 0 && height > 0) {
			image = Image.fromColor(width, height, fillColor, transparent);
			__isValid = true;
			__readable = true;
		}

		__worldTransform = new Matrix();
		__worldColorTransform = new ColorTransform();
		__renderable = true;
		__ownsTexture = false;
	}

	public function applyFilter(sourceBitmapData:BitmapData, sourceRect:Rectangle, destPoint:Point, filter:BitmapFilter):Void {
		if (!__readable || sourceBitmapData == null || !sourceBitmapData.__readable)
			return;

		filter.__applyFilter(this, sourceBitmapData, sourceRect, destPoint);
	}

	public function clone():BitmapData {
		if (!__isValid) {
			return new BitmapData(width, height, transparent, 0);
		} else if (!__readable && image == null) {
			var bitmapData = new BitmapData(0, 0, transparent, 0);

			bitmapData.width = width;
			bitmapData.height = height;
			bitmapData.rect.copyFrom(rect);

			bitmapData.__textureData = __textureData;
			bitmapData.__isValid = true;

			return bitmapData;
		} else {
			return BitmapData.fromImage(image.clone(), transparent);
		}
	}

	public function colorTransform(rect:Rectangle, colorTransform:ColorTransform):Void {
		if (!__readable)
			return;

		rect = image.__clipRect(rect.clone());
		if (rect == null)
			return;

		ImageCanvasUtil.convertToData(image);
		ImageDataUtil.colorTransform(image, rect, colorTransform);
	}

	public function compare(otherBitmapData:BitmapData):Dynamic {
		if (otherBitmapData == this) {
			return 0;
		} else if (otherBitmapData == null) {
			return -1;
		} else if (__readable == false || otherBitmapData.__readable == false) {
			return -2;
		} else if (width != otherBitmapData.width) {
			return -3;
		} else if (height != otherBitmapData.height) {
			return -4;
		}

		if (image != null && otherBitmapData.image != null) {
			var bytes = image.getData();
			var otherBytes = otherBitmapData.image.getData();
			var equal = true;

			for (i in 0...bytes.length) {
				if (bytes[i] != otherBytes[i]) {
					equal = false;
					break;
				}
			}

			if (equal) {
				return 0;
			}
		}

		var bitmapData = null;
		var foundDifference,
			pixel:ARGB,
			otherPixel:ARGB,
			comparePixel:ARGB,
			r,
			g,
			b,
			a;

		for (y in 0...height) {
			for (x in 0...width) {
				foundDifference = false;

				pixel = getPixel32(x, y);
				otherPixel = otherBitmapData.getPixel32(x, y);
				comparePixel = 0;

				if (pixel != otherPixel) {
					r = pixel.r - otherPixel.r;
					g = pixel.g - otherPixel.g;
					b = pixel.b - otherPixel.b;

					if (r < 0)
						r *= -1;
					if (g < 0)
						g *= -1;
					if (b < 0)
						b *= -1;

					if (r == 0 && g == 0 && b == 0) {
						a = pixel.a - otherPixel.a;

						if (a != 0) {
							comparePixel.r = 0xFF;
							comparePixel.g = 0xFF;
							comparePixel.b = 0xFF;
							comparePixel.a = a;

							foundDifference = true;
						}
					} else {
						comparePixel.r = r;
						comparePixel.g = g;
						comparePixel.b = b;
						comparePixel.a = 0xFF;

						foundDifference = true;
					}
				}

				if (foundDifference) {
					if (bitmapData == null) {
						bitmapData = new BitmapData(width, height, transparent || otherBitmapData.transparent, 0x00000000);
					}

					bitmapData.setPixel32(x, y, comparePixel);
				}
			}
		}

		if (bitmapData == null) {
			return 0;
		}

		return bitmapData;
	}

	public function copyChannel(sourceBitmapData:BitmapData, sourceRect:Rectangle, destPoint:Point, sourceChannel:BitmapDataChannel, destChannel:BitmapDataChannel):Void {
		if (!__readable)
			return;

		image.copyChannel(sourceBitmapData.image, sourceRect.__toLimeRectangle(), destPoint.__toLimeVector2(), sourceChannel, destChannel);
	}

	public function copyPixels(sourceBitmapData:BitmapData, sourceRect:Rectangle, destPoint:Point, alphaBitmapData:BitmapData = null, alphaPoint:Point = null, mergeAlpha:Bool = false):Void {
		if (!__readable || sourceBitmapData == null || !sourceBitmapData.__prepareImage())
			return;

		image.copyPixels(sourceBitmapData.image, sourceRect.__toLimeRectangle(), destPoint.__toLimeVector2(),
			alphaBitmapData != null ? alphaBitmapData.image : null, alphaPoint, mergeAlpha);
	}

	public function dispose():Void {
		__cleanup();

		image = null;

		width = 0;
		height = 0;
		rect = null;

		__isValid = false;
		__readable = false;

		// gotta call this in  finalizer i guess

		if (__maskVertexBuffer != null) {
			__maskVertexBuffer.delete();
			__maskVertexBuffer = null;
		}

		if (__ownsTexture) {
			__ownsTexture = false;
			__textureData.image.unload();
			__textureData = null;
		}
	}

	public inline function disposeImage() {
		__readable = false;
	}

	public function draw(source:IBitmapDrawable, matrix:Matrix = null, colorTransform:ColorTransform = null, blendMode:BlendMode = null, clipRect:Rectangle = null, smoothing:Bool = false):Void {
		if (matrix == null) {
			matrix = new Matrix();
			if (source.__transform != null) {
				matrix.copyFrom(source.__transform);
				matrix.tx = 0;
				matrix.ty = 0;
			}
		}

		if (__readable /*&& source.__readable*/) {
			if (colorTransform != null && !colorTransform.__isDefault()) {
				var bounds = Rectangle.__pool.get();
				{
					var boundsMatrix = Matrix.__pool.get();
					source.__getBounds(bounds, boundsMatrix);
					Matrix.__pool.release(boundsMatrix);
				}
				var width = Math.ceil(bounds.width);
				var height = Math.ceil(bounds.height);
				Rectangle.__pool.release(bounds);

				var copy = new BitmapData(width, height, true, 0);
				copy.__pixelRatio = __pixelRatio;
				copy.draw(source);
				copy.colorTransform(copy.rect, colorTransform);
				source = copy;
			}
			__draw(source, matrix, smoothing, clipRect, false, blendMode);
		}
	}

	public function drawWithQuality(source:IBitmapDrawable, matrix:Matrix = null, colorTransform:ColorTransform = null, blendMode:BlendMode = null, clipRect:Rectangle = null, smoothing:Bool = false, quality:StageQuality = null):Void {
		draw(source, matrix, colorTransform, blendMode, clipRect, quality != LOW ? smoothing : false);
	}

	public function encode(rect:Rectangle, compressor:Object, byteArray:ByteArray = null):ByteArray {
		if (!__readable || rect == null) {
			return null;
		}

		if (byteArray == null)
			byteArray = new ByteArray();

		var image = this.image;

		if (!rect.equals(this.rect)) {
			var matrix = Matrix.__pool.get();
			matrix.tx = Math.round(-rect.x);
			matrix.ty = Math.round(-rect.y);

			var bitmapData = new BitmapData(Math.ceil(rect.width), Math.ceil(rect.height), true, 0);
			bitmapData.draw(this, matrix);

			image = bitmapData.image;

			Matrix.__pool.release(matrix);
		}

		if (Std.is(compressor, PNGEncoderOptions)) {
			byteArray.writeBytes(ByteArray.fromBytes(image.encodePNG()));
			return byteArray;
		} else if (Std.is(compressor, JPEGEncoderOptions)) {
			byteArray.writeBytes(ByteArray.fromBytes(image.encodeJPEG((cast compressor : JPEGEncoderOptions).quality)));
			return byteArray;
		} else {
			return null;
		}
	}

	public function fillRect(rect:Rectangle, color:Int):Void {
		if (rect == null)
			return;

		if (transparent && (color & 0xFF000000) == 0) {
			color = 0;
		}

		if (__readable) {
			image.fillRect(rect.__toLimeRectangle(), color, ARGB32);
		}
	}

	public function floodFill(x:Int, y:Int, color:Int):Void {
		if (!__readable)
			return;
		image.floodFill(x, y, color);
	}

	public static function fromCanvas(canvas:CanvasElement, transparent:Bool = true):BitmapData {
		if (canvas == null)
			return null;

		var bitmapData = new BitmapData(0, 0, transparent, 0);
		bitmapData.__fromImage(Image.fromCanvas(canvas));
		bitmapData.image.transparent = transparent;
		return bitmapData;
	}

	public static function fromKhaImage(image:kha.Image):BitmapData {
		// hacky crap
		return fromImage(openfl._internal.graphics.Image.fromHTMLImage((cast image : kha.WebGLImage).image));
	}

	public static function fromImage(image:Image, transparent:Bool = true):BitmapData {
		if (image == null)
			return null;

		var bitmapData = new BitmapData(0, 0, transparent, 0);
		bitmapData.__fromImage(image);
		bitmapData.image.transparent = transparent;
		return bitmapData;
	}

	public function generateFilterRect(sourceRect:Rectangle, filter:BitmapFilter):Rectangle {
		return sourceRect.clone();
	}

	public function getMaskVertexBuffer(vertexStructure) {
		var vertexBuffer = __maskVertexBuffer;
		if (vertexBuffer == null) {
			vertexBuffer = new kha.graphics4.VertexBuffer(4, vertexStructure, StaticUsage);
			var data = vertexBuffer.lock();
			var r = __pixelRatio;
			data[ 0] = 0;           data[ 1] = 0;            data[ 2] = 0; data[ 3] = 0;
			data[ 4] = width / r;   data[ 5] = 0;            data[ 6] = 1; data[ 7] = 0;
			data[ 8] = width / r;   data[ 9] = height / r;   data[10] = 1; data[11] = 1;
			data[12] = 0;           data[13] = height / r;   data[14] = 0; data[15] = 1;
			vertexBuffer.unlock();
			__maskVertexBuffer = vertexBuffer;
		}
		return vertexBuffer;
	}

	/**
		Calculate texture coordinates for a quad representing a texture region
		inside this BitmapData given normalized texture coordinates.
	**/
	public function __getTextureRegion(uvX:Float, uvY:Float, uvWidth:Float, uvHeight:Float, result:TextureRegionResult) {
		result.u0 = uvX;
		result.v0 = uvY;

		result.u1 = uvWidth;
		result.v1 = uvY;

		result.u2 = uvWidth;
		result.v2 = uvHeight;

		result.u3 = uvX;
		result.v3 = uvHeight;
	}

	public function getColorBoundsRect(mask:Int, color:Int, findColor:Bool = true):Rectangle {
		if (!__readable)
			return new Rectangle(0, 0, width, height);

		if (!transparent || ((mask >> 24) & 0xFF) > 0) {
			var color = (color : ARGB);
			if (color.a == 0)
				color = 0;
		}

		return image.getColorBoundsRect(mask, color, findColor, ARGB32);
	}

	public function getPixel(x:Int, y:Int):Int {
		if (!__readable)
			return 0;
		return image.getPixel(x, y, ARGB32);
	}

	public function getPixel32(x:Int, y:Int):Int {
		if (!__readable)
			return 0;
		return image.getPixel32(x, y, ARGB32);
	}

	public function getPixels(rect:Rectangle):ByteArray {
		if (!__readable)
			return null;
		if (rect == null)
			rect = this.rect;
		var byteArray = ByteArray.fromBytes(image.getPixels(rect.__toLimeRectangle(), ARGB32));
		// TODO: System endian order
		byteArray.endian = BIG_ENDIAN;
		return byteArray;
	}

	function __getTexture():QuadTextureData {
		if (!__isValid)
			return null;

		var gl = kha.SystemImpl.gl;

		if (__textureData == null) {
			__textureData = new TextureData(TextureData.createImageFromGLTexture(gl.createTexture()));
			__quadTextureData = null;
			__ownsTexture = true;

			gl.bindTexture(GL.TEXTURE_2D, __textureData.glTexture);
			gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
			gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
			gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.NEAREST);
			gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.NEAREST);
			__textureVersion = -1;
		}

		if (image != null && image.version != __textureVersion) {
			gl.bindTexture(GL.TEXTURE_2D, __textureData.glTexture);

			var textureImage = image;
			gl.pixelStorei(GL.UNPACK_PREMULTIPLY_ALPHA_WEBGL, 1);

			if (textureImage.type == DATA) {
				gl.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, textureImage.width, textureImage.height, 0, GL.RGBA, GL.UNSIGNED_BYTE, textureImage.getData());
			} else {
				gl.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, GL.RGBA, GL.UNSIGNED_BYTE, textureImage.src);
			}

			gl.bindTexture(GL.TEXTURE_2D, null);
			__textureVersion = image.version;
		}

		if (!__readable && image != null) {
			image = null;
		}

		if (__quadTextureData == null) {
			__quadTextureData = __prepareQuadTextureData(__textureData);
		}

		return __quadTextureData;
	}

	function __prepareQuadTextureData(texture:TextureData):QuadTextureData {
		return QuadTextureData.createFullFrame(texture, true);
	}

	function __fillBatchQuad(transform:Matrix, vertexData:Float32Array) {
		__fillTransformedVertexCoords(transform, vertexData, 0, 0, width / __pixelRatio, height / __pixelRatio);
	}

	inline function __fillTransformedVertexCoords(transform:Matrix, vertexData:Float32Array, x:Float, y:Float, w:Float, h:Float) {
		var x1 = x + w;
		var y1 = y + h;

		vertexData[0] = transform.__transformX(x, y);
		vertexData[1] = transform.__transformY(x, y);

		vertexData[2] = transform.__transformX(x1, y);
		vertexData[3] = transform.__transformY(x1, y);

		vertexData[4] = transform.__transformX(x1, y1);
		vertexData[5] = transform.__transformY(x1, y1);

		vertexData[6] = transform.__transformX(x, y1);
		vertexData[7] = transform.__transformY(x, y1);
	}

	public function getVector(rect:Rectangle) {
		var pixels = getPixels(rect);
		var length = Std.int(pixels.length / 4);
		var result = new Vector<UInt>(length, true);

		for (i in 0...length) {
			result[i] = pixels.readUnsignedInt();
		}

		return result;
	}

	public function histogram(hRect:Rectangle = null) {
		var rect = hRect != null ? hRect : new Rectangle(0, 0, width, height);
		var pixels = getPixels(rect);
		var result = [for (i in 0...4) [for (j in 0...256) 0]];

		for (i in 0...pixels.length) {
			++result[i % 4][pixels.readUnsignedByte()];
		}

		return result;
	}

	public function hitTest(firstPoint:Point, firstAlphaThreshold:Int, secondObject:Object, secondBitmapDataPoint:Point = null, secondAlphaThreshold:Int = 1):Bool {
		if (!__readable)
			return false;

		if (Std.is(secondObject, Bitmap)) {
			secondObject = (cast secondObject : Bitmap).__bitmapData;
		}

		if (Std.is(secondObject, Point)) {
			var secondPoint:Point = cast secondObject;

			var x = Std.int(secondPoint.x - firstPoint.x);
			var y = Std.int(secondPoint.y - firstPoint.y);

			if (rect.contains(x, y)) {
				var pixel = getPixel32(x, y);

				if ((pixel >> 24) & 0xFF > firstAlphaThreshold) {
					return true;
				}
			}
		} else if (Std.is(secondObject, BitmapData)) {
			var secondBitmapData:BitmapData = cast secondObject;
			var x, y;

			if (secondBitmapDataPoint == null) {
				x = 0;
				y = 0;
			} else {
				x = Std.int(secondBitmapDataPoint.x - firstPoint.x);
				y = Std.int(secondBitmapDataPoint.y - firstPoint.y);
			}

			if (rect.contains(x, y)) {
				var hitRect = Rectangle.__pool.get();
				hitRect.setTo(x, y, Math.min(secondBitmapData.width, width - x), Math.min(secondBitmapData.height, height - y));

				var pixels = getPixels(hitRect);

				hitRect.offset(-x, -y);
				var testPixels = secondBitmapData.getPixels(hitRect);

				var length = Std.int(hitRect.width * hitRect.height);
				var pixel, testPixel;

				Rectangle.__pool.release(hitRect);

				for (i in 0...length) {
					pixel = pixels.readUnsignedInt();
					testPixel = testPixels.readUnsignedInt();

					if ((pixel >> 24) & 0xFF > firstAlphaThreshold && (testPixel >> 24) & 0xFF > secondAlphaThreshold) {
						return true;
					}
				}

				return false;
			}
		} else if (Std.is(secondObject, Rectangle)) {
			var secondRectangle = Rectangle.__pool.get();
			secondRectangle.copyFrom(cast secondObject);
			secondRectangle.offset(-firstPoint.x, -firstPoint.y);
			secondRectangle.__contract(0, 0, width, height);

			if (secondRectangle.width > 0 && secondRectangle.height > 0) {
				var pixels = getPixels(secondRectangle);
				var length = Std.int(pixels.length / 4);
				var pixel;

				for (i in 0...length) {
					pixel = pixels.readUnsignedInt();

					if ((pixel >> 24) & 0xFF > firstAlphaThreshold) {
						Rectangle.__pool.release(secondRectangle);
						return true;
					}
				}
			}

			Rectangle.__pool.release(secondRectangle);
		}

		return false;
	}

	public static function loadFromBytes(bytes:ByteArray):Future<BitmapData> {
		return Image.loadFromBytes(bytes).then(function(image) {
			return Future.withValue(BitmapData.fromImage(image));
		});
	}

	public static function loadFromFile(path:String):Future<BitmapData> {
		return Image.loadFromFile(path).then(function(image) {
			return Future.withValue(BitmapData.fromImage(image));
		});
	}

	public function lock():Void {}

	public function merge(sourceBitmapData:BitmapData, sourceRect:Rectangle, destPoint:Point, redMultiplier:UInt, greenMultiplier:UInt, blueMultiplier:UInt,
			alphaMultiplier:UInt):Void {
		if (!__readable || sourceBitmapData == null || !sourceBitmapData.__readable || sourceRect == null || destPoint == null)
			return;
		image.merge(sourceBitmapData.image, sourceRect.__toLimeRectangle(), destPoint.__toLimeVector2(), redMultiplier, greenMultiplier, blueMultiplier,
			alphaMultiplier);
	}

	public function noise(randomSeed:Int, low:Int = 0, high:Int = 255, channelOptions:Int = 7, grayScale:Bool = false):Void {
		if (!__readable)
			return;

		// Seeded Random Number Generator
		var rand:Void->Int = {
			function func():Int {
				randomSeed = randomSeed * 1103515245 + 12345;
				return Std.int(Math.abs(randomSeed / 65536)) % 32768;
			}
		};
		rand();

		// Range of values to value to.
		var range:Int = high - low;
		var data:ByteArray = new ByteArray();

		var redChannel:Bool = ((channelOptions & (1 << 0)) >> 0) == 1;
		var greenChannel:Bool = ((channelOptions & (1 << 1)) >> 1) == 1;
		var blueChannel:Bool = ((channelOptions & (1 << 2)) >> 2) == 1;
		var alphaChannel:Bool = ((channelOptions & (1 << 3)) >> 3) == 1;

		for (y in 0...height) {
			for (x in 0...width) {
				// Default channel colours if all channel options are false.
				var red:Int = 0;
				var blue:Int = 0;
				var green:Int = 0;
				var alpha:Int = 255;

				if (grayScale) {
					red = green = blue = low + (rand() % range);
					alpha = 255;
				} else {
					if (redChannel)
						red = low + (rand() % range);
					if (greenChannel)
						green = low + (rand() % range);
					if (blueChannel)
						blue = low + (rand() % range);
					if (alphaChannel)
						alpha = low + (rand() % range);
				}

				var rgb:Int = alpha;
				rgb = (rgb << 8) + red;
				rgb = (rgb << 8) + green;
				rgb = (rgb << 8) + blue;

				setPixel32(x, y, rgb);
			}
		}
	}

	public function paletteMap(sourceBitmapData:BitmapData, sourceRect:Rectangle, destPoint:Point, redArray:Array<Int> = null, greenArray:Array<Int> = null,
			blueArray:Array<Int> = null, alphaArray:Array<Int> = null):Void {
		var sw:Int = Std.int(sourceRect.width);
		var sh:Int = Std.int(sourceRect.height);

		var pixels = sourceBitmapData.getPixels(sourceRect);

		var pixelValue:Int, r:Int, g:Int, b:Int, a:Int, color:Int;

		for (i in 0...(sh * sw)) {
			pixelValue = pixels.readUnsignedInt();

			a = (alphaArray == null) ? pixelValue & 0xFF000000 : alphaArray[(pixelValue >> 24) & 0xFF];
			r = (redArray == null) ? pixelValue & 0x00FF0000 : redArray[(pixelValue >> 16) & 0xFF];
			g = (greenArray == null) ? pixelValue & 0x0000FF00 : greenArray[(pixelValue >> 8) & 0xFF];
			b = (blueArray == null) ? pixelValue & 0x000000FF : blueArray[(pixelValue) & 0xFF];

			color = a + r + g + b;

			pixels.position = i * 4;
			pixels.writeUnsignedInt(color);
		}

		pixels.position = 0;
		var destRect = Rectangle.__pool.get();
		destRect.setTo(destPoint.x, destPoint.y, sw, sh);
		setPixels(destRect, pixels);
		Rectangle.__pool.release(destRect);
	}

	public function perlinNoise(baseX:Float, baseY:Float, numOctaves:UInt, randomSeed:Int, stitch:Bool, fractalNoise:Bool, channelOptions:UInt = 7, grayScale:Bool = false, offsets:Array<Point> = null):Void {
		if (!__readable)
			return;
		var noise = new PerlinNoise(randomSeed, numOctaves, 0.01);
		noise.fill(this, baseX, baseY, 0);
	}

	public function scroll(x:Int, y:Int):Void {
		if (!__readable)
			return;
		image.scroll(x, y);
	}

	public function setPixel(x:Int, y:Int, color:Int):Void {
		if (!__readable)
			return;
		image.setPixel(x, y, color, ARGB32);
	}

	public function setPixel32(x:Int, y:Int, color:Int):Void {
		if (!__readable)
			return;
		image.setPixel32(x, y, color, ARGB32);
	}

	public function setPixels(rect:Rectangle, byteArray:ByteArray):Void {
		if (!__readable || rect == null)
			return;

		var length = (rect.width * rect.height * 4);
		if (byteArray.bytesAvailable < length)
			throw new Error("End of file was encountered.", 2030);

		image.setPixels(rect.__toLimeRectangle(), byteArray, ARGB32, byteArray.endian);
	}

	public function setVector(rect:Rectangle, inputVector:Vector<UInt>) {
		var byteArray = new ByteArray();
		byteArray.length = inputVector.length * 4;

		for (color in inputVector) {
			byteArray.writeUnsignedInt(color);
		}

		byteArray.position = 0;
		setPixels(rect, byteArray);
	}

	public function threshold(sourceBitmapData:BitmapData, sourceRect:Rectangle, destPoint:Point, operation:String, threshold:Int, color:Int = 0x00000000,
			mask:Int = 0xFFFFFFFF, copySource:Bool = false):Int {
		if (sourceBitmapData == null
			|| sourceRect == null
			|| destPoint == null
			|| sourceRect.x > sourceBitmapData.width
			|| sourceRect.y > sourceBitmapData.height
			|| destPoint.x > width
			|| destPoint.y > height)
			return 0;

		return image.threshold(sourceBitmapData.image, sourceRect.__toLimeRectangle(), destPoint.__toLimeVector2(), operation, threshold, color, mask,
			copySource, ARGB32);
	}

	public function unlock(changeRect:Rectangle = null):Void {}

	function __cleanup() {
	}

	private function __draw(source:IBitmapDrawable, matrix:Matrix, smoothing:Bool, clipRect:Null<Rectangle>, clearRenderDirty:Bool, blendMode:Null<BlendMode>) {
		ImageCanvasUtil.convertToCanvas(image);

		var renderSession = new CanvasRenderSession(image.__srcContext, clearRenderDirty, __pixelRatio, smoothing);
		renderSession.blendModeManager.setBlendMode(blendMode);

		image.__srcContext.save();

		CanvasSmoothing.setEnabled(image.__srcContext, smoothing);
		var matrixCache = Matrix.__pool.get();
		matrixCache.copyFrom(source.__worldTransform);
		var cacheWorldAlpha = source.__worldAlpha;
		var cacheAlpha = source.__alpha;
		var cacheVisible = source.__visible;
		var cacheIsMask = source.__isMask;
		source.__alpha = 1;
		source.__visible = true;
		source.__isMask = false;
		source.__overrideTransforms(matrix);
		source.__updateChildren(false);
		source.__renderCanvas(renderSession);
		source.__alpha = cacheAlpha;
		source.__visible = cacheVisible;
		source.__isMask = cacheIsMask;
		source.__overrideTransforms(matrixCache);
		Matrix.__pool.release(matrixCache);
		source.__updateChildren(true);
		source.__worldAlpha = cacheWorldAlpha;

		image.__srcContext.restore();

		image.__srcImageData = null;
		image.data = null;
		image.dirty = true;
		image.version++;
	}

	function __fromImage(image:Image) {
		if (image != null) {
			this.image = image;

			width = image.width;
			height = image.height;
			rect = new Rectangle(0, 0, image.width, image.height);

			__readable = true;
			__isValid = true;
		}
	}

	private function __getBounds(rect:Rectangle, matrix:Matrix):Void {
		var bounds = Rectangle.__pool.get();
		this.rect.__transform(bounds, matrix);
		rect.__expand(bounds.x, bounds.y, bounds.width, bounds.height);
		Rectangle.__pool.release(bounds);
	}

	private function __prepareImage()
		return image != null;

	private function __loadFromFile(path:String):Future<BitmapData> {
		return Image.loadFromFile(path).then(function(image) {
			__fromImage(image);
			return Future.withValue(this);
		});
	}

	function __canBeDrawnToCanvas():Bool {
		return image != null;
	}

	function __drawToCanvas(context:CanvasRenderingContext2D, transform:Matrix, roundPixels:Bool, pixelRatio:Float, scrollRect:Rectangle,
			useScrollRectCoords:Bool):Void {
		if (image.type == DATA) {
			ImageCanvasUtil.convertToCanvas(image);
		}

		var scale = pixelRatio / this.__pixelRatio; // Bitmaps can have different pixelRatio than display, therefore we need to scale them properly

		if (roundPixels) {
			context.setTransform(transform.a * scale, transform.b, transform.c, transform.d * scale, Math.round(transform.tx * pixelRatio),
				Math.round(transform.ty * pixelRatio));
		} else {
			context.setTransform(transform.a * scale, transform.b, transform.c, transform.d * scale, transform.tx * pixelRatio, transform.ty * pixelRatio);
		}

		if (scrollRect == null) {
			context.drawImage(image.src, 0, 0);
		} else {
			var dx, dy;
			if (useScrollRectCoords) {
				dx = scrollRect.x;
				dy = scrollRect.y;
			} else {
				dx = dy = 0;
			}

			context.drawImage(image.src, scrollRect.x, scrollRect.y, scrollRect.width, scrollRect.height, dx, dy, scrollRect.width, scrollRect.height);
		}
	}

	private function __renderCanvas(renderSession:CanvasRenderSession):Void {
		if (!__readable)
			return;

		renderSession.context.globalAlpha = 1;
		__drawToCanvas(renderSession.context, __worldTransform, false, renderSession.pixelRatio, null, false);
	}

	private function __renderCanvasMask(renderSession:CanvasRenderSession):Void {}

	function __resize(width:Int, height:Int) {
		this.width = width;
		this.height = height;
		this.rect.width = width;
		this.rect.height = height;
	}

	function __updateChildren(transformOnly:Bool) {}

	function __overrideTransforms(overrideTransform:Matrix) {
		if (overrideTransform == null) {
			__worldTransform.identity();
		} else {
			__worldTransform.copyFrom(overrideTransform);
		}
	}
}

/**
	Result structure for `BitmapData.__getTextureRegion`.
	Can only be used for reading after calling `__getTextureRegion`.
**/
@:publicFields class TextureRegionResult {
	/** a single helper instance that can be used for returning results that are immediately processed */
	public static final helperInstance = new TextureRegionResult();

	var u0:Float;
	var v0:Float;
	var u1:Float;
	var v1:Float;
	var u2:Float;
	var v2:Float;
	var u3:Float;
	var v3:Float;

	function new() {}
}
