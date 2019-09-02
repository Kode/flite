// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================
package starling.utils;

import flash.errors.ArgumentError;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;

/** A utility class containing methods related to the Rectangle class. */
class RectangleUtil {
	/** Helper objects. */
	private static var sHelperPoint:Point = new Point();

	private static var sPositions:Array<Point> = [new Point(0, 0), new Point(1, 0), new Point(0, 1), new Point(1, 1)];

	/** The largest representable number. */
	private static inline var MAX_VALUE:Float = 1.79e+308;

	/** The largest representable number. */
	private static inline var MIN_VALUE:Float = 5e-324;

	/** Calculates the intersection between two Rectangles. If the rectangles do not intersect,
	 * this method returns an empty Rectangle object with its properties set to 0. */
	public static function intersect(rect1:Rectangle, rect2:Rectangle, resultRect:Rectangle = null):Rectangle {
		if (resultRect == null)
			resultRect = new Rectangle();

		var left:Float = rect1.x > rect2.x ? rect1.x : rect2.x;
		var right:Float = rect1.right < rect2.right ? rect1.right : rect2.right;
		var top:Float = rect1.y > rect2.y ? rect1.y : rect2.y;
		var bottom:Float = rect1.bottom < rect2.bottom ? rect1.bottom : rect2.bottom;

		if (left > right || top > bottom)
			resultRect.setEmpty();
		else
			resultRect.setTo(left, top, right - left, bottom - top);

		return resultRect;
	}

	/** Calculates a rectangle with the same aspect ratio as the given 'rectangle',
	 * centered within 'into'.
	 *
	 * <p>This method is useful for calculating the optimal viewPort for a certain display
	 * size. You can use different scale modes to specify how the result should be calculated;
	 * furthermore, you can avoid pixel alignment errors by only allowing whole-number
	 * multipliers/divisors (e.g. 3, 2, 1, 1/2, 1/3).</p>
	 *
	 * @see starling.utils.ScaleMode
	 */
	public static function fit(rectangle:Rectangle, into:Rectangle, scaleMode:String = "showAll", pixelPerfect:Bool = false,
			resultRect:Rectangle = null):Rectangle {
		if (!ScaleMode.isValid(scaleMode))
			throw new ArgumentError("Invalid scaleMode: " + scaleMode);
		if (resultRect == null)
			resultRect = new Rectangle();

		var width:Float = rectangle.width;
		var height:Float = rectangle.height;
		var factorX:Float = into.width / width;
		var factorY:Float = into.height / height;
		var factor:Float = 1.0;

		if (scaleMode == ScaleMode.SHOW_ALL) {
			factor = factorX < factorY ? factorX : factorY;
			if (pixelPerfect)
				factor = nextSuitableScaleFactor(factor, false);
		} else if (scaleMode == ScaleMode.NO_BORDER) {
			factor = factorX > factorY ? factorX : factorY;
			if (pixelPerfect)
				factor = nextSuitableScaleFactor(factor, true);
		}

		width *= factor;
		height *= factor;

		resultRect.setTo(into.x + (into.width - width) / 2, into.y + (into.height - height) / 2, width, height);

		return resultRect;
	}

	/** Calculates the next whole-number multiplier or divisor, moving either up or down. */
	private static function nextSuitableScaleFactor(factor:Float, up:Bool):Float {
		var divisor:Float = 1.0;

		if (up) {
			if (factor >= 0.5)
				return Math.ceil(factor);
			else {
				while (1.0 / (divisor + 1) > factor)
					++divisor;
			}
		} else {
			if (factor >= 1.0)
				return Math.floor(factor);
			else {
				while (1.0 / divisor > factor)
					++divisor;
			}
		}

		return 1.0 / divisor;
	}

	/** If the rectangle contains negative values for width or height, all coordinates
	 * are adjusted so that the rectangle describes the same region with positive values. */
	public static function normalize(rect:Rectangle):Void {
		if (rect.width < 0) {
			rect.width = -rect.width;
			rect.x -= rect.width;
		}

		if (rect.height < 0) {
			rect.height = -rect.height;
			rect.y -= rect.height;
		}
	}

	/** Calculates the bounds of a rectangle after transforming it by a matrix.
	 * If you pass a 'resultRect', the result will be stored in this rectangle
	 * instead of creating a new object. */
	public static function getBounds(rectangle:Rectangle, transformationMatrix:Matrix, resultRect:Rectangle = null):Rectangle {
		if (resultRect == null)
			resultRect = new Rectangle();

		var minX:Float = MAX_VALUE, maxX:Float = -MAX_VALUE;
		var minY:Float = MAX_VALUE, maxY:Float = -MAX_VALUE;

		for (i in 0...4) {
			MatrixUtil.transformCoords(transformationMatrix, sPositions[i].x * rectangle.width, sPositions[i].y * rectangle.height, sHelperPoint);

			if (minX > sHelperPoint.x)
				minX = sHelperPoint.x;
			if (maxX < sHelperPoint.x)
				maxX = sHelperPoint.x;
			if (minY > sHelperPoint.y)
				minY = sHelperPoint.y;
			if (maxY < sHelperPoint.y)
				maxY = sHelperPoint.y;
		}

		resultRect.setTo(minX, minY, maxX - minX, maxY - minY);
		return resultRect;
	}
}
