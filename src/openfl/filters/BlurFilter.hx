package openfl.filters;

import openfl._internal.graphics.utils.ImageDataUtil;
import openfl.display.BitmapData;
import openfl.filters.BitmapFilter;
import openfl.geom.Point;
import openfl.geom.Rectangle;

@:access(openfl.geom.Point)
@:access(openfl.geom.Rectangle)
@:final class BlurFilter extends BitmapFilter {
	public var blurX(get, set):Float;
	public var blurY(get, set):Float;
	public var quality(get, set):Int;

	private var __blurX:Float;
	private var __blurY:Float;
	private var __quality:Int;

	public function new(blurX:Float = 4, blurY:Float = 4, quality:Int = 1) {
		super();

		this.blurX = blurX;
		this.blurY = blurY;
		this.quality = quality;

		__needSecondBitmapData = true;
		__preserveObject = false;
		__renderDirty = true;
	}

	public override function clone():BitmapFilter {
		return new BlurFilter(__blurX, __blurY, __quality);
	}

	@:access(openfl.display.BitmapData)
	private override function __applyFilter(bitmapData:BitmapData, sourceBitmapData:BitmapData, sourceRect:Rectangle, destPoint:Point):BitmapData {
		var pixelRatio = sourceBitmapData.__pixelRatio;
		var finalImage = ImageDataUtil.gaussianBlur(bitmapData.image, sourceBitmapData.image, sourceRect, destPoint, __blurX * pixelRatio, __blurY * pixelRatio, __quality);
		if (finalImage == bitmapData.image)
			return bitmapData;
		return sourceBitmapData;
	}

	function get_blurX():Float {
		return __blurX;
	}

	function set_blurX(value:Float):Float {
		if (value != __blurX) {
			__blurX = value;
			__renderDirty = true;
			__leftExtension = (value > 0 ? Math.ceil(value) : 0);
			__rightExtension = __leftExtension;
		}
		return value;
	}

	function get_blurY():Float {
		return __blurY;
	}

	function set_blurY(value:Float):Float {
		if (value != __blurY) {
			__blurY = value;
			__renderDirty = true;
			__topExtension = (value > 0 ? Math.ceil(value) : 0);
			__bottomExtension = __topExtension;
		}
		return value;
	}

	function get_quality():Int {
		return __quality;
	}

	function set_quality(value:Int):Int {
		if (__quality != value) {
			__quality = value;
			__renderDirty = true;
		}
		return value;
	}
}
