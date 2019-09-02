package openfl._internal.renderer.canvas;

import js.html.CanvasRenderingContext2D;

class CanvasRenderSession {
	public final context:CanvasRenderingContext2D;
	public final clearRenderDirty:Bool;
	public final pixelRatio:Float;
	public final allowSmoothing:Bool;
	public final blendModeManager:CanvasBlendModeManager;
	public final maskManager:CanvasMaskManager;

	public function new(context, clearRenderDirty, pixelRatio, allowSmoothing) {
		this.context = context;
		this.clearRenderDirty = clearRenderDirty;
		this.pixelRatio = pixelRatio;
		this.allowSmoothing = allowSmoothing;
		this.blendModeManager = new CanvasBlendModeManager(context);
		this.maskManager = new CanvasMaskManager(this);
	}
}
