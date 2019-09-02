package openfl.display;

import openfl._internal.renderer.canvas.CanvasGraphics;
import openfl._internal.renderer.canvas.CanvasRenderSession;
import openfl._internal.renderer.opengl.GLRenderSession;
import openfl.errors.ArgumentError;
import openfl.errors.RangeError;
import openfl.errors.TypeError;
import openfl.events.Event;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.Vector;

@:access(openfl.events.Event)
@:access(openfl.display.Graphics)
@:access(openfl.errors.Error)
@:access(openfl.geom.Point)
@:access(openfl.geom.Matrix)
@:access(openfl.geom.Rectangle)
class DisplayObjectContainer extends InteractiveObject {
	public var mouseChildren:Bool;
	public var numChildren(get, never):Int;
	public var tabChildren:Bool;

	private var __removedChildren:Array<DisplayObject>;

	private function new() {
		super();

		mouseChildren = true;

		__children = new Array<DisplayObject>();
		__removedChildren = new Array<DisplayObject>();
	}

	public function addChild(child:DisplayObject):DisplayObject {
		return addChildAt(child, numChildren);
	}

	public function addChildAt(child:DisplayObject, index:Int):DisplayObject {
		if (child == null) {
			var error = new TypeError("Error #2007: Parameter child must be non-null.");
			error.errorID = 2007;
			throw error;
		} else if (child.stage == child) {
			var error = new ArgumentError("Error #3783: A Stage object cannot be added as the child of another object.");
			error.errorID = 3783;
			throw error;
		}

		if (index > __children.length || index < 0) {
			throw "Invalid index position " + index;
		}

		if (child.parent == this) {
			if (__children[index] != child) {
				__children.remove(child);
				__children.insert(index, child);

				__setRenderDirty();
			}
		} else {
			if (child.parent != null) {
				child.parent.removeChild(child);
			}

			__children.insert(index, child);
			child.parent = this;

			var addedToStage = (stage != null && child.stage == null);

			if (addedToStage) {
				this.__setStageReference(stage);
			}

			child.__setTransformDirty();
			child.__setRenderDirty();
			__setRenderDirty();

			var event = new Event(Event.ADDED, true);
			event.target = child;
			child.__dispatchWithCapture(event);

			if (addedToStage) {
				var event = new Event(Event.ADDED_TO_STAGE, false, false);
				child.__dispatchWithCapture(event);
				child.__dispatchChildren(event);
			}
		}

		return child;
	}

	public function areInaccessibleObjectsUnderPoint(point:Point):Bool {
		return false;
	}

	public function contains(child:DisplayObject):Bool {
		while (child != this && child != null) {
			child = child.parent;
		}

		return child == this;
	}

	public function getChildAt(index:Int):DisplayObject {
		if (index >= 0 && index < __children.length) {
			return __children[index];
		}

		return null;
	}

	public function getChildByName(name:String):DisplayObject {
		for (child in __children) {
			if (child.name == name)
				return child;
		}

		return null;
	}

	public function getChildIndex(child:DisplayObject):Int {
		for (i in 0...__children.length) {
			if (__children[i] == child)
				return i;
		}

		return -1;
	}

	public function getObjectsUnderPoint(point:Point):Array<DisplayObject> {
		var stack = new Array<DisplayObject>();
		__hitTest(point.x, point.y, false, stack, false, this);
		stack.reverse();
		return stack;
	}

	public function removeChild(child:DisplayObject):DisplayObject {
		if (child != null && child.parent == this) {
			child.__setTransformDirty();
			child.__setRenderDirty();
			__setRenderDirty();

			var event = new Event(Event.REMOVED, true);
			child.__dispatchWithCapture(event);

			if (stage != null) {
				if (child.stage != null && stage.focus == child) {
					stage.focus = null;
				}

				var event = new Event(Event.REMOVED_FROM_STAGE, false, false);
				child.__dispatchWithCapture(event);
				child.__dispatchChildren(event);
				child.__setStageReference(null);
			}

			child.parent = null;
			__children.remove(child);
			__removedChildren.push(child);
			child.__setTransformDirty();
		}

		return child;
	}

	public function removeChildAt(index:Int):DisplayObject {
		if (index >= 0 && index < __children.length) {
			return removeChild(__children[index]);
		}

		return null;
	}

	public function removeChildren(beginIndex:Int = 0, endIndex:Int = 0x7FFFFFFF):Void {
		if (endIndex == 0x7FFFFFFF) {
			endIndex = __children.length - 1;

			if (endIndex < 0) {
				return;
			}
		}

		if (beginIndex > __children.length - 1) {
			return;
		} else if (endIndex < beginIndex || beginIndex < 0 || endIndex > __children.length) {
			throw new RangeError("The supplied index is out of bounds.");
		}

		var numRemovals = endIndex - beginIndex;
		while (numRemovals >= 0) {
			removeChildAt(beginIndex);
			numRemovals--;
		}
	}

	private function resolve(fieldName:String):DisplayObject {
		if (__children == null)
			return null;

		for (child in __children) {
			if (child.name == fieldName) {
				return child;
			}
		}

		return null;
	}

