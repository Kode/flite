package openfl._internal.renderer.opengl.batcher;

import kha.arrays.Float32Array;
import openfl._internal.utils.ObjectPool;
import openfl.geom.ColorTransform;

class Quad {
	public static final pool = new ObjectPool(Quad.new, quad -> quad.cleanup());

	/** Absolute vertex coordinates **/
	public var vertexData(default, null):Float32Array;

	/** Link to the texture information **/
	public var texture:QuadTextureData;

	public var alpha(default, null):Float;
	public var colorTransform(default, null):ColorTransform;
	public var blendMode(default, null):BlendMode;
	public var smoothing(default, null):Bool;

	public function new() {
		vertexData = new Float32Array(4 * 2);
		alpha = 1;
		smoothing = false;
	}

	public inline function setup(alpha, colorTransform, blendMode, smoothing) {
		this.alpha = alpha;
		this.colorTransform = colorTransform;
		this.blendMode = blendMode;
		this.smoothing = smoothing;
	}

	function cleanup() {
		texture = null;
		colorTransform = null;
	}
}
