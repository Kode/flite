// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================
package starling.display;

import flash.errors.ArgumentError;
import flash.geom.Matrix;
import flash.geom.Matrix3D;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.geom.Vector3D;
import starling.core.RenderSupport;
import starling.utils.VertexData;

/** A Quad represents a rectangle with a uniform color or a color gradient.
 *
 *  <p>You can set one color per vertex. The colors will smoothly fade into each other over the area
 *  of the quad. To display a simple linear color gradient, assign one color to vertices 0 and 1 and
 *  another color to vertices 2 and 3. </p>
 *
 *  <p>The indices of the vertices are arranged like this:</p>
 *
 *  <pre>
 *  0 - 1
 *  | / |
 *  2 - 3
 *  </pre>
 *
 *  @see Image
 */
class Quad extends DisplayObject {
	private var mTinted:Bool;

	/** The raw vertex data of the quad. */
	private var mVertexData:VertexData;

	/** Helper objects. */
	private static var sHelperPoint:Point = new Point();

	private static var sHelperPoint3D:Vector3D = new Vector3D();
	private static var sHelperMatrix:Matrix = new Matrix();
	private static var sHelperMatrix3D:Matrix3D = new Matrix3D();

	/** Creates a quad with a certain size and color. The last parameter controls if the 
	 * alpha value should be premultiplied into the color values on rendering, which can
	 * influence blending output. You can use the default value in most cases. */
	public function new(width:Float, height:Float, color:UInt = 0xffffff, premultipliedAlpha:Bool = true) {
		super();
		if (width == 0.0 || height == 0.0)
			throw new ArgumentError("Invalid size: width and height must not be zero");

		mTinted = color != 0xffffff;

		mVertexData = new VertexData(4, premultipliedAlpha);
		mVertexData.setPosition(0, 0.0, 0.0);
		mVertexData.setPosition(1, width, 0.0);
		mVertexData.setPosition(2, 0.0, height);
		mVertexData.setPosition(3, width, height);
		mVertexData.setUniformColor(color);

		onVertexDataChanged();
	}

	/** Call this method after manually changing the contents of 'mVertexData'. */
	private function onVertexDataChanged():Void {
		// override in subclasses, if necessary
	}

	/** @inheritDoc */
	public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle = null):Rectangle {
		if (resultRect == null)
			resultRect = new Rectangle();

		if (targetSpace == this) // optimization
		{
			mVertexData.getPosition(3, sHelperPoint);
			resultRect.setTo(0.0, 0.0, sHelperPoint.x, sHelperPoint.y);
		} else if (targetSpace == parent && rotation == 0.0) // optimization
		{
			var scaleX:Float = this.scaleX;
			var scaleY:Float = this.scaleY;
			mVertexData.getPosition(3, sHelperPoint);
			resultRect.setTo(x - pivotX * scaleX, y - pivotY * scaleY, sHelperPoint.x * scaleX, sHelperPoint.y * scaleY);
			if (scaleX < 0) {
				resultRect.width *= -1;
				resultRect.x -= resultRect.width;
			}
			if (scaleY < 0) {
				resultRect.height *= -1;
				resultRect.y -= resultRect.height;
			}
		} else if (is3D && stage != null) {
			stage.getCameraPosition(targetSpace, sHelperPoint3D);
			getTransformationMatrix3D(targetSpace, sHelperMatrix3D);
			mVertexData.getBoundsProjected(sHelperMatrix3D, sHelperPoint3D, 0, 4, resultRect);
		} else {
			getTransformationMatrix(targetSpace, sHelperMatrix);
			mVertexData.getBounds(sHelperMatrix, 0, 4, resultRect);
		}

		return resultRect;
	}

	/** Returns the color of a vertex at a certain index. */
	public function getVertexColor(vertexID:Int):UInt {
		return mVertexData.getColor(vertexID);
	}

	/** Sets the color of a vertex at a certain index. */
	public function setVertexColor(vertexID:Int, color:UInt):Void {
		mVertexData.setColor(vertexID, color);
		onVertexDataChanged();

		if (color != 0xffffff)
			mTinted = true;
		else
			mTinted = mVertexData.tinted;
	}

	/** Returns the alpha value of a vertex at a certain index. */
	public function getVertexAlpha(vertexID:Int):Float {
		return mVertexData.getAlpha(vertexID);
	}

	/** Sets the alpha value of a vertex at a certain index. */
	public function setVertexAlpha(vertexID:Int, alpha:Float):Void {
		mVertexData.setAlpha(vertexID, alpha);
		onVertexDataChanged();

		if (alpha != 1.0)
			mTinted = true;
		else
			mTinted = mVertexData.tinted;
	}

	/** Returns the color of the quad, or of vertex 0 if vertices have different colors. */
	public var color(get, set):UInt;

	private function get_color():UInt {
		return mVertexData.getColor(0);
	}

	/** Sets the colors of all vertices to a certain value. */
	private function set_color(value:UInt):UInt {
		mVertexData.setUniformColor(value);
		onVertexDataChanged();

		if (value != 0xffffff || alpha != 1.0)
			mTinted = true;
		else
			mTinted = mVertexData.tinted;
		return value;
	}

	/** @inheritDoc **/
	private override function set_alpha(value:Float):Float {
		super.set_alpha(value);

		if (value < 1.0)
			mTinted = true;
		else
			mTinted = mVertexData.tinted;
		return value;
	}

	/** Copies the raw vertex data to a VertexData instance. */
	public function copyVertexDataTo(targetData:VertexData, targetVertexID:Int = 0):Void {
		mVertexData.copyTo(targetData, targetVertexID);
	}

	/** Transforms the vertex positions of the raw vertex data by a certain matrix and
	 * copies the result to another VertexData instance. */
	public function copyVertexDataTransformedTo(targetData:VertexData, targetVertexID:Int = 0, matrix:Matrix = null):Void {
		mVertexData.copyTransformedTo(targetData, targetVertexID, matrix, 0, 4);
	}

	/** @inheritDoc */
	public override function render(support:RenderSupport, parentAlpha:Float):Void {
		support.batchQuad(this, parentAlpha);
	}

	/** Returns true if the quad (or any of its vertices) is non-white or non-opaque. */
	public var tinted(get, never):Bool;

	private function get_tinted():Bool {
		return mTinted;
	}

	/** Indicates if the rgb values are stored premultiplied with the alpha value; this can
	 * affect the rendering. (Most developers don't have to care, though.) */
	public var premultipliedAlpha(get, never):Bool;

	private function get_premultipliedAlpha():Bool {
		return mVertexData.premultipliedAlpha;
	}
}
