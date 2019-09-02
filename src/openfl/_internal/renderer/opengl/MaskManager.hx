package openfl._internal.renderer.opengl;

import openfl.display.DisplayObject;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;

@:access(openfl.display.DisplayObject)
@:access(openfl.geom.Matrix)
@:access(openfl.geom.Rectangle)
class MaskManager {
	final renderSession:GLRenderSession;
	final incrPipeline:kha.graphics4.PipelineState;
	final incrTexUnit:kha.graphics4.TextureUnit;
	final incrMatrix:kha.graphics4.ConstantLocation;
	final decrPipeline:kha.graphics4.PipelineState;
	final decrTexUnit:kha.graphics4.TextureUnit;
	final decrMatrix:kha.graphics4.ConstantLocation;

	public final quadIndexBuffer:kha.graphics4.IndexBuffer;
	public final vertexStructure:kha.graphics4.VertexStructure;
	public var uImage0(default,null):kha.graphics4.TextureUnit;
	public var uMatrix(default,null):kha.graphics4.ConstantLocation;
	public var stencilReference(default,null):Int;

	var clipRects:Array<Rectangle>;
	var maskObjects:Array<DisplayObject>;
	var numClipRects:Int;
	var tempRect:Rectangle;

	public function new(renderSession) {
		this.renderSession = renderSession;

		quadIndexBuffer = new kha.graphics4.IndexBuffer(6, StaticUsage);
		var data = quadIndexBuffer.lock();
		data[0] = 0; data[1] = 1; data[2] = 2;
		data[3] = 0; data[4] = 2; data[5] = 3;
		quadIndexBuffer.unlock();

		vertexStructure = new kha.graphics4.VertexStructure();
		vertexStructure.add("aPosition", Float2);
		vertexStructure.add("aTexCoord", Float2);

		var vertexShader = kha.Shaders.mask_vert;
		var fragmentShader = kha.Shaders.mask_frag;

		// todo refactor this obviously
		incrPipeline = new kha.graphics4.PipelineState();
		incrPipeline.inputLayout = [vertexStructure];
		incrPipeline.vertexShader = vertexShader;
		incrPipeline.fragmentShader = fragmentShader;
		incrPipeline.colorWriteMask = false;
		incrPipeline.stencilReferenceValue = Dynamic;
		incrPipeline.stencilReadMask = 0xFF;
		incrPipeline.stencilMode = Equal;
		incrPipeline.stencilFail = Keep;
		incrPipeline.stencilDepthFail = Keep;
		incrPipeline.stencilBothPass = Increment;
		incrPipeline.compile();
		incrTexUnit = incrPipeline.getTextureUnit("uImage0");
		incrMatrix = incrPipeline.getConstantLocation("uMatrix");

		decrPipeline = new kha.graphics4.PipelineState();
		decrPipeline.inputLayout = [vertexStructure];
		decrPipeline.vertexShader = vertexShader;
		decrPipeline.fragmentShader = fragmentShader;
		decrPipeline.colorWriteMask = false;
		decrPipeline.stencilReferenceValue = Dynamic;
		decrPipeline.stencilReadMask = 0xFF;
		decrPipeline.stencilMode = Equal;
		decrPipeline.stencilFail = Keep;
		decrPipeline.stencilDepthFail = Keep;
		decrPipeline.stencilBothPass = Decrement;
		decrPipeline.compile();
		decrTexUnit = incrPipeline.getTextureUnit("uImage0");
		decrMatrix = incrPipeline.getConstantLocation("uMatrix");

		clipRects = new Array();
		maskObjects = new Array();
		numClipRects = 0;
		stencilReference = 0;
		tempRect = new Rectangle();
	}

	public function pushMask(mask:DisplayObject):Void {
		// flush everything in the current batch, since we're rendering stuff differently now
		renderSession.batcher.flush();

		var g4 = renderSession.g4;
		g4.setPipeline(incrPipeline);
		g4.setStencilReferenceValue(stencilReference);

		if (stencilReference == 0) {
			g4.clear(null, null, 0);
		}

		uImage0 = incrTexUnit;
		uMatrix = incrMatrix;
		mask.__renderGLMask(renderSession);

		// flush batched mask renders, because we're changing state again
		renderSession.batcher.flush();

		maskObjects.push(mask);
		stencilReference++;
	}

	public function pushObject(object:DisplayObject):Void {
		if (object.__scrollRect != null) {
			pushRect(object.__scrollRect, object.__renderTransform);
		}

		if (object.__mask != null) {
			pushMask(object.__mask);
		}
	}

	public function pushRect(rect:Rectangle, transform:Matrix):Void {
		// TODO: Handle rotation?

		if (numClipRects == clipRects.length) {
			clipRects[numClipRects] = new Rectangle();
		}

		var clipRect = clipRects[numClipRects];
		rect.__transform(clipRect, transform);

		if (numClipRects > 0) {
			var parentClipRect = clipRects[numClipRects - 1];
			clipRect.__contract(parentClipRect.x, parentClipRect.y, parentClipRect.width, parentClipRect.height);
		}

		if (clipRect.height < 0) {
			clipRect.height = 0;
		}

		if (clipRect.width < 0) {
			clipRect.width = 0;
		}

		scissorRect(clipRect);
		numClipRects++;
	}

	public function popMask():Void {
		if (stencilReference == 0)
			return;

		// flush whatever was rendered behind the mask, because we're changing state
		renderSession.batcher.flush();

		var mask = maskObjects.pop();
		if (stencilReference > 1) {
			var g4 = renderSession.g4;
			g4.setPipeline(decrPipeline);
			g4.setStencilReferenceValue(stencilReference);

			uImage0 = decrTexUnit;
			uMatrix = decrMatrix;
			mask.__renderGLMask(renderSession);

			// flush batched mask renders, because we're changing state again
			renderSession.batcher.flush();
			stencilReference--;
		} else {
			stencilReference = 0;
		}
	}

	public function popObject(object:DisplayObject):Void {
		if (object.__mask != null) {
			popMask();
		}

		if (object.__scrollRect != null) {
			popRect();
		}
	}

	public function popRect():Void {
		if (numClipRects > 0) {
			numClipRects--;

			if (numClipRects > 0) {
				scissorRect(clipRects[numClipRects - 1]);
			} else {
				scissorRect(null);
			}
		}
	}

	function scissorRect(rect:Rectangle) {
		// flush batched renders so they are drawn before the scissor call
		renderSession.batcher.flush();

		if (rect != null) {
			var renderer = renderSession.renderer;

			var clipRect = tempRect;
			rect.__transform(clipRect, @:privateAccess renderer.displayMatrix);

			var x = Math.floor(clipRect.x);
			var y = Math.floor(clipRect.y);
			var width = Math.ceil(clipRect.right) - x;
			var height = Math.ceil(clipRect.bottom) - y;

			if (width < 0)
				width = 0;
			if (height < 0)
				height = 0;

			renderSession.g4.scissor(x, y, width, height);
		} else {
			renderSession.g4.disableScissor();
		}
	}
}
