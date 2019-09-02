package openfl.system;

import haxe.macro.Compiler;
import openfl._internal.app.Application;

@:final class Capabilities {
	public static var avHardwareDisable(default, null) = true;
	public static var cpuArchitecture(get, never):String;
	public static var hasAccessibility(default, null) = false;
	public static var hasAudio(default, null) = true;
	public static var hasAudioEncoder(default, null) = false;
	public static var hasEmbeddedVideo(default, null) = false;
	public static var hasIME(default, null) = false;
	public static var hasMP3(default, null) = false;
	public static var hasPrinting(default, null) = true;
	public static var hasScreenBroadcast(default, null) = false;
	public static var hasScreenPlayback(default, null) = false;
	public static var hasStreamingAudio(default, null) = false;
	public static var hasStreamingVideo(default, null) = false;
	public static var hasTLS(default, null) = true;
	public static var hasVideoEncoder(default, null) = true;
	public static var isDebugger(default, null) = #if debug true #else false #end;
	public static var isEmbeddedInAcrobat(default, null) = false;
	public static var language(get, never):String;
	public static var localFileReadDisable(default, null) = true;
	public static var manufacturer(get, never):String;
	public static var maxLevelIDC(default, null) = 0;
	public static var os(get, never):String;
	public static var pixelAspectRatio(get, never):Float;
	public static var playerType(default, null) = "PlugIn";
	public static var screenColor(default, null) = "color";
	public static var screenDPI(get, never):Float;
	public static var screenResolutionX(get, never):Float;
	public static var screenResolutionY(get, never):Float;
	public static var serverString(default, null) = ""; // TODO
	public static var supports32BitProcesses(default, null) = false;
	public static var supports64BitProcesses(default, null) = false; // TODO
	public static var touchscreenType(default, null) = TouchscreenType.FINGER; // TODO
	public static var version(get, never):String;
	private static var __standardDensities = [120, 160, 240, 320, 480, 640, 800, 960];

	public static function hasMultiChannelAudio(type:String):Bool {
		return false;
	}

	// Getters & Setters

	private static inline function get_cpuArchitecture():String {
		// TODO: Check architecture
		return "x86";
	}

	private static function get_language():String {
		var code = kha.System.language;
		var language = extractLanguage(code).toLowerCase();
		switch (language) {
			case "cs", "da", "nl", "en", "fi", "fr", "de", "hu", "it", "ja", "ko", "nb", "pl", "pt", "ru", "es", "sv", "tr":
				return language;

			case "zh":
				var region = extractRegion(code);
				if (region != null) {
					switch (region.toUpperCase()) {
						case "TW", "HANT":
							return "zh-TW";

						default:
					}
				}
				return "zh-CN";

			default:
				return "xu";
		}
	}

	static function extractLanguage(code:String):String {
		var index = code.indexOf("_");
		if (index > -1) {
			return code.substring(0, index);
		}

		index = code.indexOf("-");
		if (index > -1) {
			return code.substring(0, index);
		}

		return code;
	}

	static function extractRegion(code:String):Null<String> {
		var underscoreIndex = code.indexOf("_");
		var dotIndex = code.indexOf(".");

		if (underscoreIndex > -1) {
			if (dotIndex > -1) {
				return code.substring(underscoreIndex + 1, dotIndex);
			} else {
				return code.substring(underscoreIndex + 1);
			}
		}

		var dashIndex = code.indexOf("-");
		if (dashIndex > -1) {
			if (dotIndex > -1) {
				return code.substring(dashIndex + 1, dotIndex);
			} else {
				return code.substring(dashIndex + 1);
			}
		}

		return null;
	}

	private static inline function get_manufacturer():String {
		return "OpenFL HTML5";
	}

	private static inline function get_os():String {
		return "HTML5";
	}

	private static function get_pixelAspectRatio():Float {
		return 1;
	}

	private static function get_screenDPI():Float {
		var screenDPI = 72.0;

		var window = Application.current != null ? Application.current.window : null;
		if (window != null) {
			screenDPI *= window.scale;
		}
		return screenDPI;
	}

	static inline function get_screenResolutionX():Float {
		return kha.Display.primary.width;
	}

	static inline function get_screenResolutionY():Float {
		return kha.Display.primary.height;
	}

	static function get_version():String {
		var value = "WEB";
		if (Compiler.getDefine("openfl") != null) {
			value += " " + StringTools.replace(Compiler.getDefine("openfl"), ".", ",") + ",0";
		}
		return value;
	}
}
