package openfl.display;

import haxe.CallStack;
import openfl._internal.ui.Gamepad;
import openfl._internal.ui.GamepadAxis;
import openfl._internal.ui.GamepadButton;
import openfl._internal.ui.KeyCode;
import openfl._internal.ui.KeyModifier;
import openfl._internal.ui.Window;
import openfl._internal.renderer.opengl.GLRenderer;
import openfl._internal.stage3D.GLCompressedTextureFormats;
import openfl.display.DisplayObjectContainer;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.EventPhase;
import openfl.events.FocusEvent;
import openfl.events.FullScreenEvent;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.events.TouchEvent;
import openfl.events.UncaughtErrorEvent;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.geom.Transform;
import openfl.ui.GameInput;
import openfl.ui.Keyboard;
import openfl.ui.Mouse;
import openfl.ui.MouseCursor;

@:access(openfl.display.LoaderInfo)
@:access(openfl.display.Sprite)
@:access(openfl.display.Stage3D)
@:access(openfl.events.Event)
@:access(openfl.geom.Point)
@:access(openfl.ui.GameInput)
@:access(openfl.ui.Keyboard)
@:access(openfl.ui.Mouse)
class Stage extends DisplayObjectContainer {
	public var align:StageAlign;
	public var allowsFullScreen(default, null):Bool;
	public var allowsFullScreenInteractive(default, null):Bool;
	public var color(get, set):Null<Int>;
	public var contentsScaleFactor(get, never):Float;
	public var displayState(get, set):StageDisplayState;
	public var focus(get, set):InteractiveObject;
	public var frameRate(get, set):Float;
	public var fullScreenHeight(get, never):UInt;
	public var fullScreenWidth(get, never):UInt;
	public var quality:StageQuality;
	public var scaleMode:StageScaleMode;
	public var showDefaultContextMenu:Bool; // TODO: disable browser context menu with this?
	public var softKeyboardRect:Rectangle;
	public var stage3Ds(default, null):Vector<Stage3D>;
	public var stageFocusRect:Bool;
	public var stageHeight(default, null):Int;
	public var stageWidth(default, null):Int;
	public var window(default, null):Window;

	private var __cacheFocus:InteractiveObject;
	private var __color:Int;
	private var __colorKha:kha.Color;
	private var __contentsScaleFactor:Float;
	private var __dirty:Bool;
	private var __displayMatrix:Matrix;
	private var __displayState:StageDisplayState;
	private var __dragBounds:Rectangle;
	private var __dragObject:Sprite;
	private var __dragOffsetX:Float;
	private var __dragOffsetY:Float;
	private var __focus:InteractiveObject;
	private var __fullscreen:Bool;
	private var __invalidated:Bool;
	private var __lastClickTime:Int;
	private var __logicalWidth:Int;
	private var __logicalHeight:Int;
	private var __macKeyboard:Bool;
	private var __mouseDownLeft:InteractiveObject;
	private var __mouseDownMiddle:InteractiveObject;
	private var __mouseDownRight:InteractiveObject;
	private var __mouseOverTarget:InteractiveObject;
	private var __mouseX:Float;
	private var __mouseY:Float;
	private var __primaryTouchId:Int = -1;
	private var __renderer:GLRenderer;
	private var __rendering:Bool;
	private var __rollOutStack:Array<DisplayObject>;
	private var __mouseOutStack:Array<DisplayObject>;
	private var __stack:Array<DisplayObject>;
	private var __touchData:Map<Int, TouchData>;
	private var __wasFullscreen:Bool;

	public function new(window:Window) {
		super();

		this.window = window;
		this.color = 0xFFFFFF;
		this.name = null;

		__contentsScaleFactor = window.scale;
		__displayState = NORMAL;
		__mouseX = 0;
		__mouseY = 0;
		__lastClickTime = 0;
		__logicalWidth = 0;
		__logicalHeight = 0;
		__displayMatrix = new Matrix();
		__renderDirty = true;
		__wasFullscreen = window.fullscreen;

		stage3Ds = new Vector();
		stage3Ds.push(new Stage3D());

		__resize();

		this.stage = this;

		align = StageAlign.TOP_LEFT;
		allowsFullScreen = false;
		allowsFullScreenInteractive = false;
		quality = StageQuality.HIGH;
		scaleMode = StageScaleMode.NO_SCALE;
		showDefaultContextMenu = true;
		softKeyboardRect = new Rectangle();
		stageFocusRect = true;

		__macKeyboard = untyped __js__("/AppleWebKit/.test (navigator.userAgent) && /Mobile\\/\\w+/.test (navigator.userAgent) || /Mac/.test (navigator.platform)");

		__stack = [];
		__rollOutStack = [];
		__mouseOutStack = [];
		__touchData = new Map<Int, TouchData>();

		if (Lib.current.stage == null) {
			addChild(Lib.current);
		}
	}

