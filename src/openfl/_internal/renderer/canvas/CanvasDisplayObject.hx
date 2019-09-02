package openfl._internal.renderer.canvas;

import openfl._internal.graphics.color.ARGB;
import openfl.display.DisplayObject;

@:access(openfl.display.DisplayObject)
@:access(openfl.geom.Matrix)
@:access(openfl.display.Graphics)
class CanvasDisplayObject {
	public static function render(displayObject:DisplayObject, renderSession:CanvasRenderSession):Void {
		if (displayObject.opaqueBackground == null && displayObject.__graphics == null)
			return;
		if (!displayObject.__renderable || displayObject.__worldAlpha <= 0)
			return;

		if (displayObject.opaqueBackground != null
			&& !displayObject.__cacheBitmapRender
			&& displayObject.width > 0
			&& displayObject.height > 0) {
			renderSession.blendModeManager.setBlendMode(displayObject.__worldBlendMode);
			renderSession.maskManager.pushObject(displayObject);

			var context = renderSession.context;
			var transform = displayObject.__renderTransform;
			var pixelRatio = renderSession.pixelRatio;

			context.setTransform(transform.a * pixelRatio, transform.b, transform.c, transform.d * pixelRatio, transform.tx * pixelRatio,
				transform.ty * pixelRatio);

			var color:ARGB = (displayObject.opaqueBackground : ARGB);
			context.fillStyle = 'rgb(${color.r},${color.g},${color.b})';
			context.fillRect(0, 0, displayObject.width, displayObject.height);

			renderSession.maskManager.popObject(displayObject);
		}

		if (displayObject.__graphics != null) {
			var graphics = displayObject.__graphics;
			CanvasGraphics.render(graphics, renderSession.pixelRatio, renderSession.allowSmoothing);

			var width = graphics.__width;
			var height = graphics.__height;

			if (graphics.__canvas != null) {
				var context = renderSession.context;
				var scrollRect = displayObject.__scrollRect;

				if (width > 0 && height > 0 && (scrollRect == null || (scrollRect.width > 0 && scrollRect.height > 0))) {
					renderSession.blendModeManager.setBlendMode(displayObject.__worldBlendMode);
					renderSession.maskManager.pushObject(displayObject);

					context.globalAlpha = displayObject.__worldAlpha;

					var transform = graphics.__worldTransform;
					var pixelRatio = renderSession.pixelRatio;
					var scale = 1; // As opposed of CanvasBitmap, canvases have the same pixelRatio as display, therefore we don't need to scale them and so scale is always 1

					context.setTransform(transform.a * scale, transform.b, transform.c, transform.d * scale, transform.tx * pixelRatio,
						transform.ty * pixelRatio);

					context.drawImage(graphics.__canvas, 0, 0);

					renderSession.maskManager.popObject(displayObject);
				}
			}
		}
	}
}
