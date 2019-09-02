package openfl._internal.graphics.utils;

import haxe.io.Bytes;
import openfl._internal.graphics.Image;
import openfl._internal.graphics.PixelFormat;
import openfl._internal.graphics.color.ARGB;
import openfl._internal.graphics.color.RGBA;
import openfl.geom.ColorTransform;
import openfl.geom.Rectangle;
import openfl.geom.Point;
import openfl.utils.Endian;
import openfl.display.BitmapDataChannel;
import js.lib.Uint8Array;
import js.lib.Float32Array;

@:access(openfl._internal.graphics.color.RGBA)
@:access(openfl._internal.graphics.Image)
class ImageDataUtil {
	static var __tempColorMatrix:ColorMatrix;

	static function __toColorMatrix(colorTransform:ColorTransform):ColorMatrix {
		if (__tempColorMatrix == null) {
			__tempColorMatrix = new js.lib.Float32Array(20);
		}

		__tempColorMatrix[0] = colorTransform.redMultiplier;
		__tempColorMatrix[4] = colorTransform.redOffset / 255;
		__tempColorMatrix[6] = colorTransform.greenMultiplier;
		__tempColorMatrix[9] = colorTransform.greenOffset / 255;
		__tempColorMatrix[12] = colorTransform.blueMultiplier;
		__tempColorMatrix[14] = colorTransform.blueOffset / 255;
		__tempColorMatrix[18] = colorTransform.alphaMultiplier;
		__tempColorMatrix[19] = colorTransform.alphaOffset / 255;

		return __tempColorMatrix;
	}

	public static function colorTransform(image:Image, rect:Rectangle, colorTransform:ColorTransform):Void {
		var data = image.data;
		if (data == null)
			return;

		var dataView = new ImageDataView(image, rect);

		var colorMatrix = __toColorMatrix(colorTransform);
		var alphaTable = colorMatrix.getAlphaTable();
		var redTable = colorMatrix.getRedTable();
		var greenTable = colorMatrix.getGreenTable();
		var blueTable = colorMatrix.getBlueTable();

		var row, offset, pixel:RGBA;

		for (y in 0...dataView.height) {
			row = dataView.row(y);

			for (x in 0...dataView.width) {
				offset = row + (x * 4);

				pixel.readUInt8(data, offset);
				pixel.set(redTable[pixel.r], greenTable[pixel.g], blueTable[pixel.b], alphaTable[pixel.a]);
				pixel.writeUInt8(data, offset);
			}
		}

		image.dirty = true;
		image.version++;
	}

	public static function copyChannel(image:Image, sourceImage:Image, sourceRect:Rectangle, destPoint:Point, sourceChannel:BitmapDataChannel, destChannel:BitmapDataChannel) {
		var destIdx = switch (destChannel) {
			case RED: 0;
			case GREEN: 1;
			case BLUE: 2;
			case ALPHA: 3;
		}

		var srcIdx = switch (sourceChannel) {
			case RED: 0;
			case GREEN: 1;
			case BLUE: 2;
			case ALPHA: 3;
		}

		var srcData = sourceImage.data;
		var destData = image.data;

		if (srcData == null || destData == null)
			return;

		var srcView = new ImageDataView(sourceImage, sourceRect);
		var destView = new ImageDataView(image, new Rectangle(destPoint.x, destPoint.y, srcView.width, srcView.height));

		var srcPosition,
			destPosition,
			srcPixel:RGBA,
			destPixel:RGBA,
			value = 0;

		for (y in 0...destView.height) {
			srcPosition = srcView.row(y);
			destPosition = destView.row(y);

			for (x in 0...destView.width) {
				srcPixel.readUInt8(srcData, srcPosition);
				destPixel.readUInt8(destData, destPosition);

				switch (srcIdx) {
					case 0:
						value = srcPixel.r;
					case 1:
						value = srcPixel.g;
					case 2:
						value = srcPixel.b;
					case 3:
						value = srcPixel.a;
				}

				switch (destIdx) {
					case 0:
						destPixel.r = value;
					case 1:
						destPixel.g = value;
					case 2:
						destPixel.b = value;
					case 3:
						destPixel.a = value;
				}

				destPixel.writeUInt8(destData, destPosition);

				srcPosition += 4;
				destPosition += 4;
			}
		}

		image.dirty = true;
		image.version++;
	}