	function __start() {
		kha.input.Mouse.get().notify(__onMouseDown, __onMouseUp, __onMouseMove, __onMouseWheel, __onMouseLeave);
		kha.input.Surface.get().notify(__onTouchStart, __onTouchEnd, __onTouchMove);

		for (gamepad in Gamepad.devices) {
			__onGamepadConnect(gamepad);
		}

		Gamepad.onConnect.add(__onGamepadConnect);

		window.onKeyDown.add(onKeyDown);
		window.onKeyUp.add(onKeyUp);

		__createRenderer();
	}

	public function invalidate():Void {
		__invalidated = true;
	}

	public override function localToGlobal(pos:Point):Point {
		return pos.clone();
	}

	public function onGamepadAxisMove(gamepad:Gamepad, axis:GamepadAxis, value:Float):Void {
		try {
			GameInput.__onGamepadAxisMove(gamepad, axis, value);
		} catch (e:Dynamic) {
			if (!__handleError(e)) js.Lib.rethrow();
		}
	}

	public function onGamepadButtonDown(gamepad:Gamepad, button:GamepadButton):Void {
		try {
			GameInput.__onGamepadButtonDown(gamepad, button);
		} catch (e:Dynamic) {
			if (!__handleError(e)) js.Lib.rethrow();
		}
	}

	public function onGamepadButtonUp(gamepad:Gamepad, button:GamepadButton):Void {
		try {
			GameInput.__onGamepadButtonUp(gamepad, button);
		} catch (e:Dynamic) {
			if (!__handleError(e)) js.Lib.rethrow();
		}
	}

	public function onGamepadConnect(gamepad:Gamepad):Void {
		try {
			GameInput.__onGamepadConnect(gamepad);
		} catch (e:Dynamic) {
			if (!__handleError(e)) js.Lib.rethrow();
		}
	}

	public function onGamepadDisconnect(gamepad:Gamepad):Void {
		try {
			GameInput.__onGamepadDisconnect(gamepad);
		} catch (e:Dynamic) {
			if (!__handleError(e)) js.Lib.rethrow();
		}
	}

	public function onKeyDown(keyCode:KeyCode, modifier:KeyModifier):Void {
		__onKey(KeyboardEvent.KEY_DOWN, keyCode, modifier);
	}

	public function onKeyUp(keyCode:KeyCode, modifier:KeyModifier):Void {
		__onKey(KeyboardEvent.KEY_UP, keyCode, modifier);
	}

	function __onMouseDown(button:Int, x:Float, y:Float) {
		__dispatchPendingMouseMove();

		var type = switch (button) {
			case 2: MouseEvent.MIDDLE_MOUSE_DOWN;
			case 1: MouseEvent.RIGHT_MOUSE_DOWN;
			default: MouseEvent.MOUSE_DOWN;
		}

		__onMouse(type, x, y);
	}

	function __onMouseUp(button:Int, x:Float, y:Float) {
		__dispatchPendingMouseMove();

		var type = switch (button) {
			case 2: MouseEvent.MIDDLE_MOUSE_UP;
			case 1: MouseEvent.RIGHT_MOUSE_UP;
			default: MouseEvent.MOUSE_UP;
		}

		__onMouse(type, x, y);
	}

	var hasPendingMouseMove = false;
	var pendingMouseMoveX:Int;
	var pendingMouseMoveY:Int;

	function __onMouseMove(x:Int, y:Int, moveX:Int, moveY:Int) {
		hasPendingMouseMove = true;
		pendingMouseMoveX = x;
		pendingMouseMoveY = y;
	}

	function __dispatchPendingMouseMove() {
		if (hasPendingMouseMove) {
			__onMouse(MouseEvent.MOUSE_MOVE, pendingMouseMoveX, pendingMouseMoveY);
			hasPendingMouseMove = false;
		}
	}

	function __onMouseWheel(delta:Int) {
		__dispatchPendingMouseMove();

		// TODO: maybe implement pixel to line delta conversion for html5 in Kha?
		delta = -Std.int(delta * window.scale);

		// Flash API docs say it can be a greater value when scrolling fast,
		// but I couldn't figure out how to get the `3` from Chrome's pixel delta (it's around 6 for me)
		if (delta < -3) delta = -3
		else if (delta > 3) delta = 3;

		var x = __mouseX;
		var y = __mouseY;

		var stack = [];
		var target:InteractiveObject = null;

		if (__hitTest(__mouseX, __mouseY, true, stack, true, this)) {
			target = cast stack[stack.length - 1];
		} else {
			target = this;
			stack = [this];
		}

		if (target == null)
			target = this;
		var targetPoint = Point.__pool.get();
		targetPoint.setTo(x, y);
		__displayMatrix.__transformInversePoint(targetPoint);

		__dispatchStack(MouseEvent.__create(MouseEvent.MOUSE_WHEEL, __mouseX, __mouseY, target.__globalToLocal(targetPoint, targetPoint), target, delta), stack);

		Point.__pool.release(targetPoint);
	}

