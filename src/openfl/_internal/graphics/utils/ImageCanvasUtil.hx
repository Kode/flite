package openfl._internal.graphics.utils;

import openfl._internal.graphics.Image;
import openfl._internal.graphics.PixelFormat;
import openfl.geom.Rectangle;
import openfl.geom.Point;
import openfl.display.BitmapDataChannel;
import js.lib.Uint8Array;

@:access(openfl._internal.graphics.Image)
class ImageCanvasUtil {
	public static function convertToCanvas(image:Image, clear:Bool = false):Void {
		if (image.__srcImage != null) {
			if (image.__srcCanvas == null) {
				image.createCanvas();
				image.__srcContext.drawImage(image.__srcImage, 0, 0);
			}

			image.__srcImage = null;
		} else if (image.__srcCanvas == null && image.data != null) {
			image.transparent = true;
			image.createCanvas();
			image.createImageData();
			image.__srcContext.putImageData(image.__srcImageData, 0, 0);
		} else {
			if (image.type == DATA && image.__srcImageData != null && image.dirty) {
				image.__srcContext.putImageData(image.__srcImageData, 0, 0);
				image.dirty = false;
			}
		}

		if (clear) {
			image.data = null;
			image.__srcImageData = null;
		} else {
			if (image.data == null && image.__srcImageData != null) {
				image.data = cast image.__srcImageData.data;
			}
		}

		image.type = CANVAS;
	}

	public static function convertToData(image:Image):Void {
		if (image.__srcImage != null) {
			convertToCanvas(image);
		}

		if (image.__srcCanvas != null && image.data == null) {
			image.createImageData();
			if (image.type == CANVAS)
				image.dirty = false;
		} else if (image.type == CANVAS && image.__srcCanvas != null && image.dirty) {
			if (image.__srcImageData == null) {
				image.createImageData();
			} else {
				image.__srcImageData = image.__srcContext.getImageData(0, 0, image.width, image.height);
				image.data = new Uint8Array(image.__srcImageData.data.buffer);
			}

			image.dirty = false;
		}

		image.type = DATA;
	}

	public static function copyPixels(image:Image, sourceImage:Image, sourceRect:Rectangle, destPoint:Point, alphaImage:Image = null,
			alphaPoint:Point = null, mergeAlpha:Bool = false):Void {
		if (destPoint == null || destPoint.x >= image.width || destPoint.y >= image.height || sourceRect == null || sourceRect.width < 1
			|| sourceRect.height < 1) {
			return;
		}

		if (alphaImage != null && alphaImage.transparent) {
			if (alphaPoint == null)
				alphaPoint = new Point();

			// TODO: use faster method

			var tempData = image.clone();
			tempData.copyChannel(alphaImage, new Rectangle(alphaPoint.x, alphaPoint.y, sourceRect.width, sourceRect.height),
				new Point(sourceRect.x, sourceRect.y), BitmapDataChannel.ALPHA, BitmapDataChannel.ALPHA);
			sourceImage = tempData;
		}

		convertToCanvas(image, true);

		if (!mergeAlpha) {
			if (image.transparent && sourceImage.transparent) {
				image.__srcContext.clearRect(destPoint.x, destPoint.y, sourceRect.width, sourceRect.height);
			}
		}

		convertToCanvas(sourceImage);

		if (sourceImage.src != null) {
			// Set default composition (just in case it is different)
			image.__srcContext.globalCompositeOperation = "source-over";

			image.__srcContext.drawImage(sourceImage.src, Std.int(sourceRect.x),
				Std.int(sourceRect.y), Std.int(sourceRect.width), Std.int(sourceRect.height), Std.int(destPoint.x),
				Std.int(destPoint.y), Std.int(sourceRect.width), Std.int(sourceRect.height));
		}

		image.dirty = true;
		image.version++;
	}


	public static function fillRect(image:Image, rect:Rectangle, color:Int, format:PixelFormat):Void {
		convertToCanvas(image);

		var r, g, b, a;

		if (format == ARGB32) {
			r = (color >> 16) & 0xFF;
			g = (color >> 8) & 0xFF;
			b = color & 0xFF;
			a = (image.transparent) ? (color >> 24) & 0xFF : 0xFF;
		} else {
			r = (color >> 24) & 0xFF;
			g = (color >> 16) & 0xFF;
			b = (color >> 8) & 0xFF;
			a = (image.transparent) ? color & 0xFF : 0xFF;
		}

		if (rect.x == 0 && rect.y == 0 && rect.width == image.width && rect.height == image.height) {
			if (image.transparent && a == 0) {
				image.__srcCanvas.width = image.width;
				return;
			}
		}

		if (a < 255) {
			image.__srcContext.clearRect(rect.x, rect.y, rect.width, rect.height);
		}

		if (a > 0) {
			image.__srcContext.fillStyle = 'rgba(' + r + ', ' + g + ', ' + b + ', ' + (a / 255) + ')';
			image.__srcContext.fillRect(rect.x, rect.y, rect.width, rect.height);
		}

		image.dirty = true;
		image.version++;
	}

	public static function scroll(image:Image, x:Int, y:Int):Void {
		if ((x % image.width == 0) && (y % image.height == 0))
			return;

		var copy = image.clone();

		convertToCanvas(image, true);

		image.__srcContext.clearRect(x, y, image.width, image.height);
		image.__srcContext.drawImage(copy.src, x, y);

		image.dirty = true;
		image.version++;
	}
}