	public static function copyPixels(image:Image, sourceImage:Image, sourceRect:Rectangle, destPoint:Point, alphaImage:Image, alphaPoint:Point, mergeAlpha:Bool):Void {
		if (image.width == sourceImage.width
			&& image.height == sourceImage.height
			&& sourceRect.width == sourceImage.width
			&& sourceRect.height == sourceImage.height
			&& sourceRect.x == 0
			&& sourceRect.y == 0
			&& destPoint.x == 0
			&& destPoint.y == 0
			&& alphaImage == null
			&& alphaPoint == null
			&& mergeAlpha == false) {
			image.data.set(sourceImage.data);
		} else {
			var sourceData = sourceImage.data;
			var destData = image.data;

			if (sourceData == null || destData == null)
				return;

			var sourceView = new ImageDataView(sourceImage, sourceRect);
			var destRect = new Rectangle(destPoint.x, destPoint.y, sourceView.width, sourceView.height);
			var destView = new ImageDataView(image, destRect);

			var sourcePosition, destPosition;
			var sourceAlpha, destAlpha, oneMinusSourceAlpha, blendAlpha;
			var sourcePixel:RGBA, destPixel:RGBA;

			var useAlphaImage = (alphaImage != null && alphaImage.transparent);
			var blend = (mergeAlpha || (useAlphaImage && !image.transparent));

			if (!useAlphaImage) {
				if (blend) {
					for (y in 0...destView.height) {
						sourcePosition = sourceView.row(y);
						destPosition = destView.row(y);

						for (x in 0...destView.width) {
							sourcePixel.readUInt8(sourceData, sourcePosition);
							destPixel.readUInt8(destData, destPosition);

							sourceAlpha = sourcePixel.a / 255.0;
							destAlpha = destPixel.a / 255.0;
							oneMinusSourceAlpha = 1 - sourceAlpha;
							blendAlpha = sourceAlpha + (destAlpha * oneMinusSourceAlpha);

							if (blendAlpha == 0) {
								destPixel = 0;
							} else {
								destPixel.r = __clamp[Math.round((sourcePixel.r * sourceAlpha + destPixel.r * destAlpha * oneMinusSourceAlpha) / blendAlpha)];
								destPixel.g = __clamp[Math.round((sourcePixel.g * sourceAlpha + destPixel.g * destAlpha * oneMinusSourceAlpha) / blendAlpha)];
								destPixel.b = __clamp[Math.round((sourcePixel.b * sourceAlpha + destPixel.b * destAlpha * oneMinusSourceAlpha) / blendAlpha)];
								destPixel.a = __clamp[Math.round(blendAlpha * 255.0)];
							}

							destPixel.writeUInt8(destData, destPosition);

							sourcePosition += 4;
							destPosition += 4;
						}
					}
				} else {
					for (y in 0...destView.height) {
						sourcePosition = sourceView.row(y);
						destPosition = destView.row(y);

						#if js
						// TODO: Is this faster on HTML5 than the normal copy method?
						destData.set(sourceData.subarray(sourcePosition, sourcePosition + destView.width * 4), destPosition);
						#else
						destData.buffer.blit(destPosition, sourceData.buffer, sourcePosition, destView.width * 4);
						#end
					}
				}
			} else {
				if (alphaPoint == null)
					alphaPoint = new Point();

				var alphaData = alphaImage.data;
				var alphaPosition, alphaPixel:RGBA;

				var alphaView = new ImageDataView(alphaImage, new Rectangle(alphaPoint.x, alphaPoint.y, alphaImage.width, alphaImage.height));
				alphaView.offset(sourceView.x, sourceView.y);

				destView.clip(Std.int(destPoint.x), Std.int(destPoint.y), alphaView.width, alphaView.height);

				if (blend) {
					for (y in 0...destView.height) {
						sourcePosition = sourceView.row(y);
						destPosition = destView.row(y);
						alphaPosition = alphaView.row(y);

						for (x in 0...destView.width) {
							sourcePixel.readUInt8(sourceData, sourcePosition);
							destPixel.readUInt8(destData, destPosition);
							alphaPixel.readUInt8(alphaData, alphaPosition);

							sourceAlpha = (alphaPixel.a / 255.0) * (sourcePixel.a / 255.0);

							if (sourceAlpha > 0) {
								destAlpha = destPixel.a / 255.0;
								oneMinusSourceAlpha = 1 - sourceAlpha;
								blendAlpha = sourceAlpha + (destAlpha * oneMinusSourceAlpha);

								destPixel.r = __clamp[Math.round((sourcePixel.r * sourceAlpha + destPixel.r * destAlpha * oneMinusSourceAlpha) / blendAlpha)];
								destPixel.g = __clamp[Math.round((sourcePixel.g * sourceAlpha + destPixel.g * destAlpha * oneMinusSourceAlpha) / blendAlpha)];
								destPixel.b = __clamp[Math.round((sourcePixel.b * sourceAlpha + destPixel.b * destAlpha * oneMinusSourceAlpha) / blendAlpha)];
								destPixel.a = __clamp[Math.round(blendAlpha * 255.0)];

								destPixel.writeUInt8(destData, destPosition);
							}

							sourcePosition += 4;
							destPosition += 4;
							alphaPosition += 4;
						}
					}
				} else {
					for (y in 0...destView.height) {
						sourcePosition = sourceView.row(y);
						destPosition = destView.row(y);
						alphaPosition = alphaView.row(y);

						for (x in 0...destView.width) {
							sourcePixel.readUInt8(sourceData, sourcePosition);
							alphaPixel.readUInt8(alphaData, alphaPosition);

							sourcePixel.a = Math.round(sourcePixel.a * (alphaPixel.a / 0xFF));
							sourcePixel.writeUInt8(destData, destPosition);

							sourcePosition += 4;
							destPosition += 4;
							alphaPosition += 4;
						}
					}
				}
			}
		}

		image.dirty = true;
		image.version++;
	}

