package openfl.display;

import openfl._internal.renderer.canvas.CanvasRenderSession;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;

interface IBitmapDrawable {
	private var __alpha:Float;
	private var __visible:Bool;
	private var __blendMode:BlendMode;
	private var __isMask:Bool;
	private var __renderable:Bool;
	private var __transform:Matrix;
	private var __worldAlpha:Float;
	private var __worldColorTransform:ColorTransform;
	private var __worldTransform:Matrix;
	private function __getBounds(rect:Rectangle, matrix:Matrix):Void;
	private function __renderCanvas(renderSession:CanvasRenderSession):Void;
	private function __renderCanvasMask(renderSession:CanvasRenderSession):Void;
	private function __updateChildren(transformOnly:Bool):Void;
	private function __overrideTransforms(overrideTransform:Matrix):Void;
}