	function __onMouseLeave() {
		if (MouseEvent.__buttonDown)
			return;
		__dispatchEvent(new Event(Event.MOUSE_LEAVE));
	}

	public function onRenderContextLost():Void {
		__renderer = null;

		for (stage3D in stage3Ds) {
			stage3D.__loseContext();
		}
	}

	public function onRenderContextRestored():Void {
		GLCompressedTextureFormats.reset();
		__createRenderer();
		__forceRenderDirty();
	}

	function __onTouchStart(touchId:Int, touchX:Int, touchY:Int) {
		if (__primaryTouchId == -1) {
			__primaryTouchId = touchId;
		}
		__onTouch(TouchEvent.TOUCH_BEGIN, touchId, touchX, touchY);
	}

	function __onTouchMove(touchId:Int, touchX:Int, touchY:Int) {
		__onTouch(TouchEvent.TOUCH_MOVE, touchId, touchX, touchY);
	}

	function __onTouchEnd(touchId:Int, touchX:Int, touchY:Int) {
		if (__primaryTouchId == touchId) {
			__primaryTouchId = -1;
		}
		__onTouch(TouchEvent.TOUCH_END, touchId, touchX, touchY);
	}

	public function onWindowClose():Void {
		this.window = null;

		__primaryTouchId = -1;
		__broadcastEvent(new Event(Event.DEACTIVATE));
	}

	public function onWindowFocusIn():Void {
		__renderDirty = true;
		__broadcastEvent(new Event(Event.ACTIVATE));

		focus = __cacheFocus;
	}

	public function onWindowFocusOut():Void {
		__primaryTouchId = -1;
		__broadcastEvent(new Event(Event.DEACTIVATE));

		var currentFocus = focus;
		focus = null;
		__cacheFocus = currentFocus;
	}

	public function onWindowFullscreen():Void {
		__resize();

		if (!__wasFullscreen) {
			__wasFullscreen = true;
			if (__displayState == NORMAL)
				__displayState = FULL_SCREEN_INTERACTIVE;
			__dispatchEvent(new FullScreenEvent(FullScreenEvent.FULL_SCREEN, false, false, true, true));
		}
	}

	public function onWindowResize(width:Int, height:Int):Void {
		__renderDirty = true;
		__resize();

		__handleFullScreenRestore();
	}

	public function onWindowRestore():Void {
		__handleFullScreenRestore();
	}

	inline function __handleFullScreenRestore() {
		if (__wasFullscreen && !window.fullscreen) {
			__wasFullscreen = false;
			__displayState = NORMAL;
			__dispatchEvent(new FullScreenEvent(FullScreenEvent.FULL_SCREEN, false, false, false, true));
		}
	}

	var currentUpdate:Float = 0;
	var lastUpdate:Float = 0;
	var nextUpdate:Float = 0;

	function __onFrame(framebuffer:kha.Framebuffer) {
		currentUpdate = Date.now().getTime();
		if (currentUpdate >= nextUpdate) {
			__dispatchPendingMouseMove();
			__render(Std.int(currentUpdate - lastUpdate));

			lastUpdate = currentUpdate;
			if (framePeriod < 0) {
				nextUpdate = currentUpdate;
			} else {
				nextUpdate = currentUpdate - (currentUpdate % framePeriod) + framePeriod;
			}
		}
		framebuffer.g2.begin();
		framebuffer.g2.drawImage(__renderer.backbuffer, 0, 0);
		framebuffer.g2.end();
	}

	function __render(deltaTime:Int) {
		if (__rendering)
			return;
		__rendering = true;

		if (__renderer != null && (Stage3D.__active || stage3Ds[0].__contextRequested)) {
			__renderer.begin();
			__renderer.clear();
			__renderer.renderStage3D();
			__renderDirty = true;
		}

		__broadcastEvent(new Event(Event.ENTER_FRAME));
		__broadcastEvent(new Event(Event.FRAME_CONSTRUCTED));
		__broadcastEvent(new Event(Event.EXIT_FRAME));

		if (__invalidated) {
			__invalidated = false;
			__broadcastEvent(new Event(Event.RENDER));
		}

		__renderable = true;

		__enterFrame(deltaTime);
		__traverse();

		if (__renderer != null #if !openfl_always_render && __renderDirty #end) {
			if (!Stage3D.__active) {
				__renderer.begin();
				__renderer.clear();
			}
			__renderer.render();
			__renderer.end();
		}

		__rendering = false;
	}