	public static function fillRect(image:Image, rect:Rectangle, color:Int, format:PixelFormat):Void {
		var fillColor:RGBA;
		switch (format) {
			case ARGB32:
				fillColor = (color : ARGB);
			case RGBA32:
				fillColor = color;
		}

		if (!image.transparent) {
			fillColor.a = 0xFF;
		}

		var data = image.data;
		if (data == null)
			return;

		var dataView = new ImageDataView(image, rect);
		var row;

		for (y in 0...dataView.height) {
			row = dataView.row(y);

			for (x in 0...dataView.width) {
				fillColor.writeUInt8(data, row + (x * 4));
			}
		}

		image.dirty = true;
		image.version++;
	}

	public static function floodFill(image:Image, x:Int, y:Int, fillColor:RGBA):Void {
		var data = image.data;
		if (data == null)
			return;

		var hitColor:RGBA;
		hitColor.readUInt8(data, (y * (image.width * 4)) + (x * 4));

		if (!image.transparent) {
			fillColor.a = 0xFF;
			hitColor.a = 0xFF;
		}

		if (fillColor == hitColor)
			return;

		var dx = [0, -1, 1, 0];
		var dy = [-1, 0, 0, 1];

		var minX = 0;
		var minY = 0;
		var maxX = minX + image.width;
		var maxY = minY + image.height;

		var queue = new Array<Int>();
		queue.push(x);
		queue.push(y);

		var curPointX,
			curPointY,
			nextPointX,
			nextPointY,
			nextPointOffset,
			readColor:RGBA;

		while (queue.length > 0) {
			curPointY = queue.pop();
			curPointX = queue.pop();

			for (i in 0...4) {
				nextPointX = curPointX + dx[i];
				nextPointY = curPointY + dy[i];

				if (nextPointX < minX || nextPointY < minY || nextPointX >= maxX || nextPointY >= maxY) {
					continue;
				}

				nextPointOffset = (nextPointY * image.width + nextPointX) * 4;
				readColor.readUInt8(data, nextPointOffset);

				if (readColor == hitColor) {
					fillColor.writeUInt8(data, nextPointOffset);

					queue.push(nextPointX);
					queue.push(nextPointY);
				}
			}
		}

		image.dirty = true;
		image.version++;
	}

