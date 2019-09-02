package openfl._internal.app;

import openfl.display.Sprite;
import js.html.KeyboardEvent;
import js.Browser;
import openfl._internal.ui.GamepadAxis;
import openfl._internal.ui.KeyCode;
import openfl._internal.ui.KeyModifier;
import openfl._internal.ui.Gamepad;
import openfl._internal.ui.GamepadButton;
import openfl._internal.ui.Window;
import openfl.display.Stage;

@:access(openfl.display.DisplayObject)
@:access(openfl.display.LoaderInfo)
@:access(openfl._internal.ui.Gamepad)
@:access(openfl._internal.ui.Window)
class Application {
	public var window(default, null):Window;

	/**
	 * The current Application instance that is executing
	**/
	public static var current(default, null):Application;

	/**
	 * Configuration values for the application, such as window options or a package name
	**/
	public var config(default, null):Config;

	public var stage:Stage;

	var gameDeviceCache = new Map<Int, GameDeviceData>();

	public static function start() {
		var app = new Application({});
		app._start();
	}

	function new(config) {
		this.config = config;
		Application.current = this;
	}

	function _start() {
		window = new Window(this);

		var root = new Sprite();
		root.__loaderInfo = openfl.display.LoaderInfo.create(null);
		root.__loaderInfo.content = root;
		@:privateAccess Lib.current = root;

		stage = new Stage(window);
		window.stage = stage;

		if (Reflect.hasField(config, "parameters")) {
			stage.loaderInfo.parameters = config.parameters;
		}

		stage.__start();

		Browser.window.addEventListener("keydown", handleKeyEvent, false);
		Browser.window.addEventListener("keyup", handleKeyEvent, false);
		Browser.window.addEventListener("focus", handleWindowEvent, false);
		Browser.window.addEventListener("blur", handleWindowEvent, false);
		Browser.window.addEventListener("resize", handleWindowEvent, false);
		Browser.window.addEventListener("beforeunload", handleWindowEvent, false);

		// Disable image drag on Firefox
		Browser.document.addEventListener("dragstart", function(e) {
			if (e.target.nodeName.toLowerCase() == "img") {
				e.preventDefault();
				return false;
			}
			return true;
		}, false);


		kha.System.notifyOnFrames(framebuffers -> onFrame(framebuffers[0]));
	}

	function handleKeyEvent(event:KeyboardEvent) {
		// space and arrow keys
		// switch (event.keyCode) {
		// 	case 32, 37, 38, 39, 40: event.preventDefault ();
		// }

		// TODO: Use event.key instead where supported

		var keyCode = convertKeyCode(event.keyCode != null ? event.keyCode : event.which);
		var modifier = (event.shiftKey ? (KeyModifier.SHIFT) : 0) | (event.ctrlKey ? (KeyModifier.CTRL) : 0) | (event.altKey ? (KeyModifier.ALT) : 0) | (event.metaKey ? (KeyModifier.META) : 0);

		if (event.type == "keydown") {
			window.onKeyDown.dispatch(keyCode, modifier);
			if (window.onKeyDown.canceled) {
				event.preventDefault();
			}
		} else {
			window.onKeyUp.dispatch(keyCode, modifier);
			if (window.onKeyUp.canceled) {
				event.preventDefault();
			}
		}
	}

	function convertKeyCode(keyCode:Int):KeyCode {
		if (keyCode >= 65 && keyCode <= 90) {
			return keyCode + 32;
		}

		return switch (keyCode) {
			case 16: KeyCode.LEFT_SHIFT;
			case 17: KeyCode.LEFT_CTRL;
			case 18: KeyCode.LEFT_ALT;
			case 20: KeyCode.CAPS_LOCK;
			case 33: KeyCode.PAGE_UP;
			case 34: KeyCode.PAGE_DOWN;
			case 35: KeyCode.END;
			case 36: KeyCode.HOME;
			case 37: KeyCode.LEFT;
			case 38: KeyCode.UP;
			case 39: KeyCode.RIGHT;
			case 40: KeyCode.DOWN;
			case 45: KeyCode.INSERT;
			case 46: KeyCode.DELETE;
			case 96: KeyCode.NUMPAD_0;
			case 97: KeyCode.NUMPAD_1;
			case 98: KeyCode.NUMPAD_2;
			case 99: KeyCode.NUMPAD_3;
			case 100: KeyCode.NUMPAD_4;
			case 101: KeyCode.NUMPAD_5;
			case 102: KeyCode.NUMPAD_6;
			case 103: KeyCode.NUMPAD_7;
			case 104: KeyCode.NUMPAD_8;
			case 105: KeyCode.NUMPAD_9;
			case 106: KeyCode.NUMPAD_MULTIPLY;
			case 107: KeyCode.NUMPAD_PLUS;
			case 109: KeyCode.NUMPAD_MINUS;
			case 110: KeyCode.NUMPAD_PERIOD;
			case 111: KeyCode.NUMPAD_DIVIDE;
			case 112: KeyCode.F1;
			case 113: KeyCode.F2;
			case 114: KeyCode.F3;
			case 115: KeyCode.F4;
			case 116: KeyCode.F5;
			case 117: KeyCode.F6;
			case 118: KeyCode.F7;
			case 119: KeyCode.F8;
			case 120: KeyCode.F9;
			case 121: KeyCode.F10;
			case 122: KeyCode.F11;
			case 123: KeyCode.F12;
			case 124: KeyCode.F13;
			case 125: KeyCode.F14;
			case 126: KeyCode.F15;
			case 144: KeyCode.NUM_LOCK;
			case 186: KeyCode.SEMICOLON;
			case 187: KeyCode.EQUALS;
			case 188: KeyCode.COMMA;
			case 189: KeyCode.MINUS;
			case 190: KeyCode.PERIOD;
			case 191: KeyCode.SLASH;
			case 192: KeyCode.GRAVE;
			case 219: KeyCode.LEFT_BRACKET;
			case 220: KeyCode.BACKSLASH;
			case 221: KeyCode.RIGHT_BRACKET;
			case 222: KeyCode.SINGLE_QUOTE;
			case _: keyCode;
		};
	}

