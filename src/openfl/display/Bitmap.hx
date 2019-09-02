package openfl.display;

import openfl._internal.renderer.canvas.CanvasBitmap;
import openfl._internal.renderer.canvas.CanvasRenderSession;
import openfl._internal.renderer.opengl.batcher.Quad;
import openfl._internal.renderer.opengl.batcher.BlendMode as BatcherBlendMode;
import openfl._internal.renderer.opengl.GLRenderSession;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;

@:access(openfl.display.BitmapData)
@:access(openfl.display.Graphics)
@:access(openfl.geom.ColorTransform)
@:access(openfl.geom.Rectangle)
class Bitmap extends DisplayObject {
	public var bitmapData(get, set):BitmapData;
	public var pixelSnapping(get, set):PixelSnapping;
	public var smoothing:Bool;

	private var __bitmapData:BitmapData;
	private var __imageVersion:Int;
	var __batchQuad:Quad;
	var __batchQuadDirty:Bool = true;

	public function new(bitmapData:BitmapData = null, pixelSnapping:PixelSnapping = null, smoothing:Bool = false) {
		super();

		__bitmapData = bitmapData;

		if (pixelSnapping == null)
			pixelSnapping = PixelSnapping.AUTO;
		__pixelSnapping = pixelSnapping;

		this.smoothing = smoothing;
	}

	private override function __cleanup():Void {
		super.__cleanup();

		if (__bitmapData != null) {
			__bitmapData.__cleanup();
		}

		if (__batchQuad != null) {
			Quad.pool.release(__batchQuad);
			__batchQuad = null;
		}
	}

	private override function __enterFrame(deltaTime:Int):Void {
		if (__bitmapData != null && __bitmapData.image != null) {
			var image = __bitmapData.image;
			if (__bitmapData.image.version != __imageVersion) {
				__setRenderDirty();
				__imageVersion = image.version;
			}
		}
	}

	private override function __getBounds(rect:Rectangle, matrix:Matrix):Void {
		if (__bitmapData != null) {
			var bounds = Rectangle.__pool.get();
			bounds.setTo(0, 0, __bitmapData.width, __bitmapData.height);
			bounds.__transform(bounds, matrix);

			rect.__expand(bounds.x, bounds.y, bounds.width, bounds.height);

			Rectangle.__pool.release(bounds);
		}
	}

	private override function __hitTest(x:Float, y:Float, shapeFlag:Bool, stack:Array<DisplayObject>, interactiveOnly:Bool, hitObject:DisplayObject,
			hitTestWhenMouseDisabled:Bool = false):Bool {
		if (!hitObject.visible || __isMask || __bitmapData == null)
			return false;
		if (mask != null && !mask.__hitTestMask(x, y))
			return false;

		__getRenderTransform();

		var px = __renderTransform.__transformInverseX(x, y);
		var py = __renderTransform.__transformInverseY(x, y);

		if (px > 0 && py > 0 && px <= __bitmapData.width && py <= __bitmapData.height) {
			if (__scrollRect != null && !__scrollRect.contains(px, py)) {
				return false;
			}

			if (stack != null && !interactiveOnly && !hitTestWhenMouseDisabled) {
				stack.push(hitObject);
			}

			return true;
		}

		return false;
	}

	private override function __hitTestMask(x:Float, y:Float):Bool {
		if (__bitmapData == null)
			return false;

		__getRenderTransform();

		var px = __renderTransform.__transformInverseX(x, y);
		var py = __renderTransform.__transformInverseY(x, y);

		if (px > 0 && py > 0 && px <= __bitmapData.width && py <= __bitmapData.height) {
			return true;
		}

		return false;
	}

	private override function __renderCanvas(renderSession:CanvasRenderSession):Void {
		__updateCacheBitmap(!__worldColorTransform.__isDefault(), renderSession.pixelRatio, renderSession.allowSmoothing);

		if (__cacheBitmap != null && !__cacheBitmapRender) {
			CanvasBitmap.render(__cacheBitmap, renderSession);
		} else {
			CanvasBitmap.render(this, renderSession);
		}
	}

