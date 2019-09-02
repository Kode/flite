package openfl._internal.renderer.opengl;

import openfl._internal.renderer.canvas.CanvasGraphics;
import openfl.display.DisplayObject;
import openfl.geom.Rectangle;

@:access(openfl.display.DisplayObject)
@:access(openfl.geom.Matrix)
@:access(openfl.geom.Rectangle)
@:access(openfl.display.Graphics)
class GLDisplayObject {
	public static function render(displayObject:DisplayObject, renderSession:GLRenderSession):Void {
		if (displayObject.opaqueBackground == null && displayObject.__graphics == null)
			return;
		if (!displayObject.__renderable || displayObject.__worldAlpha <= 0)
			return;

		if (displayObject.opaqueBackground != null && !displayObject.__cacheBitmapRender && displayObject.width > 0 && displayObject.height > 0) {
			// renderSession.blendModeManager.setBlendMode(displayObject.__worldBlendMode);
			// renderSession.maskManager.pushObject(displayObject);

			// var rect = Rectangle.__pool.get();
			// rect.setTo(0, 0, displayObject.width, displayObject.height);
			// renderSession.maskManager.pushRect(rect, displayObject.__renderTransform);
			// renderSession.g4.clear(displayObject.opaqueBackground); // TODO: not sure if this play well with masks...
			// renderSession.maskManager.popRect();
			// renderSession.maskManager.popObject(displayObject);

			// Rectangle.__pool.release(rect);
		}

		if (displayObject.__graphics != null) {
			var graphics = displayObject.__graphics;
			CanvasGraphics.render(graphics, renderSession.pixelRatio, renderSession.allowSmoothing);

			if (graphics.__bitmap != null && graphics.__visible) {
				renderSession.maskManager.pushObject(displayObject);
				renderSession.batcher.render(graphics.__getBatchQuad(renderSession, displayObject.__worldAlpha, displayObject.__worldColorTransform, displayObject.__worldBlendMode));
				renderSession.maskManager.popObject(displayObject);
			}
		}
	}

	public static function renderMask(displayObject:DisplayObject, renderSession:GLRenderSession):Void {
		if (displayObject.opaqueBackground == null && displayObject.__graphics == null)
			return;

		if (displayObject.opaqueBackground != null && !displayObject.__cacheBitmapRender && displayObject.width > 0 && displayObject.height > 0) {
			// TODO

			// var gl = kha.SystemImpl.gl;
			// var rect = Rectangle.__pool.get ();
			// rect.setTo (0, 0, displayObject.width, displayObject.height);
			// renderSession.maskManager.pushRect (rect, displayObject.__renderTransform);

			// var color:ARGB = (displayObject.opaqueBackground:ARGB);
			// gl.clearColor (color.r / 0xFF, color.g / 0xFF, color.b / 0xFF, 1);
			// gl.clear (gl.COLOR_BUFFER_BIT);

			// renderSession.maskManager.popRect ();
			// renderSession.maskManager.popObject (displayObject);

			// Rectangle.__pool.release (rect);
		}

		var graphics = displayObject.__graphics;
		if (graphics != null) {
			// TODO: Support invisible shapes
			CanvasGraphics.render(graphics, renderSession.pixelRatio, renderSession.allowSmoothing);
			if (graphics.__bitmap != null) {
				renderSession.renderMask(graphics.__bitmap, renderSession.allowSmoothing, graphics.__worldTransform, false);
			}
		}
	}
}