	public function setChildIndex(child:DisplayObject, index:Int):Void {
		if (index >= 0 && index <= __children.length && child.parent == this) {
			__children.remove(child);
			__children.insert(index, child);
		}
	}

	public function stopAllMovieClips():Void {
		__stopAllMovieClips();
	}

	public function swapChildren(child1:DisplayObject, child2:DisplayObject):Void {
		if (child1.parent == this && child2.parent == this) {
			var index1 = __children.indexOf(child1);
			var index2 = __children.indexOf(child2);

			__children[index1] = child2;
			__children[index2] = child1;

			__setRenderDirty();
		}
	}

	public function swapChildrenAt(index1:Int, index2:Int):Void {
		var swap:DisplayObject = __children[index1];
		__children[index1] = __children[index2];
		__children[index2] = swap;
		swap = null;
		__setRenderDirty();
	}

	inline function __cleanupRemovedChildren() {
		for (orphan in __removedChildren) {
			if (orphan.stage == null) {
				orphan.__cleanup();
			}
		}

		__removedChildren.resize(0);
	}

	override function __cleanup():Void {
		super.__cleanup();

		for (child in __children) {
			child.__cleanup();
		}

		__cleanupRemovedChildren();
	}

	private override function __dispatchChildren(event:Event):Void {
		if (__children != null) {
			for (child in __children) {
				event.target = child;

				if (!child.__dispatchWithCapture(event)) {
					break;
				}

				child.__dispatchChildren(event);
			}
		}
	}

	private override function __enterFrame(deltaTime:Int):Void {
		for (child in __children) {
			child.__enterFrame(deltaTime);
		}
	}

	private override function __forceRenderDirty():Void {
		super.__forceRenderDirty();

		for (child in __children) {
			child.__forceRenderDirty();
		}
	}

	private override function __getBounds(rect:Rectangle, matrix:Matrix):Void {
		super.__getBounds(rect, matrix);

		if (__children.length == 0)
			return;

		var childWorldTransform = Matrix.__pool.get();

		for (child in __children) {
			if (child.__scaleX == 0 || child.__scaleY == 0)
				continue;

			DisplayObject.__calculateAbsoluteTransform(child.__transform, matrix, childWorldTransform);

			child.__getBounds(rect, childWorldTransform);
		}

		Matrix.__pool.release(childWorldTransform);
	}

	private override function __getFilterBounds(rect:Rectangle, matrix:Matrix):Void {
		super.__getFilterBounds(rect, matrix);

		if (__children.length == 0)
			return;

		var childWorldTransform = Matrix.__pool.get();

		for (child in __children) {
			if (child.__scaleX == 0 || child.__scaleY == 0 || child.__isMask)
				continue;

			DisplayObject.__calculateAbsoluteTransform(child.__transform, matrix, childWorldTransform);

			child.__getFilterBounds(rect, childWorldTransform);
		}

		Matrix.__pool.release(childWorldTransform);
	}

	private override function __getRenderBounds(rect:Rectangle, matrix:Matrix):Void {
		if (__scrollRect != null) {
			super.__getRenderBounds(rect, matrix);
			return;
		} else {
			super.__getBounds(rect, matrix);
		}

		if (__children.length == 0)
			return;

		var childWorldTransform = Matrix.__pool.get();

		for (child in __children) {
			if (child.__scaleX == 0 || child.__scaleY == 0 || child.__isMask)
				continue;

			DisplayObject.__calculateAbsoluteTransform(child.__transform, matrix, childWorldTransform);

			child.__getRenderBounds(rect, childWorldTransform);
		}

		Matrix.__pool.release(childWorldTransform);
	}

	private override function __hitTest(x:Float, y:Float, shapeFlag:Bool, stack:Array<DisplayObject>, interactiveOnly:Bool, hitObject:DisplayObject,
			hitTestWhenMouseDisabled:Bool = false):Bool {
		if (!hitObject.visible || __isMask || (!hitTestWhenMouseDisabled && interactiveOnly && !mouseEnabled && !mouseChildren))
			return false;
		if (mask != null && !mask.__hitTestMask(x, y))
			return false;

		if (__scrollRect != null) {
			var point = Point.__pool.get();
			point.setTo(x, y);
			__getRenderTransform().__transformInversePoint(point);

			if (!__scrollRect.containsPoint(point)) {
				Point.__pool.release(point);
				return false;
			}

			Point.__pool.release(point);
		}

		var i = __children.length;
		if (interactiveOnly) {
			if (stack == null || !mouseChildren) {
				while (--i >= 0) {
					if (__children[i].__hitTest(x, y, shapeFlag, null, true, cast __children[i], hitTestWhenMouseDisabled)) {
						if (stack != null && !hitTestWhenMouseDisabled) {
							stack.push(hitObject);
						}

						return true;
					}
				}
			} else if (stack != null) {
				var length = stack.length;

				var interactive = false;
				var hitTest = false;

				while (--i >= 0) {
					interactive = __children[i].__getInteractive(null);

					var childHitTestWhenMouseDisabled = hitTestWhenMouseDisabled
						|| (interactive && !__children[i].__mouseThroughAllowed())
						|| (!interactive && !mouseEnabled);

					if (interactive || (mouseEnabled && !hitTest) || childHitTestWhenMouseDisabled) {
						if (__children[i].__hitTest(x, y, shapeFlag, stack, true, cast __children[i], childHitTestWhenMouseDisabled)) {
							hitTest = true;

							if (!childHitTestWhenMouseDisabled && interactive && stack.length > 0) {
								break;
							}
						}
					}
				}

				if (hitTest) {
					if (!hitTestWhenMouseDisabled && mouseEnabled) {
						stack.insert(length, hitObject);
					}

					return true;
				}
			}
		} else {
			while (--i >= 0) {
				__children[i].__hitTest(x, y, shapeFlag, stack, false, cast __children[i]);
			}
		}

		return false;
	}

