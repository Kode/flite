package openfl._internal.renderer.opengl;

import openfl._internal.renderer.opengl.batcher.BatchRenderer;
import openfl.geom.Matrix;
import openfl.display.BitmapData;
import kha.graphics4.TextureFilter;

class GLRenderSession {
	public var allowSmoothing:Bool;
	public var forceSmoothing:Bool;
	public var pixelRatio:Float;
	public var g4:kha.graphics4.Graphics;
	public final batcher:BatchRenderer;
	public final renderer:GLRenderer;
	public final maskManager:MaskManager;

	public function new(renderer, pixelRatio) {
		this.renderer = renderer;
		this.pixelRatio = pixelRatio;
		this.maskManager = new MaskManager(this);
		this.batcher = new BatchRenderer(maskManager, 4096);
		allowSmoothing = true;
	}

	public function renderMask(bitmapData:BitmapData, smoothing:Bool, transform:Matrix, snapToPixel:Bool) {
		g4.setTexture(maskManager.uImage0, @:privateAccess bitmapData.__getTexture().data.image);
		var filter = if (smoothing) TextureFilter.LinearFilter else TextureFilter.PointFilter;
		g4.setTextureParameters(maskManager.uImage0, Clamp, Clamp, filter, filter, NoMipFilter);
		g4.setMatrix(maskManager.uMatrix, renderer.getMatrix(transform, snapToPixel));
		g4.setVertexBuffer(bitmapData.getMaskVertexBuffer(maskManager.vertexStructure));
		g4.setIndexBuffer(maskManager.quadIndexBuffer);
		g4.drawIndexedVertices(0, 6);
	}
}