	public static function gaussianBlur(image:Image, sourceImage:Image, sourceRect:Rectangle, destPoint:Point, blurX:Float = 4, blurY:Float = 4,
			quality:Int = 1, strength:Float = 1):Image {
		// TODO: Support sourceRect better, do not modify sourceImage, create C++ implementation for native

		var boxesForGauss = function(sigma:Float, n:Int):Array<Float> {
			var wIdeal = Math.sqrt((12 * sigma * sigma / n) + 1); // Ideal averaging filter width
			var wl = Math.floor(wIdeal);
			if (wl % 2 == 0)
				wl--;
			var wu = wl + 2;

			var mIdeal = (12 * sigma * sigma - n * wl * wl - 4 * n * wl - 3 * n) / (-4 * wl - 4);
			var m = Math.round(mIdeal);
			var sizes:Array<Float> = [];
			for (i in 0...n)
				sizes.push(i < m ? wl : wu);

			return sizes;
		}

		var boxBlurH = function(imgA:Uint8Array, imgB:Uint8Array, w:Int, h:Int, r:Int, off:Int):Void {
			var iarr = 1 / (r + r + 1);
			for (i in 0...h) {
				var ti = i * w, li = ti, ri = ti + r;
				var fv = imgA[ti * 4 + off], lv = imgA[(ti + w - 1) * 4 + off], val = (r + 1) * fv;

				for (j in 0...r)
					val += imgA[(ti + j) * 4 + off];

				for (j in 0...r + 1) {
					val += imgA[ri * 4 + off] - fv;
					imgB[ti * 4 + off] = Math.round(val * iarr);
					ri++;
					ti++;
				}

				for (j in r + 1...w - r) {
					val += imgA[ri * 4 + off] - imgA[li * 4 + off];
					imgB[ti * 4 + off] = Math.round(val * iarr);
					ri++;
					li++;
					ti++;
				}

				for (j in w - r...w) {
					val += lv - imgA[li * 4 + off];
					imgB[ti * 4 + off] = Math.round(val * iarr);
					li++;
					ti++;
				}
			}
		}

		var boxBlurT = function(imgA:Uint8Array, imgB:Uint8Array, w:Int, h:Int, r:Int, off:Int):Void {
			var iarr = 1 / (r + r + 1);
			var ws = w * 4;
			for (i in 0...w) {
				var ti = i * 4 + off, li = ti, ri = ti + (r * ws);
				var fv = imgA[ti], lv = imgA[ti + (ws * (h - 1))], val = (r + 1) * fv;
				for (j in 0...r)
					val += imgA[ti + j * ws];

				for (j in 0...r + 1) {
					val += imgA[ri] - fv;
					imgB[ti] = Math.round(val * iarr);
					ri += ws;
					ti += ws;
				}

				for (j in r + 1...h - r) {
					val += imgA[ri] - imgA[li];
					imgB[ti] = Math.round(val * iarr);
					li += ws;
					ri += ws;
					ti += ws;
				}

				for (j in h - r...h) {
					val += lv - imgA[li];
					imgB[ti] = Math.round(val * iarr);
					li += ws;
					ti += ws;
				}
			}
		}

		var boxBlur = function(imgA:Uint8Array, imgB:Uint8Array, w:Int, h:Int, bx:Float, by:Float):Void {
			for (i in 0...imgA.length)
				imgB[i] = imgA[i];

			boxBlurH(imgB, imgA, w, h, Std.int(bx), 0);
			boxBlurH(imgB, imgA, w, h, Std.int(bx), 1);
			boxBlurH(imgB, imgA, w, h, Std.int(bx), 2);
			boxBlurH(imgB, imgA, w, h, Std.int(bx), 3);

			boxBlurT(imgA, imgB, w, h, Std.int(by), 0);
			boxBlurT(imgA, imgB, w, h, Std.int(by), 1);
			boxBlurT(imgA, imgB, w, h, Std.int(by), 2);
			boxBlurT(imgA, imgB, w, h, Std.int(by), 3);
		}

		var imgB = image.getData();
		var imgA = sourceImage.getData();
		var w = Std.int(sourceRect.width);
		var h = Std.int(sourceRect.height);
		var bx = Std.int(blurX);
		var by = Std.int(blurY);
		var oX = Std.int(destPoint.x);
		var oY = Std.int(destPoint.y);

		var n = (quality * 2) - 1;
		var rng = Math.pow(2, quality) * 0.125;

		var bxs = boxesForGauss(bx * rng, n);
		var bys = boxesForGauss(by * rng, n);
		var offset:Int = Std.int((w * oY + oX) * 4);

		boxBlur(imgA, imgB, w, h, (bxs[0] - 1) / 2, (bys[0] - 1) / 2);
		var bIndex:Int = 1;
		for (i in 0...Std.int(n / 2)) {
			boxBlur(imgB, imgA, w, h, (bxs[bIndex] - 1) / 2, (bys[bIndex] - 1) / 2);
			boxBlur(imgA, imgB, w, h, (bxs[bIndex + 1] - 1) / 2, (bys[bIndex + 1] - 1) / 2);

			bIndex += 2;
		}

		var x:Int;
		var y:Int;
		if (offset <= 0) {
			y = 0;
			while (y < h) {
				x = 0;
				while (x < w) {
					translatePixel(imgB, sourceImage.rect, image.rect, destPoint, x, y, strength);
					x += 1;
				}
				y += 1;
			}
		} else {
			y = h - 1;
			while (y >= 0) {
				x = w - 1;
				while (x >= 0) {
					translatePixel(imgB, sourceImage.rect, image.rect, destPoint, x, y, strength);
					x -= 1;
				}
				y -= 1;
			}
		}

		image.dirty = true;
		image.version++;
		sourceImage.dirty = true;
		sourceImage.version++;

		if (imgB == image.getData())
			return image;
		return sourceImage;
	}

	/**
	 * Returns: the offset for translated coordinate in the source image or -1 if the source the coordinate out of the source or destination bounds
	 * Note: destX and destY should be valid coordinates
	**/
	inline private static function calculateSourceOffset(sourceRect:Rectangle, destPoint:Point, destX:Int, destY:Int):Int {
		var sourceX:Int = destX - Std.int(destPoint.x);
		var sourceY:Int = destY - Std.int(destPoint.y);
		return if (sourceX < 0 || sourceY < 0 || sourceX >= sourceRect.width || sourceY >= sourceRect.height)
			-1
		else
			4 * (sourceY * Std.int(sourceRect.width) + sourceX);
	}

	inline private static function translatePixel(imgB:Uint8Array, sourceRect:Rectangle, destRect:Rectangle, destPoint:Point, destX:Int, destY:Int,
			strength:Float) {
		var d = 4 * (destY * Std.int(destRect.width) + destX);
		var s = calculateSourceOffset(sourceRect, destPoint, destX, destY);
		if (s < 0) {
			imgB[d] = imgB[d + 1] = imgB[d + 2] = imgB[d + 3] = 0;
		} else {
			imgB[d] = imgB[s];
			imgB[d + 1] = imgB[s + 1];
			imgB[d + 2] = imgB[s + 2];

			var a = Std.int(imgB[s + 3] * strength);
			imgB[d + 3] = a < 0 ? 0 : (a > 255 ? 255 : a);
		}
	}