	private override function __hitTestMask(x:Float, y:Float):Bool {
		var i = __children.length;

		while (--i >= 0) {
			if (__children[i].__hitTestMask(x, y)) {
				return true;
			}
		}

		return false;
	}

	private override function __mouseThroughAllowed():Bool {
		return mouseEnabled || mouseChildren;
	}

	private override function __readGraphicsData(graphicsData:Vector<IGraphicsData>, recurse:Bool):Void {
		super.__readGraphicsData(graphicsData, recurse);

		if (recurse) {
			for (child in __children) {
				child.__readGraphicsData(graphicsData, recurse);
			}
		}
	}

	private override function __renderCanvas(renderSession:CanvasRenderSession):Void {
		__cleanupRemovedChildren();

		if (!__renderable || __worldAlpha <= 0 || (mask != null && (mask.width <= 0 || mask.height <= 0)))
			return;

		super.__renderCanvas(renderSession);

		if (__cacheBitmap != null && !__cacheBitmapRender)
			return;

		renderSession.maskManager.pushObject(this);

		if (renderSession.clearRenderDirty) {
			for (child in __children) {
				child.__renderCanvas(renderSession);
				child.__renderDirty = false;
			}

			__renderDirty = false;
		} else {
			for (child in __children) {
				child.__renderCanvas(renderSession);
			}
		}

		renderSession.maskManager.popObject(this);
	}

	private override function __renderCanvasMask(renderSession:CanvasRenderSession):Void {
		if (__graphics != null) {
			CanvasGraphics.renderMask(__graphics, renderSession.context);
		}

		var bounds = Rectangle.__pool.get();
		__getLocalBounds(bounds);

		renderSession.context.rect(0, 0, bounds.width, bounds.height);

		Rectangle.__pool.release(bounds);
		/*for (child in __children) {

			child.__renderMask (renderSession);

		}*/
	}

	private override function __renderGL(renderSession:GLRenderSession):Void {
		__cleanupRemovedChildren();

		if (!__renderable || __worldAlpha <= 0)
			return;

		super.__renderGL(renderSession);

		if (__cacheBitmap != null && !__cacheBitmapRender)
			return;

		if (__children.length > 0) {
			renderSession.maskManager.pushObject(this);
			for (child in __children) {
				child.__renderGL(renderSession);
				child.__renderDirty = false;
			}
			__renderDirty = false;
			renderSession.maskManager.popObject(this);
		}
	}

	private override function __renderGLMask(renderSession:GLRenderSession):Void {
		__cleanupRemovedChildren();

		super.__renderGLMask(renderSession);

		if (__cacheBitmap != null && !__cacheBitmapRender)
			return;

		for (child in __children) {
			child.__renderGLMask(renderSession);
			child.__renderDirty = false;
		}

		__renderDirty = false;
	}

	private override function __setStageReference(stage:Stage):Void {
		super.__setStageReference(stage);

		if (__children != null) {
			for (child in __children) {
				child.__setStageReference(stage);
			}
		}
	}

	private override function __setWorldTransformInvalid():Void {
		if (!__worldTransformInvalid) {
			__worldTransformInvalid = true;

			if (__children != null) {
				for (child in __children) {
					child.__setWorldTransformInvalid();
				}
			}
		}
	}

	private override function __stopAllMovieClips():Void {
		for (child in __children) {
			child.__stopAllMovieClips();
		}
	}

	private override function __traverse():Void {
		if (__updateDirty) {
			__update(false, true, true);
		} else if (__updateTraverse) {
			for (child in __children) {
				child.__traverse();
			}
		}

		// This container has been traversed, therefore reset flag
		__updateTraverse = false;
	}

	public override function __update(transformOnly:Bool, updateChildren:Bool, ?resetUpdateDirty:Bool = false):Void {
		super.__update(transformOnly, updateChildren, resetUpdateDirty);

		if (updateChildren) {
			for (child in __children) {
				child.__update(transformOnly, true, resetUpdateDirty);
			}
		}
	}

	public override function __updateChildren(transformOnly:Bool):Void {
		super.__updateChildren(transformOnly);

		for (child in __children) {
			child.__update(transformOnly, true);
		}
	}

	// Get & Set Methods

	private function get_numChildren():Int {
		return __children.length;
	}
}