	private override function __renderCanvasMask(renderSession:CanvasRenderSession):Void {
		renderSession.context.rect(0, 0, __bitmapData.width, __bitmapData.height);
	}

	function __getBatchQuad(renderSession:GLRenderSession):Quad {
		if (__batchQuadDirty) {
			if (__batchQuad == null) {
				__batchQuad = Quad.pool.get();
			}

			var snapToPixel = __snapToPixel();
			var transform = renderSession.renderer.getDisplayTransformTempMatrix(__renderTransform, snapToPixel);
			bitmapData.__fillBatchQuad(transform, __batchQuad.vertexData);
			__batchQuad.texture = __bitmapData.__getTexture();
			__batchQuadDirty = false;
		}

		__batchQuad.setup(__worldAlpha, __worldColorTransform, BatcherBlendMode.fromOpenFLBlendMode(__worldBlendMode), smoothing);

		return __batchQuad;
	}

	override function __updateTransforms() {
		super.__updateTransforms();
		__batchQuadDirty = true;
	}

	function __renderBatched(renderSession:GLRenderSession) {
		if (!__renderable || __worldAlpha <= 0 || __bitmapData == null || !__bitmapData.__isValid) {
			return;
		}
		renderSession.maskManager.pushObject(this);
		renderSession.batcher.render(__getBatchQuad(renderSession));
		renderSession.maskManager.popObject(this);
	}

	function __renderAsMask(renderSession:GLRenderSession):Void {
		if (__bitmapData == null || !__bitmapData.__isValid) {
			return;
		}
		var smoothing = renderSession.allowSmoothing && (this.smoothing || renderSession.forceSmoothing);
		renderSession.renderMask(__bitmapData, smoothing, __renderTransform, __snapToPixel());
	}

	private override function __renderGL(renderSession:GLRenderSession):Void {
		__updateCacheBitmap(false, renderSession.pixelRatio, renderSession.allowSmoothing);
		if (__cacheBitmap != null && !__cacheBitmapRender) {
			__cacheBitmap.__renderBatched(renderSession);
		} else {
			__renderBatched(renderSession);
		}
	}

	private override function __renderGLMask(renderSession:GLRenderSession):Void {
		__updateCacheBitmap(false, renderSession.pixelRatio, renderSession.allowSmoothing);
		if (__cacheBitmap != null && !__cacheBitmapRender) {
			__cacheBitmap.__renderAsMask(renderSession);
		} else {
			__renderAsMask(renderSession);
		}
	}

	private override function __updateCacheBitmap(force:Bool, pixelRatio:Float, allowSmoothing:Bool):Bool {
		if (!force && !__hasFilters() && __cacheBitmap == null)
			return false;
		return super.__updateCacheBitmap(force, pixelRatio, allowSmoothing);
	}

	override function __forceRenderDirty() {
		super.__forceRenderDirty();

		__batchQuadDirty = true;
	}

	// Get & Set Methods

	private function get_bitmapData():BitmapData {
		return __bitmapData;
	}

	private function set_bitmapData(value:BitmapData):BitmapData {
		__bitmapData = value;
		smoothing = false;

		__setRenderDirty();
		__batchQuadDirty = true;

		if (__hasFilters()) {
			// __updateFilters = true;
		}

		__imageVersion = -1;

		return __bitmapData;
	}

	private override function get_height():Float {
		if (__bitmapData != null) {
			return __bitmapData.height * Math.abs(scaleY);
		}

		return 0;
	}

	private override function set_height(value:Float):Float {
		if (__bitmapData != null) {
			if (value != __bitmapData.height * __scaleY) {
				__setRenderDirty();
				scaleY = value / __bitmapData.height;
			}

			return value;
		}

		return 0;
	}

	private override function get_width():Float {
		if (__bitmapData != null) {
			return __bitmapData.width * Math.abs(__scaleX);
		}

		return 0;
	}

	private override function set_width(value:Float):Float {
		if (__bitmapData != null) {
			if (value != __bitmapData.width * __scaleX) {
				__setRenderDirty();
				scaleX = value / __bitmapData.width;
			}

			return value;
		}

		return 0;
	}
}
