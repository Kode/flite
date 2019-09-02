package openfl.desktop;

import openfl._internal.system.Clipboard in InternalClipboard;
import openfl.utils.Object;

class Clipboard {
	public static var generalClipboard(get, null):Clipboard;

	public var formats(get, never):Array<ClipboardFormats>;

	var __htmlText:String;
	var __richText:String;
	var __text:String;

	public function clear():Void {
		__htmlText = null;
		__richText = null;
		__text = null;
	}

	public function clearData(format:ClipboardFormats):Void {
		switch (format) {
			case HTML_FORMAT:
				__htmlText = null;

			case RICH_TEXT_FORMAT:
				__richText = null;

			case TEXT_FORMAT:
				__text = null;

			default:
		}
	}

	public function getData(format:ClipboardFormats, transferMode:ClipboardTransferMode = ORIGINAL_PREFERRED):Object {
		return switch (format) {
			case HTML_FORMAT: __htmlText;
			case RICH_TEXT_FORMAT: __richText;
			case TEXT_FORMAT: __text;
			default: null;
		}
	}

	public function hasFormat(format:ClipboardFormats):Bool {
		return switch (format) {
			case HTML_FORMAT: __htmlText != null;
			case RICH_TEXT_FORMAT: __richText != null;
			case TEXT_FORMAT: __text != null;
			default: false;
		}
	}

	public function setData(format:ClipboardFormats, data:Object, serializable:Bool = true):Bool {
		switch (format) {
			case HTML_FORMAT:
				__htmlText = data;
				return true;

			case RICH_TEXT_FORMAT:
				__richText = data;
				return true;

			case TEXT_FORMAT:
				__text = data;
				return true;

			default:
				return false;
		}
	}

	public function setDataHandler(format:ClipboardFormats, handler:Void->Dynamic, serializable:Bool = true):Bool {
		openfl.Lib.notImplemented();
		return false;
	}

	// Get & Set Methods

	function get_formats():Array<ClipboardFormats> {
		var formats = new Array<ClipboardFormats>();
		if (hasFormat(HTML_FORMAT))
			formats.push(HTML_FORMAT);
		if (hasFormat(RICH_TEXT_FORMAT))
			formats.push(RICH_TEXT_FORMAT);
		if (hasFormat(TEXT_FORMAT))
			formats.push(TEXT_FORMAT);
		return formats;
	}

	static function get_generalClipboard():Clipboard {
		if (generalClipboard == null) {
			generalClipboard = new GeneralClipboard();
		}
		return generalClipboard;
	}
}

private class GeneralClipboard extends Clipboard {
	public function new() {}

	override function clear() {
		InternalClipboard.setText(null, true);
	}

	override function clearData(format:ClipboardFormats) {
		switch (format) {
			case HTML_FORMAT | RICH_TEXT_FORMAT | TEXT_FORMAT:
				InternalClipboard.setText(null, true);
			default:
		}
	}

	override function getData(format:ClipboardFormats, transferMode:ClipboardTransferMode = ORIGINAL_PREFERRED):Object {
		return switch (format) {
			case HTML_FORMAT | RICH_TEXT_FORMAT | TEXT_FORMAT: InternalClipboard.text;
			default: null;
		}
	}

	override function hasFormat(format:ClipboardFormats):Bool {
		return switch (format) {
			case HTML_FORMAT | RICH_TEXT_FORMAT | TEXT_FORMAT: InternalClipboard.text != null;
			default: false;
		}
	}

	override function setData(format:ClipboardFormats, data:Object, serializable:Bool = true):Bool {
		switch (format) {
			case HTML_FORMAT | RICH_TEXT_FORMAT | TEXT_FORMAT:
				InternalClipboard.setText(data, true);
				return true;

			default:
				return false;
		}
	}
}