	private function __broadcastEvent(event:Event):Void {
		if (DisplayObject.__broadcastEvents.exists(event.type)) {
			var dispatchers = DisplayObject.__broadcastEvents.get(event.type);

			for (dispatcher in dispatchers) {
				// TODO: Way to resolve dispatching occurring if object not on stage
				// and there are multiple stage objects running in HTML5?

				if (dispatcher.stage == this || dispatcher.stage == null) {
					try {
						dispatcher.__dispatch(event);
					} catch (e:Dynamic) {
						if (!__handleError(e)) js.Lib.rethrow();
					}
				}
			}
		}
	}

	private function __createRenderer():Void {
		__renderer = new GLRenderer(this);
	}

	private override function __dispatchEvent(event:Event):Bool {
		try {
			return super.__dispatchEvent(event);
		} catch (e:Dynamic) {
			if (!__handleError(e)) js.Lib.rethrow();
			return false;
		}
	}

	private function __dispatchStack(event:Event, stack:Array<DisplayObject>):Void {
		try {
			var target:DisplayObject;
			var length = stack.length;

			if (length == 0) {
				event.eventPhase = EventPhase.AT_TARGET;
				target = event.target;
				target.__dispatch(event);
			} else {
				event.eventPhase = EventPhase.CAPTURING_PHASE;
				event.target = stack[stack.length - 1];

				for (i in 0...length - 1) {
					stack[i].__dispatch(event);

					if (event.__isCanceled) {
						return;
					}
				}

				event.eventPhase = EventPhase.AT_TARGET;
				target = event.target;
				target.__dispatch(event);

				if (event.__isCanceled) {
					return;
				}

				if (event.bubbles) {
					event.eventPhase = EventPhase.BUBBLING_PHASE;
					var i = length - 2;

					while (i >= 0) {
						stack[i].__dispatch(event);

						if (event.__isCanceled) {
							return;
						}

						i--;
					}
				}
			}
		} catch (e:Dynamic) {
			if (!__handleError(e)) js.Lib.rethrow();
		}
	}

	private function __dispatchTarget(target:EventDispatcher, event:Event):Bool {
		try {
			return target.__dispatchEvent(event);
		} catch (e:Dynamic) {
			if (!__handleError(e)) js.Lib.rethrow();
			return false;
		}
	}

	private function __drag(mouse:Point):Void {
		var parent = __dragObject.parent;
		if (parent != null) {
			parent.__getWorldTransform().__transformInversePoint(mouse);
		}

		var x = mouse.x + __dragOffsetX;
		var y = mouse.y + __dragOffsetY;

		if (__dragBounds != null) {
			if (x < __dragBounds.x) {
				x = __dragBounds.x;
			} else if (x > __dragBounds.right) {
				x = __dragBounds.right;
			}

			if (y < __dragBounds.y) {
				y = __dragBounds.y;
			} else if (y > __dragBounds.bottom) {
				y = __dragBounds.bottom;
			}
		}

		__dragObject.x = x;
		__dragObject.y = y;
	}

	private override function __getInteractive(stack:Array<DisplayObject>):Bool {
		if (stack != null) {
			stack.push(this);
		}

		return true;
	}

	private override function __globalToLocal(global:Point, local:Point):Point {
		if (global != local) {
			local.copyFrom(global);
		}

		return local;
	}

	private function __handleError(e:Dynamic):Bool {
		var event = new UncaughtErrorEvent(UncaughtErrorEvent.UNCAUGHT_ERROR, true, true, e);
		Lib.current.__loaderInfo.uncaughtErrorEvents.dispatchEvent(event);

		if (!event.__preventDefault) {
			try {
				var exc = @:privateAccess haxe.CallStack.lastException;
				if (exc != null && Reflect.hasField(exc, "stack") && exc.stack != null && exc.stack != "") {
					js.Browser.console.log(exc.stack);
					e.stack = exc.stack;
				} else {
					js.Browser.console.log(CallStack.toString(CallStack.callStack()));
				}
			} catch (_:Dynamic) {}
		}
		return event.__preventDefault;
	}

	private function __onKey(type:String, keyCode:KeyCode, modifier:KeyModifier):Void {
		__dispatchPendingMouseMove();

		MouseEvent.__altKey = modifier.altKey;
		MouseEvent.__commandKey = modifier.metaKey;
		MouseEvent.__ctrlKey = modifier.ctrlKey;
		MouseEvent.__shiftKey = modifier.shiftKey;

		var stack = new Array<DisplayObject>();

		if (__focus == null) {
			__getInteractive(stack);
		} else {
			__focus.__getInteractive(stack);
		}

		if (stack.length > 0) {
			var keyLocation = Keyboard.__getKeyLocation(keyCode);
			var keyCode = Keyboard.__convertKeyCode(keyCode);
			var charCode = Keyboard.__getCharCode(keyCode, modifier.shiftKey);

			// Flash Player events are not cancelable, should we make only some events (like APP_CONTROL_BACK) cancelable?

			var event = new KeyboardEvent(type, true, true, charCode, keyCode, keyLocation,
				__macKeyboard ? modifier.ctrlKey || modifier.metaKey : modifier.ctrlKey, modifier.altKey, modifier.shiftKey, modifier.ctrlKey,
				modifier.metaKey);

			stack.reverse();
			__dispatchStack(event, stack);

			if (event.__preventDefault) {
				if (type == KeyboardEvent.KEY_DOWN) {
					window.onKeyDown.cancel();
				} else {
					window.onKeyUp.cancel();
				}
			}
		}
	}