	public static function getColorBoundsRect(image:Image, mask:Int, color:Int, findColor:Bool, format:PixelFormat):Rectangle {
		var left = image.width + 1;
		var right = 0;
		var top = image.height + 1;
		var bottom = 0;

		var _color:RGBA, _mask:RGBA;

		switch (format) {
			case ARGB32:
				_color = (color : ARGB);
				_mask = (mask : ARGB);
			case RGBA32:
				_color = color;
				_mask = mask;
		}

		if (!image.transparent) {
			_color.a = 0xFF;
			_mask.a = 0xFF;
		}

		var pixel, hit;

		for (x in 0...image.width) {
			hit = false;

			for (y in 0...image.height) {
				pixel = image.getPixel32(x, y, RGBA32);
				hit = findColor ? (pixel & _mask) == _color : (pixel & _mask) != _color;

				if (hit) {
					if (x < left)
						left = x;
					break;
				}
			}

			if (hit) {
				break;
			}
		}

		var ix;

		for (x in 0...image.width) {
			ix = (image.width - 1) - x;
			hit = false;

			for (y in 0...image.height) {
				pixel = image.getPixel32(ix, y, RGBA32);
				hit = findColor ? (pixel & _mask) == _color : (pixel & _mask) != _color;

				if (hit) {
					if (ix > right)
						right = ix;
					break;
				}
			}

			if (hit) {
				break;
			}
		}

		for (y in 0...image.height) {
			hit = false;

			for (x in 0...image.width) {
				pixel = image.getPixel32(x, y, RGBA32);
				hit = findColor ? (pixel & _mask) == _color : (pixel & _mask) != _color;

				if (hit) {
					if (y < top)
						top = y;
					break;
				}
			}

			if (hit) {
				break;
			}
		}

		var iy;

		for (y in 0...image.height) {
			iy = (image.height - 1) - y;
			hit = false;

			for (x in 0...image.width) {
				pixel = image.getPixel32(x, iy, RGBA32);
				hit = findColor ? (pixel & _mask) == _color : (pixel & _mask) != _color;

				if (hit) {
					if (iy > bottom)
						bottom = iy;
					break;
				}
			}

			if (hit) {
				break;
			}
		}

		var w = right - left;
		var h = bottom - top;

		if (w > 0)
			w++;
		if (h > 0)
			h++;

		if (w < 0)
			w = 0;
		if (h < 0)
			h = 0;

		if (left == right)
			w = 1;
		if (top == bottom)
			h = 1;

		if (left > image.width)
			left = 0;
		if (top > image.height)
			top = 0;

		return new Rectangle(left, top, w, h);
	}

	public static function getPixel(image:Image, x:Int, y:Int, format:PixelFormat):Int {
		var pixel:RGBA;

		pixel.readUInt8(image.data, (4 * y * image.width + x * 4));
		pixel.a = 0;

		switch (format) {
			case ARGB32:
				return (pixel : ARGB);
			case RGBA32:
				return pixel;
		}
	}

	public static function getPixel32(image:Image, x:Int, y:Int, format:PixelFormat):Int {
		var pixel:RGBA;

		pixel.readUInt8(image.data, (4 * y * image.width + x * 4));

		switch (format) {
			case ARGB32:
				return (pixel : ARGB);
			case RGBA32:
				return pixel;
		}
	}

	public static function getPixels(image:Image, rect:Rectangle, format:PixelFormat):Bytes {
		if (image.data == null)
			return null;

		var length = Std.int(rect.width * rect.height);
		var bytes = Bytes.alloc(length * 4);

		var data = image.data;

		var dataView = new ImageDataView(image, rect);
		var position, pixel:RGBA;
		var destPosition = 0;

		for (y in 0...dataView.height) {
			position = dataView.row(y);

			for (x in 0...dataView.width) {
				pixel.readUInt8(data, position);

				switch (format) {
					case ARGB32:
						var argb:ARGB = pixel;
						pixel = (argb : Int);
					case RGBA32:
				}

				bytes.set(destPosition++, pixel.r);
				bytes.set(destPosition++, pixel.g);
				bytes.set(destPosition++, pixel.b);
				bytes.set(destPosition++, pixel.a);

				position += 4;
			}
		}

		return bytes;
	}

