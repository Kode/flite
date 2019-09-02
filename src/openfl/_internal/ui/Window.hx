package openfl._internal.ui;

import haxe.Timer;
import js.html.FocusEvent;
import js.html.InputElement;
import js.html.InputEvent;
import js.html.Event as JsEvent;
import js.Browser;
import openfl._internal.app.Application;
import openfl._internal.app.Event;
import openfl._internal.system.Clipboard;
import openfl._internal.graphics.Image;
import openfl.display.Stage;

typedef CopyDataProvider = String->Void;

class Window {
	public var application(default, null):Application;
	public var enableTextEvents(default, set):Bool;
	public var fullscreen(get, set):Bool;
	public var onKeyDown = new Event<KeyCode->KeyModifier->Void>();
	public var onKeyUp = new Event<KeyCode->KeyModifier->Void>();
	public var onTextInput = new Event<String->Void>();
	public var onTextCopy = new Event<CopyDataProvider->Void>();
	public var onTextCut = new Event<CopyDataProvider->Void>();
	public var onTextPaste = new Event<String->Void>();
	public var scale(default, null):Float;
	public var stage(default, null):Stage;

	public var width(default, null):Int;
	public var height(default, null):Int;

	static var dummyCharacter = String.fromCharCode(127);
	static var textInput:InputElement;

	var cacheElementHeight:Float;
	var cacheElementWidth:Float;
	var isFullscreen:Bool;
	var requestedFullscreen:Bool;

	var __fullscreen:Bool;

	public function new(application:Application) {
		this.application = application;

		__fullscreen = false;
		updateScale();

		var canvas = kha.SystemImpl.khanvas;

		width = canvas.clientWidth;
		height = canvas.clientHeight;
		cacheElementWidth = width;
		cacheElementHeight = height;
		canvas.width = Math.round(width * scale);
		canvas.height = Math.round(height * scale);
		canvas.style.width = width + "px";
		canvas.style.height = height + "px";

		kha.input.Gamepad.notifyOnConnect(Gamepad.__connect, Gamepad.__disconnect);
		kha.System.notifyOnCutCopyPaste(onCut, onCopy, onPaste);

		canvas.addEventListener("webglcontextlost", handleContextLost, false);
		canvas.addEventListener("webglcontextrestored", handleContextRestored, false);
	}

	inline function updateScale() {
		scale = Browser.window.devicePixelRatio;
	}

	function handleContextLost(event:JsEvent) {
		event.preventDefault();
		stage.onRenderContextLost();
	}

	function handleContextRestored(event:JsEvent) {
		stage.onRenderContextRestored();
	}

	public function readPixels():Image {
		var canvas = kha.SystemImpl.khanvas;

		var tempCanvas = js.Browser.document.createCanvasElement();
		tempCanvas.width = Std.int(canvas.width);
		tempCanvas.height = Std.int(canvas.height);
		tempCanvas.getContext2d().drawImage(canvas, 0, 0);

		return Image.fromCanvas(tempCanvas);
	}

	function updateSize() {
		var canvas = kha.SystemImpl.khanvas;
		var elementWidth = canvas.clientWidth;
		var elementHeight = canvas.clientHeight;
		if (elementWidth != cacheElementWidth || elementHeight != cacheElementHeight) {
			cacheElementWidth = elementWidth;
			cacheElementHeight = elementHeight;
			if (width != elementWidth || height != elementHeight) {
				width = elementWidth;
				height = elementHeight;
				stage.onWindowResize(elementWidth, elementHeight);
			}
		}
	}

	function set_enableTextEvents(value:Bool):Bool {
		if (value) {
			if (textInput == null) {
				textInput = Browser.document.createInputElement();
				textInput.type = 'text';
				textInput.style.position = 'absolute';
				textInput.style.opacity = "0";
				textInput.style.color = "transparent";
				textInput.value = dummyCharacter; // See: handleInputEvent()

				(cast textInput).autocapitalize = "off";
				(cast textInput).autocorrect = "off";
				textInput.autocomplete = "off";

				// TODO: Position for mobile browsers better

				textInput.style.left = "0px";
				textInput.style.top = "50%";

				if (~/(iPad|iPhone|iPod).*OS 8_/gi.match(Browser.window.navigator.userAgent)) {
					textInput.style.fontSize = "0px";
					textInput.style.width = '0px';
					textInput.style.height = '0px';
				} else {
					textInput.style.width = '1px';
					textInput.style.height = '1px';
				}

				textInput.style.pointerEvents = 'none';
				textInput.style.zIndex = "-10000000";

				kha.SystemImpl.khanvas.parentElement.appendChild(textInput);
			}

			if (!enableTextEvents) {
				textInput.addEventListener('input', handleInputEvent, true);
				textInput.addEventListener('blur', handleFocusEvent, true);
			}

			textInput.focus();
			textInput.select();
		} else {
			if (textInput != null) {
				textInput.removeEventListener('input', handleInputEvent, true);
				textInput.removeEventListener('blur', handleFocusEvent, true);

				textInput.blur();
			}
		}
		return enableTextEvents = value;
	}

	function onCopy():String {
		if (settingSystemClipboard) {
			return Clipboard.text;
		} else {
			var result:String = null;
			onTextCopy.dispatch(function(string) {
				Clipboard.setText(string, false);
				result = string;
			});
			return result;
		}
	}