	private function __onGamepadConnect(gamepad:Gamepad):Void {
		onGamepadConnect(gamepad);

		gamepad.onAxisMove.add(onGamepadAxisMove.bind(gamepad));
		gamepad.onButtonDown.add(onGamepadButtonDown.bind(gamepad));
		gamepad.onButtonUp.add(onGamepadButtonUp.bind(gamepad));
		gamepad.onDisconnect.add(onGamepadDisconnect.bind(gamepad));
	}

	function __onMouse(type:String, x:Float, y:Float) {
		var targetPoint = Point.__pool.get();
		targetPoint.setTo(x * window.scale, y * window.scale);
		__displayMatrix.__transformInversePoint(targetPoint);

		__mouseX = targetPoint.x;
		__mouseY = targetPoint.y;

		var stack = [];
		var target:InteractiveObject = null;

		if (__hitTest(__mouseX, __mouseY, true, stack, true, this)) {
			target = cast stack[stack.length - 1];
		} else {
			target = this;
			stack = [this];
		}

		if (target == null)
			target = this;

		var clickType = null;

		switch (type) {
			case MouseEvent.MOUSE_DOWN:
				__maybeChangeFocus(target);
				__mouseDownLeft = target;
				MouseEvent.__buttonDown = true;

			case MouseEvent.MIDDLE_MOUSE_DOWN:
				__mouseDownMiddle = target;

			case MouseEvent.RIGHT_MOUSE_DOWN:
				__mouseDownRight = target;

			case MouseEvent.MOUSE_UP:
				if (__mouseDownLeft != null) {
					MouseEvent.__buttonDown = false;

					if (__mouseX < 0 || __mouseY < 0 || __mouseX > stageWidth || __mouseY > stageHeight) {
						__dispatchEvent(MouseEvent.__create(MouseEvent.RELEASE_OUTSIDE, __mouseX, __mouseY, new Point(__mouseX, __mouseY), this));
					} else if (__mouseDownLeft == target) {
						clickType = MouseEvent.CLICK;
					}

					__mouseDownLeft = null;
				}

			case MouseEvent.MIDDLE_MOUSE_UP:
				if (__mouseDownMiddle == target) {
					clickType = MouseEvent.MIDDLE_CLICK;
				}

				__mouseDownMiddle = null;

			case MouseEvent.RIGHT_MOUSE_UP:
				if (__mouseDownRight == target) {
					clickType = MouseEvent.RIGHT_CLICK;
				}

				__mouseDownRight = null;

			default:
		}

		var localPoint = Point.__pool.get();

		__dispatchStack(MouseEvent.__create(type, __mouseX, __mouseY, target.__globalToLocal(targetPoint, localPoint), target), stack);

		if (clickType != null) {
			__dispatchStack(MouseEvent.__create(clickType, __mouseX, __mouseY, target.__globalToLocal(targetPoint, localPoint), target), stack);

			if (type == MouseEvent.MOUSE_UP && cast(target, openfl.display.InteractiveObject).doubleClickEnabled) {
				var currentTime = Lib.getTimer();
				if (currentTime - __lastClickTime < 500) {
					__dispatchStack(MouseEvent.__create(MouseEvent.DOUBLE_CLICK, __mouseX, __mouseY, target.__globalToLocal(targetPoint, localPoint),
						target),
						stack);
					__lastClickTime = 0;
				} else {
					__lastClickTime = currentTime;
				}
			}
		}

		if (Mouse.__cursor == MouseCursor.AUTO) {
			var cursor = null;

			if (__mouseDownLeft != null) {
				cursor = __mouseDownLeft.__getCursor();
			} else {
				for (target in stack) {
					cursor = target.__getCursor();

					if (cursor != null) {
						InternalMouse.setCursor(cursor);
						break;
					}
				}
			}

			if (cursor == null) {
				InternalMouse.setCursor(ARROW);
			}
		}

		var event;

		if (target != __mouseOverTarget) {
			if (__mouseOverTarget != null) {
				event = MouseEvent.__create(MouseEvent.MOUSE_OUT, __mouseX, __mouseY, __mouseOverTarget.__globalToLocal(targetPoint, localPoint),
					cast __mouseOverTarget);
				__dispatchStack(event, __mouseOutStack);
			}
		}

		// TODO: carefully pick https://github.com/openfl/openfl/commit/7b55ccad4882fd925e547349fddc7954e3edc56d here
		for (target in __rollOutStack) {
			if (stack.indexOf(target) == -1) {
				__rollOutStack.remove(target);

				event = MouseEvent.__create(MouseEvent.ROLL_OUT, __mouseX, __mouseY, __mouseOverTarget.__globalToLocal(targetPoint, localPoint),
					cast __mouseOverTarget);
				event.bubbles = false;
				__dispatchTarget(target, event);
			}
		}

		for (target in stack) {
			if (__rollOutStack.indexOf(target) == -1 && __mouseOverTarget != null) {
				if (target.hasEventListener(MouseEvent.ROLL_OVER)) {
					event = MouseEvent.__create(MouseEvent.ROLL_OVER, __mouseX, __mouseY, __mouseOverTarget.__globalToLocal(targetPoint, localPoint),
						cast target);
					event.bubbles = false;
					__dispatchTarget(target, event);
				}

				if (target.hasEventListener(MouseEvent.ROLL_OUT)) {
					__rollOutStack.push(target);
				}
			}
		}

		if (target != __mouseOverTarget) {
			if (target != null) {
				event = MouseEvent.__create(MouseEvent.MOUSE_OVER, __mouseX, __mouseY, target.__globalToLocal(targetPoint, localPoint), cast target);
				__dispatchStack(event, stack);
			}

			__mouseOverTarget = target;
			__mouseOutStack = stack;
		}

		if (__dragObject != null) {
			__drag(targetPoint);

			var dropTarget = null;

			if (__mouseOverTarget == __dragObject) {
				var cacheMouseEnabled = __dragObject.mouseEnabled;
				var cacheMouseChildren = __dragObject.mouseChildren;

				__dragObject.mouseEnabled = false;
				__dragObject.mouseChildren = false;

				var stack = [];

				if (__hitTest(__mouseX, __mouseY, true, stack, true, this)) {
					dropTarget = stack[stack.length - 1];
				}

				__dragObject.mouseEnabled = cacheMouseEnabled;
				__dragObject.mouseChildren = cacheMouseChildren;
			} else if (__mouseOverTarget != this) {
				dropTarget = __mouseOverTarget;
			}

			__dragObject.dropTarget = dropTarget;
		}

		Point.__pool.release(targetPoint);
		Point.__pool.release(localPoint);
	}

