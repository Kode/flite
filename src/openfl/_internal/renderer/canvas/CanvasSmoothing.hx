package openfl._internal.renderer.canvas;

import js.html.CanvasRenderingContext2D;

class CanvasSmoothing {
	public static inline function setEnabled(context:CanvasRenderingContext2D, enabled:Bool) {
		(cast context).mozImageSmoothingEnabled = enabled;
		// (cast context).webkitImageSmoothingEnabled = enabled;
		(cast context).msImageSmoothingEnabled = enabled;
		(cast context).imageSmoothingEnabled = enabled;
	}
}
