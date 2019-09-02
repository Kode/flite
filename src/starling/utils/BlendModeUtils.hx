package starling.utils;

import openfl._internal.renderer.opengl.batcher.BlendMode as BatcherBlendMode;
import starling.display.BlendMode;

class BlendModeUtils {
	public static function toBatcherBlendMode(blendMode:String, premultipliedAlpha:Bool):BatcherBlendMode {
		return switch [premultipliedAlpha, blendMode] {
			case [true, BlendMode.NONE]: BatcherBlendMode.NONE;
			case [true, BlendMode.NORMAL]: BatcherBlendMode.NORMAL;
			case [true, BlendMode.ADD]: BatcherBlendMode.ADD;
			case [true, BlendMode.MULTIPLY]: BatcherBlendMode.MULTIPLY;
			case [true, BlendMode.SCREEN]: BatcherBlendMode.SCREEN;
			case [true, BlendMode.ERASE]: BatcherBlendMode.ERASE;
			case [true, BlendMode.MASK]: BatcherBlendMode.MASK;
			case [true, BlendMode.BELOW]: BatcherBlendMode.BELOW;
			case [true, _]: BatcherBlendMode.NORMAL;
			case [false, BlendMode.NONE]: BatcherBlendMode.NOPREMULT_NONE;
			case [false, BlendMode.NORMAL]: BatcherBlendMode.NOPREMULT_NORMAL;
			case [false, BlendMode.ADD]: BatcherBlendMode.NOPREMULT_ADD;
			case [false, BlendMode.MULTIPLY]: BatcherBlendMode.NOPREMULT_MULTIPLY;
			case [false, BlendMode.SCREEN]: BatcherBlendMode.NOPREMULT_SCREEN;
			case [false, BlendMode.ERASE]: BatcherBlendMode.NOPREMULT_ERASE;
			case [false, BlendMode.MASK]: BatcherBlendMode.NOPREMULT_MASK;
			case [false, BlendMode.BELOW]: BatcherBlendMode.NOPREMULT_BELOW;
			case [false, _]: BatcherBlendMode.NOPREMULT_NORMAL;
		}
	}
}