	function __maybeChangeFocus(target:InteractiveObject) {
		var currentFocus = __focus;
		var newFocus = if (target.__allowMouseFocus()) target else null;
		if (currentFocus != newFocus) {
			if (currentFocus != null) {
				// we always set `event.relatedObject` to `target` even if it's not focusable, because that's how it is in Flash
				var event = new FocusEvent(FocusEvent.MOUSE_FOCUS_CHANGE, true, true, target, false, 0);
				currentFocus.dispatchEvent(event);
				if (event.isDefaultPrevented()) {
					return;
				}
			}
			focus = newFocus;
		}
	}

	private function __onTouch(type:String, touchId:Int, touchX:Int, touchY:Int):Void {
		var targetPoint = Point.__pool.get();
		targetPoint.setTo(Math.round(touchX * window.scale), Math.round(touchY * window.scale));
		__displayMatrix.__transformInversePoint(targetPoint);

		var touchX = targetPoint.x;
		var touchY = targetPoint.y;

		var stack = [];
		var target:InteractiveObject = null;

		if (__hitTest(touchX, touchY, false, stack, true, this)) {
			target = cast stack[stack.length - 1];
		} else {
			target = this;
			stack = [this];
		}

		if (target == null)
			target = this;

		var touchData;
		if (__touchData.exists(touchId)) {
			touchData = __touchData.get(touchId);
		} else {
			touchData = TouchData.__pool.get();
			__touchData.set(touchId, touchData);
		}

		var touchType = null;
		var releaseTouchData:Bool = false;

		switch (type) {
			case TouchEvent.TOUCH_BEGIN:
				touchData.touchDownTarget = target;

			case TouchEvent.TOUCH_END:
				if (touchData.touchDownTarget == target) {
					touchType = TouchEvent.TOUCH_TAP;
				}

				touchData.touchDownTarget = null;
				releaseTouchData = true;

			default:
		}

		var localPoint = Point.__pool.get();
		var isPrimaryTouchPoint:Bool = (__primaryTouchId == touchId);
		var touchEvent = TouchEvent.__create(type, touchX, touchY, target.__globalToLocal(targetPoint, localPoint), target);
		touchEvent.touchPointID = touchId;
		touchEvent.isPrimaryTouchPoint = isPrimaryTouchPoint;

		__dispatchStack(touchEvent, stack);

		if (touchType != null) {
			touchEvent = TouchEvent.__create(touchType, touchX, touchY, target.__globalToLocal(targetPoint, localPoint), target);
			touchEvent.touchPointID = touchId;
			touchEvent.isPrimaryTouchPoint = isPrimaryTouchPoint;

			__dispatchStack(touchEvent, stack);
		}

		var touchOverTarget = touchData.touchOverTarget;

		if (target != touchOverTarget && touchOverTarget != null) {
			touchEvent = TouchEvent.__create(TouchEvent.TOUCH_OUT, touchX, touchY, touchOverTarget.__globalToLocal(targetPoint, localPoint), touchOverTarget);
			touchEvent.touchPointID = touchId;
			touchEvent.isPrimaryTouchPoint = isPrimaryTouchPoint;

			__dispatchTarget(touchOverTarget, touchEvent);
		}

		var touchOutStack = touchData.rollOutStack;

		for (target in touchOutStack) {
			if (stack.indexOf(target) == -1) {
				touchOutStack.remove(target);

				touchEvent = TouchEvent.__create(TouchEvent.TOUCH_ROLL_OUT, touchX, touchY, touchOverTarget.__globalToLocal(targetPoint, localPoint), touchOverTarget);
				touchEvent.touchPointID = touchId;
				touchEvent.isPrimaryTouchPoint = isPrimaryTouchPoint;
				touchEvent.bubbles = false;

				__dispatchTarget(target, touchEvent);
			}
		}

		for (target in stack) {
			if (touchOutStack.indexOf(target) == -1) {
				if (target.hasEventListener(TouchEvent.TOUCH_ROLL_OVER)) {
					touchEvent = TouchEvent.__create(TouchEvent.TOUCH_ROLL_OVER, touchX, touchY, touchOverTarget.__globalToLocal(targetPoint, localPoint), cast target);
					touchEvent.touchPointID = touchId;
					touchEvent.isPrimaryTouchPoint = isPrimaryTouchPoint;
					touchEvent.bubbles = false;

					__dispatchTarget(target, touchEvent);
				}

				if (target.hasEventListener(TouchEvent.TOUCH_ROLL_OUT)) {
					touchOutStack.push(target);
				}
			}
		}

		if (target != touchOverTarget) {
			if (target != null) {
				touchEvent = TouchEvent.__create(TouchEvent.TOUCH_OVER, touchX, touchY, target.__globalToLocal(targetPoint, localPoint), target);
				touchEvent.touchPointID = touchId;
				touchEvent.isPrimaryTouchPoint = isPrimaryTouchPoint;
				touchEvent.bubbles = true;

				__dispatchTarget(target, touchEvent);
			}

			touchData.touchOverTarget = target;
		}

		Point.__pool.release(targetPoint);
		Point.__pool.release(localPoint);

		if (releaseTouchData) {
			__touchData.remove(touchId);
			touchData.reset();
			TouchData.__pool.release(touchData);
		}
	}

