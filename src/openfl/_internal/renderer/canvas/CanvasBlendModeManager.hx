package openfl._internal.renderer.canvas;

import js.html.CanvasRenderingContext2D;
import openfl.display.BlendMode;

class CanvasBlendModeManager {
	final context:CanvasRenderingContext2D;
	var currentBlendMode:BlendMode;

	public function new(context) {
		this.context = context;
	}

	public function setBlendMode(blendMode:BlendMode):Void {
		if (currentBlendMode == blendMode)
			return;

		currentBlendMode = blendMode;

		switch (blendMode) {
			case ADD:
				context.globalCompositeOperation = "lighter";

			case ALPHA:
				context.globalCompositeOperation = "destination-in";

			case DARKEN:
				context.globalCompositeOperation = "darken";

			case DIFFERENCE:
				context.globalCompositeOperation = "difference";

			case ERASE:
				context.globalCompositeOperation = "destination-out";

			case HARDLIGHT:
				context.globalCompositeOperation = "hard-light";

			// case INVERT:

			// context.globalCompositeOperation = "";

			case LAYER:
				context.globalCompositeOperation = "source-over";

			case LIGHTEN:
				context.globalCompositeOperation = "lighten";

			case MULTIPLY:
				context.globalCompositeOperation = "multiply";

			case OVERLAY:
				context.globalCompositeOperation = "overlay";

			case SCREEN:
				context.globalCompositeOperation = "screen";

			// case SHADER:

			// context.globalCompositeOperation = "";

			// case SUBTRACT:

			// context.globalCompositeOperation = "";

			default:
				context.globalCompositeOperation = "source-over";
		}
	}
}