	function handleWindowEvent(event:js.html.Event) {
		switch (event.type) {
			case "focus":
				// TODO: discuss text input with Rob (because System.notifyOnApplicationState will make canvas and text input fight for focus, because it subscribes to canvas focus)
				stage.onWindowFocusIn();

			case "blur":
				stage.onWindowFocusOut();

			case "resize":
				window.handleResizeEvent(event);

			case "beforeunload":
				if (!event.defaultPrevented) {
					stage.onWindowClose();
					window = null;
				}
		}
	}

	function onFrame(framebuffer:kha.Framebuffer) {
		if (window == null) return; // TODO
		window.updateSize();
		updateGameDevices();
		stage.__onFrame(framebuffer);
	}

	function updateGameDevices() {
		var devices = Gamepad.__getDeviceData();
		if (devices == null)
			return;

		var id, gamepad, data:Null<js.html.Gamepad>, cache;

		for (i in 0...devices.length) {
			id = i;
			data = devices[id];

			if (data == null)
				continue;

			if (!gameDeviceCache.exists(id)) {
				cache = new GameDeviceData();
				cache.id = id;
				cache.connected = data.connected;

				for (i in 0...data.buttons.length) {
					cache.buttons.push(data.buttons[i].value);
				}

				for (i in 0...data.axes.length) {
					cache.axes.push(data.axes[i]);
				}

				gameDeviceCache.set(id, cache);

				if (data.connected) {
					Gamepad.__connect(id);
				}
			}

			cache = gameDeviceCache.get(id);

			gamepad = Gamepad.devices.get(id);

			if (data.connected) {
				var button:GamepadButton;
				var value:Float;

				for (i in 0...data.buttons.length) {
					value = data.buttons[i].value;

					if (value != cache.buttons[i]) {
						if (i == 6) {
							gamepad.onAxisMove.dispatch(GamepadAxis.TRIGGER_LEFT, value);
						} else if (i == 7) {
							gamepad.onAxisMove.dispatch(GamepadAxis.TRIGGER_RIGHT, value);
						} else {
							button = switch (i) {
								case 0: GamepadButton.A;
								case 1: GamepadButton.B;
								case 2: GamepadButton.X;
								case 3: GamepadButton.Y;
								case 4: GamepadButton.LEFT_SHOULDER;
								case 5: GamepadButton.RIGHT_SHOULDER;
								case 8: GamepadButton.BACK;
								case 9: GamepadButton.START;
								case 10: GamepadButton.LEFT_STICK;
								case 11: GamepadButton.RIGHT_STICK;
								case 12: GamepadButton.DPAD_UP;
								case 13: GamepadButton.DPAD_DOWN;
								case 14: GamepadButton.DPAD_LEFT;
								case 15: GamepadButton.DPAD_RIGHT;
								case 16: GamepadButton.GUIDE;
								default: continue;
							}

							if (value > 0) {
								gamepad.onButtonDown.dispatch(button);
							} else {
								gamepad.onButtonUp.dispatch(button);
							}
						}

						cache.buttons[i] = value;
					}
				}

				for (i in 0...data.axes.length) {
					if (data.axes[i] != cache.axes[i]) {
						gamepad.onAxisMove.dispatch(i, data.axes[i]);
						cache.axes[i] = data.axes[i];
					}
				}
			} else if (cache.connected) {
				cache.connected = false;
				Gamepad.__disconnect(id);
			}
		}
	}

	static function polyfillPerformance() {
		js.Syntax.code("
			if ('performance' in window == false) {
				window.performance = {};
			}

			if ('now' in window.performance == false) {
				var offset = Date.now();
				if (performance.timing && performance.timing.navigationStart) {
					offset = performance.timing.navigationStart
				}
				window.performance.now = function now() {
					return Date.now() - offset;
				}
			}
		");
	}

	static function __init__() polyfillPerformance();
}

private class GameDeviceData {
	public var connected:Bool;
	public var id:Int;
	public var buttons:Array<Float>;
	public var axes:Array<Float>;

	public function new() {
		connected = true;
		buttons = [];
		axes = [];
	}
}