	public static function merge(image:Image, sourceImage:Image, sourceRect:Rectangle, destPoint:Point, redMultiplier:Int, greenMultiplier:Int, blueMultiplier:Int, alphaMultiplier:Int) {
		if (image.data == null || sourceImage.data == null)
			return;

		var sourceView = new ImageDataView(sourceImage, sourceRect);
		var destView = new ImageDataView(image, new Rectangle(destPoint.x, destPoint.y, sourceView.width, sourceView.height));

		var sourceData = sourceImage.data;
		var destData = image.data;

		var sourcePosition, destPosition, sourcePixel:RGBA, destPixel:RGBA;

		for (y in 0...destView.height) {
			sourcePosition = sourceView.row(y);
			destPosition = destView.row(y);

			for (x in 0...destView.width) {
				sourcePixel.readUInt8(sourceData, sourcePosition);
				destPixel.readUInt8(destData, destPosition);

				destPixel.r = Std.int(((sourcePixel.r * redMultiplier) + (destPixel.r * (256 - redMultiplier))) / 256);
				destPixel.g = Std.int(((sourcePixel.g * greenMultiplier) + (destPixel.g * (256 - greenMultiplier))) / 256);
				destPixel.b = Std.int(((sourcePixel.b * blueMultiplier) + (destPixel.b * (256 - blueMultiplier))) / 256);
				destPixel.a = Std.int(((sourcePixel.a * alphaMultiplier) + (destPixel.a * (256 - alphaMultiplier))) / 256);

				destPixel.writeUInt8(destData, destPosition);

				sourcePosition += 4;
				destPosition += 4;
			}
		}

		image.dirty = true;
		image.version++;
	}

	public static function setPixel(image:Image, x:Int, y:Int, color:Int, format:PixelFormat):Void {
		var pixel:RGBA;

		switch (format) {
			case ARGB32:
				pixel = (color : ARGB);
			case RGBA32:
				pixel = color;
		}

		// TODO: Write only RGB instead?

		var source = new RGBA();
		source.readUInt8(image.data, (4 * y * image.width + x * 4));

		pixel.a = source.a;
		pixel.writeUInt8(image.data, (4 * y * image.width + x * 4));

		image.dirty = true;
		image.version++;
	}

	public static function setPixel32(image:Image, x:Int, y:Int, color:Int, format:PixelFormat):Void {
		var pixel:RGBA;
		switch (format) {
			case ARGB32:
				pixel = (color : ARGB);
			case RGBA32:
				pixel = color;
		}

		if (!image.transparent)
			pixel.a = 0xFF;
		pixel.writeUInt8(image.data, (4 * y * image.width + x * 4));

		image.dirty = true;
		image.version++;
	}

	public static function setPixels(image:Image, rect:Rectangle, bytes:Bytes, format:PixelFormat, endian:Endian):Void {
		if (image.data == null)
			return;

		var data = image.data;
		var dataView = new ImageDataView(image, rect);
		var row, color, pixel:RGBA;
		var transparent = image.transparent;
		var dataPosition = 0;
		var littleEndian = (endian != BIG_ENDIAN);

		for (y in 0...dataView.height) {
			row = dataView.row(y);

			for (x in 0...dataView.width) {
				if (littleEndian) {
					color = bytes.getInt32(dataPosition); // can this be trusted on big endian systems?
				} else {
					color = bytes.get(dataPosition + 3) | (bytes.get(dataPosition + 2) << 8) | (bytes.get(dataPosition +
						1) << 16) | (bytes.get(dataPosition) << 24);
				}

				dataPosition += 4;

				switch (format) {
					case ARGB32:
						pixel = (color : ARGB);
					case RGBA32:
						pixel = color;
				}

				if (!transparent)
					pixel.a = 0xFF;
				pixel.writeUInt8(data, row + (x * 4));
			}
		}

		image.dirty = true;
		image.version++;
	}

	public static function threshold(image:Image, sourceImage:Image, sourceRect:Rectangle, destPoint:Point, operation:String, threshold:Int, color:Int,
			mask:Int, copySource:Bool, format:PixelFormat):Int {
		var _color:RGBA, _mask:RGBA, _threshold:RGBA;

		switch (format) {
			case ARGB32:
				_color = (color : ARGB);
				_mask = (mask : ARGB);
				_threshold = (threshold : ARGB);

			case RGBA32:
				_color = color;
				_mask = mask;
				_threshold = threshold;
		}

		var _operation = switch (operation) {
			case "!=": NOT_EQUALS;
			case "==": EQUALS;
			case "<": LESS_THAN;
			case "<=": LESS_THAN_OR_EQUAL_TO;
			case ">": GREATER_THAN;
			case ">=": GREATER_THAN_OR_EQUAL_TO;
			default: return 0;
		}

		var srcData = sourceImage.data;
		var destData = image.data;

		if (srcData == null || destData == null)
			return 0;

		var hits = 0;

		var srcView = new ImageDataView(sourceImage, sourceRect);
		var destView = new ImageDataView(image, new Rectangle(destPoint.x, destPoint.y, srcView.width, srcView.height));

		var srcPosition,
			destPosition,
			srcPixel:RGBA,
			destPixel:RGBA,
			pixelMask:UInt,
			test:Bool,
			value:Int;

		for (y in 0...destView.height) {
			srcPosition = srcView.row(y);
			destPosition = destView.row(y);

			for (x in 0...destView.width) {
				srcPixel.readUInt8(srcData, srcPosition);

				pixelMask = srcPixel & _mask;

				value = __pixelCompare(pixelMask, _threshold);

				test = switch (_operation) {
					case NOT_EQUALS: (value != 0);
					case EQUALS: (value == 0);
					case LESS_THAN: (value == -1);
					case LESS_THAN_OR_EQUAL_TO: (value == 0 || value == -1);
					case GREATER_THAN: (value == 1);
					case GREATER_THAN_OR_EQUAL_TO: (value == 0 || value == 1);
					default: false;
				}

				if (test) {
					_color.writeUInt8(destData, destPosition);
					hits++;
				} else if (copySource) {
					srcPixel.writeUInt8(destData, destPosition);
				}

				srcPosition += 4;
				destPosition += 4;
			}
		}

		if (hits > 0) {
			image.dirty = true;
			image.version++;
		}

		return hits;
	}

