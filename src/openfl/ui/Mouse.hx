package openfl.ui;

@:access(openfl.display.Stage)
final class Mouse {
	public static var cursor(get, set):MouseCursor;
	public static var supportsCursor(default, null):Bool = #if !mobile true; #else false; #end
	public static var supportsNativeCursor(default, null):Bool = #if !mobile true; #else false; #end
	private static var __cursor:MouseCursor = MouseCursor.AUTO;

	public static function hide():Void {
		InternalMouse.hide();
	}

	public static function show():Void {
		InternalMouse.show();
	}

	// Get & Set Methods

	private static function get_cursor():MouseCursor {
		return __cursor;
	}

	private static function set_cursor(value:MouseCursor):MouseCursor {
		InternalMouse.setCursor(value);
		return __cursor = value;
	}
}

class InternalMouse {
	static var __cursor:MouseCursor;
	static var __hidden:Bool;

	public static function hide():Void {
		if (!__hidden) {
			__hidden = true;
			kha.SystemImpl.khanvas.style.cursor = "none";
		}
	}

	public static function show():Void {
		if (__hidden) {
			__hidden = false;
			applyCursor(__cursor);
		}
	}

	public static function setCursor(value:MouseCursor):MouseCursor {
		if (__cursor != value) {
			if (!__hidden) {
				applyCursor(value);
			}
			__cursor = value;
		}
		return __cursor;
	}

	static function applyCursor(cursor:MouseCursor) {
		kha.SystemImpl.khanvas.style.cursor = switch (cursor) {
			case ARROW: "default";
			case BUTTON: "pointer";
			case HAND: "move";
			case IBEAM: "text";
			case __CROSSHAIR: "crosshair";
			case __RESIZE_NESW: "nesw-resize";
			case __RESIZE_NS: "ns-resize";
			case __RESIZE_NWSE: "nwse-resize";
			case __RESIZE_WE: "ew-resize";
			case __WAIT: "wait";
			case __WAIT_ARROW: "wait";
			default: "default";
		};
	}
}