	private function __resize():Void {
		var cacheWidth = stageWidth;
		var cacheHeight = stageHeight;

		var windowWidth = Std.int(window.width * window.scale);
		var windowHeight = Std.int(window.height * window.scale);

		__logicalWidth = window.width;
		__logicalHeight = window.height;

		__displayMatrix.identity();

		if (__logicalWidth == 0 && __logicalHeight == 0) {
			stageWidth = windowWidth;
			stageHeight = windowHeight;
		} else {
			stageWidth = __logicalWidth;
			stageHeight = __logicalHeight;

			var scaleX = windowWidth / stageWidth;
			var scaleY = windowHeight / stageHeight;
			var targetScale = Math.min(scaleX, scaleY);

			var offsetX = Math.round((windowWidth - (stageWidth * targetScale)) / 2);
			var offsetY = Math.round((windowHeight - (stageHeight * targetScale)) / 2);

			__displayMatrix.scale(targetScale, targetScale);
			__displayMatrix.translate(offsetX, offsetY);
		}

		if (__renderer != null) {
			__renderer.resize(windowWidth, windowHeight);
		}

		if (stageWidth != cacheWidth || stageHeight != cacheHeight) {
			__dispatchEvent(new Event(Event.RESIZE));
		}

		if (__contentsScaleFactor != window.scale && __renderer != null) {
			__contentsScaleFactor = window.scale;

			@:privateAccess (__renderer.renderSession).pixelRatio = window.scale;

			__forceRenderDirty();
		}
	}

	private function __startDrag(sprite:Sprite, lockCenter:Bool, bounds:Rectangle):Void {
		if (bounds == null) {
			__dragBounds = null;
		} else {
			__dragBounds = new Rectangle();

			var right = bounds.right;
			var bottom = bounds.bottom;
			__dragBounds.x = right < bounds.x ? right : bounds.x;
			__dragBounds.y = bottom < bounds.y ? bottom : bounds.y;
			__dragBounds.width = Math.abs(bounds.width);
			__dragBounds.height = Math.abs(bounds.height);
		}

		__dragObject = sprite;

		if (__dragObject != null) {
			if (lockCenter) {
				__dragOffsetX = 0;
				__dragOffsetY = 0;
			} else {
				var mouse = Point.__pool.get();
				mouse.setTo(mouseX, mouseY);
				var parent = __dragObject.parent;

				if (parent != null) {
					parent.__getWorldTransform().__transformInversePoint(mouse);
				}

				__dragOffsetX = __dragObject.x - mouse.x;
				__dragOffsetY = __dragObject.y - mouse.y;
				Point.__pool.release(mouse);
			}
		}
	}