	function onCut():String {
		var result:String = null;
		onTextCut.dispatch(function(string) {
			Clipboard.setText(string, false);
			result = string;
		});
		return result;
	}

	function onPaste(text:String) {
		if (text == "") return;

		text = normalizeInputNewlines(text);
		Clipboard.setText(text, false);
		if (enableTextEvents) {
			onTextPaste.dispatch(text);
		}
	}

	function handleFocusEvent(event:FocusEvent) {
		if (enableTextEvents) {
			Timer.delay(() -> textInput.focus(), 20);
		}
	}

	function handleInputEvent(event:InputEvent) {
		// In order to ensure that the browser will fire clipboard events, we always need to have something selected.
		// Therefore, `value` cannot be "".
		if (textInput.value != dummyCharacter) {
			var value = normalizeInputNewlines(StringTools.replace(textInput.value, dummyCharacter, ""));
			if (value.length > 0) {
				onTextInput.dispatch(value);
			}
			textInput.value = dummyCharacter;
		}
	}

	inline function normalizeInputNewlines(text:String):String {
		// TODO: just normalize everything to \r for the Flash API
		// normalize line breaks to `\n`, no matter if they were `\r\n` or just `\r`
		// so the API users (e.g. OpenFL) can assume that input newlines are always `\n`
		// this avoids issues with some browsers on Windows (e.g. Chrome) that paste
		// newlines as \r\n, as well as copying Flash text produced by Flash, which only
		// contain \r (https://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/flash/text/TextField.html#text)
		return StringTools.replace(StringTools.replace(text, "\r\n", "\n"), "\r", "\n");
	}

	function handleResizeEvent(event:js.html.Event) {
		updateScale();
		updateSize();
	}

	var settingSystemClipboard = false;

	public function setClipboard(value:String) {
		var inputEnabled = enableTextEvents;

		set_enableTextEvents(true); // create textInput if necessary

		var cacheText = textInput.value;
		textInput.value = value;
		textInput.select();

		settingSystemClipboard = true;
		if (Browser.document.queryCommandEnabled("copy")) {
			Browser.document.execCommand("copy");
		}
		settingSystemClipboard = false;

		textInput.value = cacheText;

		set_enableTextEvents(inputEnabled);
	}

	inline function get_fullscreen():Bool {
		return __fullscreen;
	}

	function set_fullscreen(value:Bool):Bool {
		var element = kha.SystemImpl.khanvas; // TODO: get rid of untyped
		if (value) {
			if (!requestedFullscreen && !isFullscreen) {
				requestedFullscreen = true;

				untyped {
					if (element.requestFullscreen) {
						document.addEventListener("fullscreenchange", handleFullscreenEvent, false);
						document.addEventListener("fullscreenerror", handleFullscreenEvent, false);
						element.requestFullscreen();
					} else if (element.mozRequestFullScreen) {
						document.addEventListener("mozfullscreenchange", handleFullscreenEvent, false);
						document.addEventListener("mozfullscreenerror", handleFullscreenEvent, false);
						element.mozRequestFullScreen();
					} else if (element.webkitRequestFullscreen) {
						document.addEventListener("webkitfullscreenchange", handleFullscreenEvent, false);
						document.addEventListener("webkitfullscreenerror", handleFullscreenEvent, false);
						element.webkitRequestFullscreen();
					} else if (element.msRequestFullscreen) {
						document.addEventListener("MSFullscreenChange", handleFullscreenEvent, false);
						document.addEventListener("MSFullscreenError", handleFullscreenEvent, false);
						element.msRequestFullscreen();
					}
				}
			}
		} else if (isFullscreen) {
			requestedFullscreen = false;

			untyped {
				if (document.exitFullscreen)
					document.exitFullscreen();
				else if (document.mozCancelFullScreen)
					document.mozCancelFullScreen();
				else if (document.webkitExitFullscreen)
					document.webkitExitFullscreen();
				else if (document.msExitFullscreen)
					document.msExitFullscreen();
			}
		}

		return __fullscreen = value;
	}

	function handleFullscreenEvent(event:js.html.Event) {
		var fullscreenElement = untyped (document.fullscreenElement || document.mozFullScreenElement || document.webkitFullscreenElement
			|| document.msFullscreenElement);

		if (fullscreenElement != null) {
			isFullscreen = true;
			__fullscreen = true;

			if (requestedFullscreen) {
				requestedFullscreen = false;
				stage.onWindowFullscreen();
			}
		} else {
			isFullscreen = false;
			__fullscreen = false;

			stage.onWindowRestore();

			var changeEvents = [
				"fullscreenchange",
				"mozfullscreenchange",
				"webkitfullscreenchange",
				"MSFullscreenChange"
			];
			var errorEvents = [
				"fullscreenerror",
				"mozfullscreenerror",
				"webkitfullscreenerror",
				"MSFullscreenError"
			];

			for (i in 0...changeEvents.length) {
				Browser.document.removeEventListener(changeEvents[i], handleFullscreenEvent, false);
				Browser.document.removeEventListener(errorEvents[i], handleFullscreenEvent, false);
			}
		}
	}
}
