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

import flash.display.BitmapData;
import flash.errors.IllegalOperationError;
import flash.geom.Matrix3D;
import flash.geom.Point;
import flash.geom.Vector3D;
import openfl.Vector;
import starling.core.RenderSupport;
import starling.core.Starling;
import starling.events.EnterFrameEvent;
import starling.events.Event;
import starling.filters.FragmentFilter;
import starling.utils.MatrixUtil;

/** Dispatched when the Flash container is resized. */
@:meta(Event(name = "resize", type = "starling.events.ResizeEvent"))

/** A Stage represents the root of the display tree.  
 *  Only objects that are direct or indirect children of the stage will be rendered.
 *
 *  <p>This class represents the Starling version of the stage. Don't confuse it with its
 *  Flash equivalent: while the latter contains objects of the type
 *  <code>flash.display.DisplayObject</code>, the Starling stage contains only objects of the
 *  type <code>starling.display.DisplayObject</code>. Those classes are not compatible, and
 *  you cannot exchange one type with the other.</p>
 *
 *  <p>A stage object is created automatically by the <code>Starling</code> class. Don't
 *  create a Stage instance manually.</p>
 *
 *  <strong>Keyboard Events</strong>
 *
 *  <p>In Starling, keyboard events are only dispatched at the stage. Add an event listener
 *  directly to the stage to be notified of keyboard events.</p>
 *
 *  <strong>Resize Events</strong>
 *
 *  <p>When the Flash player is resized, the stage dispatches a <code>ResizeEvent</code>. The
 *  event contains properties containing the updated width and height of the Flash player.</p>
 *
 *  @see starling.events.KeyboardEvent
 *  @see starling.events.ResizeEvent
 *
 */
class Stage extends DisplayObjectContainer {
	private var mWidth:Int;
	private var mHeight:Int;
	private var mColor:UInt;
	private var mFieldOfView:Float;
	private var mProjectionOffset:Point;
	private var mCameraPosition:Vector3D;
	private var mEnterFrameEvent:EnterFrameEvent;
	private var mEnterFrameListeners:Vector<DisplayObject>;

	/** Helper objects. */
	private static var sHelperMatrix:Matrix3D = new Matrix3D();

	/** @private */
	private function new(width:Int, height:Int, color:UInt = 0) {
		super();
		mWidth = width;
		mHeight = height;
		mColor = color;
		mFieldOfView = 1.0;
		mProjectionOffset = new Point();
		mCameraPosition = new Vector3D();
		mEnterFrameEvent = new EnterFrameEvent(Event.ENTER_FRAME, 0.0);
		mEnterFrameListeners = new Vector<DisplayObject>();
	}

	/** @inheritDoc */
	public function advanceTime(passedTime:Float):Void {
		mEnterFrameEvent.reset(Event.ENTER_FRAME, false, passedTime);
		broadcastEvent(mEnterFrameEvent);
	}

	/** Returns the object that is found topmost beneath a point in stage coordinates, or  
	 * the stage itself if nothing else is found. */
	public override function hitTest(localPoint:Point, forTouch:Bool = false):DisplayObject {
		if (forTouch && (!visible || !touchable))
			return null;

		// locations outside of the stage area shouldn't be accepted
		if (localPoint.x < 0 || localPoint.x > mWidth || localPoint.y < 0 || localPoint.y > mHeight)
			return null;

		// if nothing else is hit, the stage returns itself as target
		var target:DisplayObject = super.hitTest(localPoint, forTouch);
		if (target == null)
			target = this;
		return target;
	}

	/** Draws the complete stage into a BitmapData object.
	 *
	 * <p>If you encounter problems with transparency, start Starling in BASELINE profile
	 * (or higher). BASELINE_CONSTRAINED might not support transparency on all platforms.
	 * </p>
	 *
	 * @param destination  If you pass null, the object will be created for you.
	 *                     If you pass a BitmapData object, it should have the size of the
	 *                     back buffer (which is accessible via the respective properties
	 *                     on the Starling instance).
	 * @param transparent  If enabled, empty areas will appear transparent; otherwise, they
	 *                     will be filled with the stage color.
	 */
	public function drawToBitmapData(destination:BitmapData = null, transparent:Bool = true):BitmapData {
		var support:RenderSupport = new RenderSupport();
		var star:Starling = Starling.current;

		if (destination == null) {
			var width:Int = star.backBufferWidth * star.backBufferPixelsPerPoint;
			var height:Int = star.backBufferHeight * star.backBufferPixelsPerPoint;
			destination = new BitmapData(width, height, transparent);
		}

		support.renderTarget = null;
		support.setProjectionMatrix(0, 0, mWidth, mHeight, mWidth, mHeight, cameraPosition);

		if (transparent)
			support.clear();
		else
			support.clear(mColor, 1);

		render(support, 1.0);
		support.finishQuadBatch();
		support.dispose();

		Starling.current.context.drawToBitmapData(destination);
		Starling.current.context.present(); // required on some platforms to avoid flickering

		return destination;
	}

	// camera positioning

	/** Returns the position of the camera within the local coordinate system of a certain
	 * display object. If you do not pass a space, the method returns the global position.
	 * To change the position of the camera, you can modify the properties 'fieldOfView',
	 * 'focalDistance' and 'projectionOffset'.
	 */
	public function getCameraPosition(space:DisplayObject = null, result:Vector3D = null):Vector3D {
		getTransformationMatrix3D(space, sHelperMatrix);

		return MatrixUtil.transformCoords3D(sHelperMatrix, mWidth / 2 + mProjectionOffset.x, mHeight / 2 + mProjectionOffset.y, -focalLength, result);
	}