	private static inline function __pixelCompare(n1:UInt, n2:UInt):Int {
		var tmp1:UInt;
		var tmp2:UInt;

		tmp1 = (n1 >> 24) & 0xFF;
		tmp2 = (n2 >> 24) & 0xFF;

		if (tmp1 != tmp2) {
			return (tmp1 > tmp2 ? 1 : -1);
		} else {
			tmp1 = (n1 >> 16) & 0xFF;
			tmp2 = (n2 >> 16) & 0xFF;

			if (tmp1 != tmp2) {
				return (tmp1 > tmp2 ? 1 : -1);
			} else {
				tmp1 = (n1 >> 8) & 0xFF;
				tmp2 = (n2 >> 8) & 0xFF;

				if (tmp1 != tmp2) {
					return (tmp1 > tmp2 ? 1 : -1);
				} else {
					tmp1 = n1 & 0xFF;
					tmp2 = n2 & 0xFF;

					if (tmp1 != tmp2) {
						return (tmp1 > tmp2 ? 1 : -1);
					} else {
						return 0;
					}
				}
			}
		}
	}


	static var __clamp = {
		var a = new Uint8Array(0xFF + 0xFF);
		for (i in 0...0xFF) {
			a[i] = i;
		}
		for (i in 0xFF...(0xFF + 0xFF + 1)) {
			a[i] = 0xFF;
		}
		a;
	};
}

private class ImageDataView {
	public var x(default, null):Int;
	public var y(default, null):Int;
	public var height(default, null):Int;
	public var width(default, null):Int;

	private var byteOffset:Int;
	private var image:Image;
	private var rect:Rectangle;
	private var stride:Int;

	public function new(image:Image, rect:Rectangle = null) {
		this.image = image;

		if (rect == null) {
			this.rect = image.rect;
		} else {
			if (rect.x < 0)
				rect.x = 0;
			if (rect.y < 0)
				rect.y = 0;
			if (rect.x + rect.width > image.width)
				rect.width = image.width - rect.x;
			if (rect.y + rect.height > image.height)
				rect.height = image.height - rect.y;
			if (rect.width < 0)
				rect.width = 0;
			if (rect.height < 0)
				rect.height = 0;
			this.rect = rect;
		}

		stride = image.stride;

		__update();
	}

	public function clip(x:Int, y:Int, width:Int, height:Int):Void {
		rect.__contract(x, y, width, height);
		__update();
	}


	public function offset(x:Int, y:Int):Void {
		if (x < 0) {
			rect.x += x;
			if (rect.x < 0)
				rect.x = 0;
		} else {
			rect.x += x;
			rect.width -= x;
		}

		if (y < 0) {
			rect.y += y;
			if (rect.y < 0)
				rect.y = 0;
		} else {
			rect.y += y;
			rect.height -= y;
		}

		__update();
	}

	public inline function row(y:Int):Int {
		return byteOffset + stride * y;
	}

	private function __update():Void {
		this.x = Math.ceil(rect.x);
		this.y = Math.ceil(rect.y);
		this.width = Math.floor(rect.width);
		this.height = Math.floor(rect.height);
		byteOffset = (stride * this.y) + (this.x * 4);
	}
}

private enum abstract ThresholdOperation(Int) {
	var NOT_EQUALS = 0;
	var EQUALS = 1;
	var LESS_THAN = 2;
	var LESS_THAN_OR_EQUAL_TO = 3;
	var GREATER_THAN = 4;
	var GREATER_THAN_OR_EQUAL_TO = 5;
}

