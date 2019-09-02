package openfl._internal.renderer.opengl;

import js.html.webgl.GL;
import kha.math.FastMatrix4;
import openfl.display.Graphics;
import openfl.display.Stage;
import openfl.geom.Matrix;

@:access(openfl.display.Graphics)
@:access(openfl.display.Stage)
@:access(openfl.display.Stage3D)
class GLRenderer {
	public var height(default,null):Int;
	public var width(default,null):Int;
	public var backbuffer(default,null):kha.Image;

	final projectionMatrix = FastMatrix4.empty();
	final renderSession:GLRenderSession;
	final stage:Stage;
	var displayMatrix:Matrix;
	var displayHeight:Int;
	var displayWidth:Int;
	var offsetX:Int;
	var offsetY:Int;

	public function new(stage:Stage) {
		this.stage = stage;

		width = stage.stageWidth;
		height = stage.stageHeight;

		if (Graphics.maxTextureWidth == null) {
			Graphics.maxTextureWidth = Graphics.maxTextureHeight = kha.Image.maxSize;
		}

		renderSession = new GLRenderSession(this, stage.window.scale);

		if (stage.window != null) {
			if (stage.stage3Ds[0].context3D == null) {
				stage.stage3Ds[0].__createContext(stage, renderSession);
			}

			var width = Math.ceil(stage.window.width * stage.window.scale);
			var height = Math.ceil(stage.window.height * stage.window.scale);

			resize(width, height);
		}
	}

	public function begin() {
		renderSession.g4 = backbuffer.g4;
		renderSession.batcher.g4 = renderSession.g4;
		renderSession.g4.begin();
	}

	public function end() {
		renderSession.g4.end();
		renderSession.g4 = null;
		renderSession.batcher.g4 = null;
	}

	public function clear() {
		renderSession.g4.clear(stage.__colorKha);
	}

	final displayTransformTempMatrix = new Matrix();

	public function getDisplayTransformTempMatrix(transform:Matrix, snapToPixel:Bool):Matrix {
		var matrix = displayTransformTempMatrix;
		matrix.copyFrom(transform);
		matrix.concat(displayMatrix);
		if (snapToPixel) {
			matrix.tx = Math.round(matrix.tx);
			matrix.ty = Math.round(matrix.ty);
		}
		return displayTransformTempMatrix;
	}

	final getMatrixHelperMatrix4 = FastMatrix4.empty();

	public function getMatrix(transform:Matrix, snapToPixel:Bool):FastMatrix4 {
		var matrix = getDisplayTransformTempMatrix(transform, snapToPixel);
		getMatrixHelperMatrix4.setFrom(projectionMatrix.multmat(new FastMatrix4(
			matrix.a, matrix.b, 0, matrix.tx,
			matrix.c, matrix.d, 0, matrix.ty,
			0,         0,       1, 0,
			0,         0,       0, 1
		)));
		return getMatrixHelperMatrix4;
	}

	public function render() {
		var gl = kha.SystemImpl.gl;
		gl.viewport(offsetX, offsetY, displayWidth, displayHeight);

		renderSession.allowSmoothing = (stage.quality != LOW);
		renderSession.forceSmoothing = #if always_smooth_on_upscale (displayMatrix.a != 1 || displayMatrix.d != 1); #else false; #end

		// setup projection matrix for the batcher as it's an uniform value for all the draw calls
		renderSession.batcher.projectionMatrix = projectionMatrix;

		stage.__renderGL(renderSession);

		// flush whatever is left in the batch to render
		renderSession.batcher.flush();

		if (offsetX > 0 || offsetY > 0) {
			gl.clearColor(0, 0, 0, 1);
			gl.enable(GL.SCISSOR_TEST);

			if (offsetX > 0) {
				gl.scissor(0, 0, offsetX, height);
				gl.clear(GL.COLOR_BUFFER_BIT);

				gl.scissor(offsetX + displayWidth, 0, width, height);
				gl.clear(GL.COLOR_BUFFER_BIT);
			}

			if (offsetY > 0) {
				gl.scissor(0, 0, width, offsetY);
				gl.clear(GL.COLOR_BUFFER_BIT);

				gl.scissor(0, offsetY + displayHeight, width, height);
				gl.clear(GL.COLOR_BUFFER_BIT);
			}

			gl.disable(GL.SCISSOR_TEST);
		}
	}

	public function renderStage3D() {
		for (stage3D in stage.stage3Ds) {
			stage3D.__renderGL(stage, renderSession);
		}
	}

	public function resize(width:Int, height:Int) {
		this.width = width;
		this.height = height;

		displayMatrix = stage.__displayMatrix;

		var w = stage.stageWidth;
		var h = stage.stageHeight;

		offsetX = Math.round(displayMatrix.__transformX(0, 0));
		offsetY = Math.round(displayMatrix.__transformY(0, 0));
		displayWidth = Math.round(displayMatrix.__transformX(w, 0) - offsetX);
		displayHeight = Math.round(displayMatrix.__transformY(0, h) - offsetY);

		// TODO: also check whether we draw directly to Framebuffer (and also something about pow2 render targets i guess...)
		if (kha.Image.renderTargetsInvertedY()) {
			projectionMatrix.setFrom(FastMatrix4.orthogonalProjection(offsetX, displayWidth + offsetX, offsetY, displayHeight + offsetY, -1000, 1000));
		} else {
			projectionMatrix.setFrom(FastMatrix4.orthogonalProjection(offsetX, displayWidth + offsetX, displayHeight + offsetY, offsetY, -1000, 1000));
		}

		backbuffer = kha.Image.createRenderTarget(width, height, RGBA32, DepthAutoStencilAuto);
	}
}