	private function __stopDrag(sprite:Sprite):Void {
		__dragBounds = null;
		__dragObject = null;
	}

	public override function __update(transformOnly:Bool, updateChildren:Bool, ?resetUpdateDirty:Bool = false):Void {
		if (transformOnly) {
			if (__transformDirty) {
				super.__update(true, updateChildren, resetUpdateDirty);

				if (updateChildren) {
					__transformDirty = false;
					// __dirty = true;
				}
			}
		} else {
			if (__transformDirty || __renderDirty) {
				super.__update(false, updateChildren, resetUpdateDirty);
				if (updateChildren) {
					// __dirty = false;
				}
			}
		}
	}

	// Get & Set Methods

	private function get_color():Null<Int> {
		return __color;
	}

	private function set_color(value:Null<Int>):Null<Int> {
		if (value == null) {
			__colorKha = kha.Color.Transparent;
		} else {
			var r = (value & 0xFF0000) >>> 16;
			var g = (value & 0x00FF00) >>> 8;
			var b = (value & 0x0000FF);
			__colorKha = kha.Color.fromBytes(r, g, b);
		}
		return __color = value;
	}

	private function get_contentsScaleFactor():Float {
		return __contentsScaleFactor;
	}

	private function get_displayState():StageDisplayState {
		return __displayState;
	}

	private function set_displayState(value:StageDisplayState):StageDisplayState {
		switch (value) {
			case NORMAL:
				if (window.fullscreen) {
					window.fullscreen = false;
				}

			default:
				if (!window.fullscreen) {
					window.fullscreen = true;
				}
		}
		return __displayState = value;
	}

	private function get_focus():InteractiveObject {
		return __focus;
	}

	private function set_focus(value:InteractiveObject):InteractiveObject {
		if (value != __focus) {
			var oldFocus = __focus;
			__focus = value;
			__cacheFocus = value;

			if (oldFocus != null) {
				var event = new FocusEvent(FocusEvent.FOCUS_OUT, true, false, value, false, 0);
				var stack = new Array<DisplayObject>();
				oldFocus.__getInteractive(stack);
				stack.reverse();
				__dispatchStack(event, stack);
			}

			if (value != null) {
				var event = new FocusEvent(FocusEvent.FOCUS_IN, true, false, oldFocus, false, 0);
				var stack = new Array<DisplayObject>();
				value.__getInteractive(stack);
				stack.reverse();
				__dispatchStack(event, stack);
			}
		}

		return value;
	}

	var framePeriod:Float = -1;

	private function get_frameRate():Float {
		if (framePeriod < 0) {
			return 60;
		} else if (framePeriod == 1000) {
			return 0;
		} else {
			return 1000 / framePeriod;
		}
	}

	private function set_frameRate(value:Float):Float {
		if (value >= 60) {
			framePeriod = -1;
		} else if (value > 0) {
			framePeriod = 1000 / value;
		} else {
			framePeriod = 1000;
		}
		return value;
	}

	inline function get_fullScreenHeight():UInt {
		return kha.Display.primary.height;
	}

	inline function get_fullScreenWidth():UInt {
		return kha.Display.primary.width;
	}

	private override function set_height(value:Float):Float {
		return this.height;
	}

	private override function get_mouseX():Float {
		return __mouseX;
	}

	private override function get_mouseY():Float {
		return __mouseY;
	}

	private override function set_rotation(value:Float):Float {
		return 0;
	}

	private override function set_scaleX(value:Float):Float {
		return 0;
	}

	private override function set_scaleY(value:Float):Float {
		return 0;
	}

	private override function set_transform(value:Transform):Transform {
		return this.transform;
	}

	private override function set_width(value:Float):Float {
		return this.width;
	}

	private override function set_x(value:Float):Float {
		return 0;
	}

	private override function set_y(value:Float):Float {
		return 0;
	}
}

private class TouchData {
	public static final __pool = new openfl._internal.utils.ObjectPool(TouchData.new, data -> data.reset());

	public final rollOutStack = new Array<DisplayObject>();
	public var touchDownTarget:Null<InteractiveObject>;
	public var touchOverTarget:Null<InteractiveObject>;

	public function new() {}

	public function reset() {
		touchDownTarget = null;
		touchOverTarget = null;
		rollOutStack.resize(0);
	}
}
