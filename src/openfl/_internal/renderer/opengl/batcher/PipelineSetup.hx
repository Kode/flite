package openfl._internal.renderer.opengl.batcher;

import haxe.ds.ReadOnlyArray;

import kha.graphics4.BlendingFactor;
import kha.graphics4.BlendingOperation;
import kha.graphics4.ConstantLocation;
import kha.graphics4.FragmentShader;
import kha.graphics4.PipelineState;
import kha.graphics4.TextureUnit;
import kha.graphics4.VertexStructure;

import openfl._internal.utils.Log;

@:allow(openfl._internal.renderer.opengl.batcher.BlendMode)
class PipelineSetup {
	public final pipeline:PipelineState;
	public final uProjMatrix:ConstantLocation;
	public final uPositionScale:ConstantLocation;
	public final textureUnits:ReadOnlyArray<TextureUnit>;

	public static var vertexStructure(default,null):VertexStructure;
	public static var numTextures(default,null):Int;

	static var fragmentShader:FragmentShader;

	@:allow(openfl._internal.renderer.opengl.batcher.BlendMode)
	static var pNormal:PipelineSetup;

	static function init() {
		if (vertexStructure != null) return;

		vertexStructure = new VertexStructure();
		vertexStructure.add("aVertexPosition", Float2);
		vertexStructure.add("aTextureCoord", Float2);
		vertexStructure.add("aTextureId", Float1);
		vertexStructure.add("aColorOffset", Float4);
		vertexStructure.add("aColorMultiplier", Float4);
		vertexStructure.add("aPremultipliedAlpha", Float1);

		numTextures = kha.SystemImpl.gl.getParameter(js.html.webgl.GL.MAX_TEXTURE_IMAGE_UNITS);
		if (numTextures > 32) {
			numTextures = 32;
		} else {
			var v = nextPowerOfTwo(numTextures);
			if (numTextures != v) {
				numTextures = v >> 1;
			}
		}
		while (numTextures >= 1) {
			try {
				fragmentShader = Reflect.field(kha.Shaders, "batch_" + numTextures + "_frag");
				pNormal = new PipelineSetup(Add, BlendOne, InverseSourceAlpha, false);
				break;
			} catch (e:Any) {
				Log.warn("Coudln't compile multi-texture program for " + numTextures + " samplers, trying twice as less, error: " + e);
				numTextures = numTextures >> 1;
			}
		}
		if (pNormal == null) {
			throw "Could not compile a multi-texture shader for any number of textures, something must be horribly broken!";
		}
	}

	function new(blendOperation:BlendingOperation, blendSource:BlendingFactor, blendDestination:BlendingFactor, masked:Bool) {
		pipeline = new PipelineState();
		pipeline.inputLayout = [vertexStructure];
		pipeline.vertexShader = kha.Shaders.batch_vert;
		pipeline.fragmentShader = fragmentShader;
		pipeline.blendOperation = blendOperation;
		pipeline.blendSource = blendSource;
		pipeline.blendDestination = blendDestination;
		pipeline.alphaBlendOperation = blendOperation;
		pipeline.alphaBlendSource = blendSource;
		pipeline.alphaBlendDestination = blendDestination;
		if (masked) {
			pipeline.stencilMode = Equal;
			pipeline.stencilReferenceValue = Dynamic;
		}
		pipeline.compile();
		uProjMatrix = pipeline.getConstantLocation("uProjMatrix");
		uPositionScale = pipeline.getConstantLocation("uPostionScale");
		textureUnits = [for (i in 0...numTextures) pipeline.getTextureUnit('uSamplers[$i]')];
	}

	static function nextPowerOfTwo(v:Int):Int {
		v--;
		v |= v >>> 1;
		v |= v >>> 2;
		v |= v >>> 4;
		v |= v >>> 8;
		v |= v >>> 16;
		v++;
		return v;
	}
}