private abstract ColorMatrix(Float32Array) from Float32Array to Float32Array {
	private static var __alphaTable:Uint8Array;
	private static var __blueTable:Uint8Array;
	private static var __greenTable:Uint8Array;
	private static var __identity = [
		1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0
	];
	private static var __redTable:Uint8Array;

	public var alphaMultiplier(get, set):Float;
	public var alphaOffset(get, set):Float;
	public var blueMultiplier(get, set):Float;
	public var blueOffset(get, set):Float;
	public var color(get, set):Int;
	public var greenMultiplier(get, set):Float;
	public var greenOffset(get, set):Float;
	public var redMultiplier(get, set):Float;
	public var redOffset(get, set):Float;

	public function new(data:Float32Array = null) {
		if (data != null && data.length == 20) {
			this = data;
		} else {
			this = new Float32Array(__identity);
		}
	}

	public function clone():ColorMatrix {
		return new ColorMatrix(new Float32Array(this));
	}

	public function concat(second:ColorMatrix):Void {
		redMultiplier += second.redMultiplier;
		greenMultiplier += second.greenMultiplier;
		blueMultiplier += second.blueMultiplier;
		alphaMultiplier += second.alphaMultiplier;
	}

	public function copyFrom(other:ColorMatrix):Void {
		this.set(other);
	}

	public function identity() {
		this[0] = 1;
		this[1] = 0;
		this[2] = 0;
		this[3] = 0;
		this[4] = 0;
		this[5] = 0;
		this[6] = 1;
		this[7] = 0;
		this[8] = 0;
		this[9] = 0;
		this[10] = 0;
		this[11] = 0;
		this[12] = 1;
		this[13] = 0;
		this[14] = 0;
		this[15] = 0;
		this[16] = 0;
		this[17] = 0;
		this[18] = 1;
		this[19] = 0;
	}

	public function getAlphaTable():Uint8Array {
		if (__alphaTable == null) {
			__alphaTable = new Uint8Array(256);
		}

		var value:Int;
		__alphaTable[0] = 0;

		for (i in 1...256) {
			value = Math.floor(i * alphaMultiplier + alphaOffset);
			if (value > 0xFF)
				value = 0xFF;
			if (value < 0)
				value = 0;
			__alphaTable[i] = value;
		}

		return __alphaTable;
	}

	public function getBlueTable():Uint8Array {
		if (__blueTable == null) {
			__blueTable = new Uint8Array(256);
		}

		var value:Int;

		for (i in 0...256) {
			value = Math.floor(i * blueMultiplier + blueOffset);
			if (value > 0xFF)
				value = 0xFF;
			if (value < 0)
				value = 0;
			__blueTable[i] = value;
		}

		return __blueTable;
	}

	public function getGreenTable():Uint8Array {
		if (__greenTable == null) {
			__greenTable = new Uint8Array(256);
		}

		var value:Int;

		for (i in 0...256) {
			value = Math.floor(i * greenMultiplier + greenOffset);
			if (value > 0xFF)
				value = 0xFF;
			if (value < 0)
				value = 0;
			__greenTable[i] = value;
		}

		return __greenTable;
	}

	public function getRedTable():Uint8Array {
		if (__redTable == null) {
			__redTable = new Uint8Array(256);
		}

		var value:Int;

		for (i in 0...256) {
			value = Math.floor(i * redMultiplier + redOffset);
			if (value > 0xFF)
				value = 0xFF;
			if (value < 0)
				value = 0;
			__redTable[i] = value;
		}

		return __redTable;
	}

	// Get & Set Methods

	private inline function get_alphaMultiplier():Float {
		return this[18];
	}

	private inline function set_alphaMultiplier(value:Float):Float {
		return this[18] = value;
	}

	private inline function get_alphaOffset():Float {
		return this[19] * 255;
	}

	private inline function set_alphaOffset(value:Float):Float {
		return this[19] = value / 255;
	}

	private inline function get_blueMultiplier():Float {
		return this[12];
	}

	private inline function set_blueMultiplier(value:Float):Float {
		return this[12] = value;
	}

	private inline function get_blueOffset():Float {
		return this[14] * 255;
	}

	private inline function set_blueOffset(value:Float):Float {
		return this[14] = value / 255;
	}

	private function get_color():Int {
		return ((Std.int(redOffset) << 16) | (Std.int(greenOffset) << 8) | Std.int(blueOffset));
	}

	private function set_color(value:Int):Int {
		redOffset = (value >> 16) & 0xFF;
		greenOffset = (value >> 8) & 0xFF;
		blueOffset = value & 0xFF;

		redMultiplier = 0;
		greenMultiplier = 0;
		blueMultiplier = 0;

		return color;
	}

	private inline function get_greenMultiplier():Float {
		return this[6];
	}

	private inline function set_greenMultiplier(value:Float):Float {
		return this[6] = value;
	}

	private inline function get_greenOffset():Float {
		return this[9] * 255;
	}

	private inline function set_greenOffset(value:Float):Float {
		return this[9] = value / 255;
	}

	private inline function get_redMultiplier():Float {
		return this[0];
	}

	private inline function set_redMultiplier(value:Float):Float {
		return this[0] = value;
	}

	private inline function get_redOffset():Float {
		return this[4] * 255;
	}

	private inline function set_redOffset(value:Float):Float {
		return this[4] = value / 255;
	}

	@:arrayAccess public function get(index:Int):Float {
		return this[index];
	}

	@:arrayAccess public function set(index:Int, value:Float):Float {
		return this[index] = value;
	}
}
