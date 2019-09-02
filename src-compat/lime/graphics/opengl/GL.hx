package lime.graphics.opengl;

import js.html.webgl.GL2;

class GL {
	// used in zame-particles :-/
	public static inline var ONE = 1;
	public static inline var DST_ALPHA = 0x0304;
	public static inline var DST_COLOR = 0x0306;
	public static inline var TEXTURE_2D = 3553;

	public static var context(default, null):GL2;

	#if debug
	static var __lastLoseContextExtension:js.html.webgl.extension.WEBGLLoseContext;

	@:expose("loseGLContext")
	static function loseContext() {
		var extension = context.getExtension(WEBGL_lose_context);
		if (extension == null) {
			js.Browser.console.warn("Context already lost");
		} else {
			extension.loseContext();
			__lastLoseContextExtension = extension;
		}
	}

	@:expose("restoreGLContext")
	static function restoreContext() {
		if (__lastLoseContextExtension == null) {
			js.Browser.console.warn("No lost context found"); // yeah
		} else {
			__lastLoseContextExtension.restoreContext();
			__lastLoseContextExtension = null;
		}
	}
	#end
}