	// enter frame event optimization

	/** @private */
	@:allow(starling) private function addEnterFrameListener(listener:DisplayObject):Void {
		mEnterFrameListeners.push(listener);
	}

	/** @private */
	@:allow(starling) private function removeEnterFrameListener(listener:DisplayObject):Void {
		var index:Int = mEnterFrameListeners.indexOf(listener);
		if (index >= 0)
			mEnterFrameListeners.splice(index, 1);
	}

	/** @private */
	@:allow(starling) private override function __getChildEventListeners(object:DisplayObject, eventType:String, listeners:Vector<DisplayObject>):Void {
		if (eventType == Event.ENTER_FRAME && object == this) {
			var length:Int = mEnterFrameListeners.length;
			for (i in 0...length)
				listeners[listeners.length] = mEnterFrameListeners[i]; // avoiding 'push'
		} else
			super.__getChildEventListeners(object, eventType, listeners);
	}

	// properties

	/** @private */
	private override function set_width(value:Float):Float {
		throw new IllegalOperationError("Cannot set width of stage");
	}

	/** @private */
	private override function set_height(value:Float):Float {
		throw new IllegalOperationError("Cannot set height of stage");
	}

	/** @private */
	private override function set_x(value:Float):Float {
		throw new IllegalOperationError("Cannot set x-coordinate of stage");
	}

	/** @private */
	private override function set_y(value:Float):Float {
		throw new IllegalOperationError("Cannot set y-coordinate of stage");
	}

	/** @private */
	private override function set_scaleX(value:Float):Float {
		throw new IllegalOperationError("Cannot scale stage");
	}

	/** @private */
	private override function set_scaleY(value:Float):Float {
		throw new IllegalOperationError("Cannot scale stage");
	}

	/** @private */
	private override function set_rotation(value:Float):Float {
		throw new IllegalOperationError("Cannot rotate stage");
	}

	/** @private */
	private override function set_skewX(value:Float):Float {
		throw new IllegalOperationError("Cannot skew stage");
	}

	/** @private */
	private override function set_skewY(value:Float):Float {
		throw new IllegalOperationError("Cannot skew stage");
	}

	/** @private */
	private override function set_filter(value:FragmentFilter):FragmentFilter {
		throw new IllegalOperationError("Cannot add filter to stage. Add it to 'root' instead!");
	}

	/** The background color of the stage. */
	public var color(get, set):UInt;

	private function get_color():UInt {
		return mColor;
	}

	private function set_color(value:UInt):UInt {
		return mColor = value;
	}

	/** The width of the stage coordinate system. Change it to scale its contents relative
	 * to the <code>viewPort</code> property of the Starling object. */
	public var stageWidth(get, set):Int;

	private function get_stageWidth():Int {
		return mWidth;
	}

	private function set_stageWidth(value:Int):Int {
		return mWidth = value;
	}

	/** The height of the stage coordinate system. Change it to scale its contents relative
	 * to the <code>viewPort</code> property of the Starling object. */
	public var stageHeight(get, set):Int;

	private function get_stageHeight():Int {
		return mHeight;
	}

	private function set_stageHeight(value:Int):Int {
		return mHeight = value;
	}

	/** The distance between the stage and the camera. Changing this value will update the
	 * field of view accordingly. */
	public var focalLength(get, set):Float;

	private function get_focalLength():Float {
		return mWidth / (2 * Math.tan(mFieldOfView / 2));
	}

	private function set_focalLength(value:Float):Float {
		return mFieldOfView = 2 * Math.atan(stageWidth / (2 * value));
	}

	/** Specifies an angle (radian, between zero and PI) for the field of view. This value
	 * determines how strong the perspective transformation and distortion apply to a Sprite3D
	 * object.
	 *
	 * <p>A value close to zero will look similar to an orthographic projection; a value
	 * close to PI results in a fisheye lens effect. If the field of view is set to 0 or PI,
	 * nothing is seen on the screen.</p>
	 *
	 * @default 1.0
	 */
	public var fieldOfView(get, set):Float;

	private function get_fieldOfView():Float {
		return mFieldOfView;
	}

	private function set_fieldOfView(value:Float):Float {
		return mFieldOfView = value;
	}

	/** A vector that moves the camera away from its default position in the center of the
	 * stage. Use this property to change the center of projection, i.e. the vanishing
	 * point for 3D display objects. <p>CAUTION: not a copy, but the actual object!</p>
	 */
	public var projectionOffset(get, set):Point;

	private function get_projectionOffset():Point {
		return mProjectionOffset;
	}

	private function set_projectionOffset(value:Point):Point {
		mProjectionOffset.setTo(value.x, value.y);
		return value;
	}

	/** The global position of the camera. This property can only be used to find out the
	 * current position, but not to modify it. For that, use the 'projectionOffset',
	 * 'fieldOfView' and 'focalLength' properties. If you need the camera position in
	 * a certain coordinate space, use 'getCameraPosition' instead.
	 *
	 * <p>CAUTION: not a copy, but the actual object!</p>
	 */
	public var cameraPosition(get, never):Vector3D;

	private function get_cameraPosition():Vector3D {
		return getCameraPosition(null, mCameraPosition);
	}
}
