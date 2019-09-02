package openfl._internal.renderer.opengl.batcher;

import openfl.display.BlendMode as OpenFLBlendMode;
import kha.graphics4.Graphics;

class BlendMode {
	public static var NONE(default,null):BlendMode;
	public static var NORMAL(default,null):BlendMode;
	public static var ADD(default,null):BlendMode;
	public static var MULTIPLY(default,null):BlendMode;
	public static var SCREEN(default,null):BlendMode;
	public static var SUBTRACT(default,null):BlendMode;
	public static var ERASE(default,null):BlendMode;
	public static var MASK(default,null):BlendMode;
	public static var BELOW(default,null):BlendMode;

	public static var DARKEN(default,null):BlendMode;
	public static var LIGHTEN(default,null):BlendMode;

	public static var NOPREMULT_NONE(default,null):BlendMode;
	public static var NOPREMULT_NORMAL(default,null):BlendMode;
	public static var NOPREMULT_ADD(default,null):BlendMode;
	public static var NOPREMULT_MULTIPLY(default,null):BlendMode;
	public static var NOPREMULT_SCREEN(default,null):BlendMode;
	public static var NOPREMULT_SUBTRACT(default,null):BlendMode;
	public static var NOPREMULT_ERASE(default,null):BlendMode;
	public static var NOPREMULT_MASK(default,null):BlendMode;
	public static var NOPREMULT_BELOW(default,null):BlendMode;

	public static function init() {
		if (NONE != null) return;
		PipelineSetup.init();
		inline function create(op, src, dst) return new BlendMode(new PipelineSetup(op, src, dst, false), new PipelineSetup(op, src, dst, true));
		NONE = create(Add, BlendOne, BlendZero);
		NORMAL = new BlendMode(PipelineSetup.pNormal, new PipelineSetup(Add, BlendOne, InverseSourceAlpha, true));
		ADD = create(Add, BlendOne, BlendOne);
		MULTIPLY = create(Add, DestinationColor, InverseSourceAlpha);
		SCREEN = create(Add, BlendOne, InverseSourceColor);
		SUBTRACT = create(ReverseSubtract, BlendOne, BlendOne);
		ERASE = create(Add, BlendZero, InverseSourceAlpha);
		MASK = create(Add, BlendZero, SourceAlpha);
		BELOW = create(Add, InverseDestinationAlpha, DestinationAlpha);

		DARKEN = create(Min, BlendOne, BlendOne);
		LIGHTEN = create(Max, BlendOne, BlendOne);

		NOPREMULT_NONE = create(Add, BlendOne, BlendZero);
		NOPREMULT_NORMAL = create(Add, SourceAlpha, InverseSourceAlpha);
		NOPREMULT_ADD = create(Add, SourceAlpha, DestinationAlpha);
		NOPREMULT_MULTIPLY = create(Add, DestinationColor, InverseSourceAlpha);
		NOPREMULT_SCREEN = create(Add, SourceAlpha, BlendOne);
		NOPREMULT_SUBTRACT = create(ReverseSubtract, BlendOne, BlendOne);
		NOPREMULT_ERASE = create(Add, BlendZero, InverseSourceAlpha);
		NOPREMULT_MASK = create(Add, BlendZero, SourceAlpha);
		NOPREMULT_BELOW = create(Add, InverseDestinationAlpha, DestinationAlpha);
	}

	public function setup(g4:Graphics, stencilReferenceValue:Int) {
		if (stencilReferenceValue > 0) {
			g4.setPipeline(maskedPipeline.pipeline);
			g4.setStencilReferenceValue(stencilReferenceValue);
			return maskedPipeline;
		} else {
			g4.setPipeline(normalPipeline.pipeline);
			return normalPipeline;
		}
	}

	final normalPipeline:PipelineSetup;
	final maskedPipeline:PipelineSetup;

	function new(normal, masked) {
		normalPipeline = normal;
		maskedPipeline = masked;
	}

	public static function fromOpenFLBlendMode(blendMode:OpenFLBlendMode):BlendMode {
		return switch blendMode {
			case OpenFLBlendMode.ADD: ADD;
			case OpenFLBlendMode.MULTIPLY: MULTIPLY;
			case OpenFLBlendMode.SCREEN: SCREEN;
			case OpenFLBlendMode.SUBTRACT: SUBTRACT;
			case OpenFLBlendMode.DARKEN: DARKEN;
			case OpenFLBlendMode.LIGHTEN: LIGHTEN;
			case _: NORMAL;
		}
	}
}
