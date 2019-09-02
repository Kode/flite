package openfl.display3D;

import js.lib.Float32Array;
import js.html.webgl.GL;
import openfl._internal.renderer.opengl.GLRenderSession;
import openfl._internal.stage3D.SamplerState;
import openfl.display3D.textures.CubeTexture;
import openfl.display3D.textures.RectangleTexture;
import openfl.display3D.textures.TextureBase;
import openfl.display3D.textures.Texture;
import openfl.display3D.textures.VideoTexture;
import openfl.display.BitmapData;
import openfl.display.Stage3D;
import openfl.errors.IllegalOperationError;
import openfl.errors.Error;
import openfl.events.EventDispatcher;
import openfl.geom.Matrix3D;
import openfl.geom.Rectangle;
import openfl.geom.Point;
import openfl.utils.ByteArray;
import openfl.Vector;

@:access(openfl.display3D.textures.CubeTexture)
@:access(openfl.display3D.textures.RectangleTexture)
@:access(openfl.display3D.textures.Texture)
@:access(openfl.display3D.textures.VideoTexture)
@:access(openfl.display3D.IndexBuffer3D)
@:access(openfl.display3D.Program3D)
@:access(openfl.display3D.VertexBuffer3D)
final class Context3D extends EventDispatcher {
	public static final supportsVideoTexture = true;

	static inline var MAX_SAMPLERS = 8;
	static inline var MAX_ATTRIBUTES = 16;
	static inline var MAX_PROGRAM_REGISTERS = 128;
	static var TEXTURE_MAX_ANISOTROPY_EXT = 0;

	public var backBufferHeight(default, null):Int = 0;
	public var backBufferWidth(default, null):Int = 0;
	public var driverInfo(default, null):String = "OpenGL (Direct blitting)";
	public var enableErrorChecking:Bool; // not implemented
	public var maxBackBufferHeight(default, null):Int;
	public var maxBackBufferWidth(default, null):Int;
	public var profile(default, null):Context3DProfile = BASELINE;
	public var totalGPUMemory(default, null):Int = 0;

	var __backBufferAntiAlias:Int;
	var __backBufferEnableDepthAndStencil:Bool;
	var __backBufferWantsBestResolution:Bool;
	var __fragmentConstants:Float32Array;
	var __frameCount:Int;
	var __maxAnisotropyCubeTexture:Int;
	var __maxAnisotropyTexture2D:Int;
	var __positionScale:Float32Array;
	var __program:Program3D;
	var __renderSession:GLRenderSession;
	var __renderToTexture:TextureBase;
	var __rttDepthAndStencil:Bool;
	var __samplerDirty:Int;
	var __samplerTextures:Vector<TextureBase>;
	var __samplerStates:Array<SamplerState>;
	var __stage3D:Stage3D;
	var __stencilCompareMode:Context3DCompareMode;
	var __stencilRef:Int;
	var __stencilReadMask:Int;
	var __supportsAnisotropicFiltering:Bool;
	var __vertexConstants:Float32Array;

	function new(stage3D:Stage3D, renderSession:GLRenderSession) {
		super();

		__stage3D = stage3D;
		__renderSession = renderSession;

		__vertexConstants = new Float32Array(4 * MAX_PROGRAM_REGISTERS);
		__fragmentConstants = new Float32Array(4 * MAX_PROGRAM_REGISTERS);
		__positionScale = new Float32Array([1.0, 1.0, 1.0, 1.0]);
		__samplerDirty = 0;
		__samplerTextures = new Vector<TextureBase>(MAX_SAMPLERS);
		__samplerStates = [for (i in 0...MAX_SAMPLERS) new SamplerState(GL.LINEAR, GL.LINEAR, GL.CLAMP_TO_EDGE, GL.CLAMP_TO_EDGE)];
		__backBufferAntiAlias = 0;
		__backBufferEnableDepthAndStencil = true;
		__backBufferWantsBestResolution = false;
		__frameCount = 0;
		__rttDepthAndStencil = false;
		__samplerDirty = 0;
		__stencilCompareMode = Context3DCompareMode.ALWAYS;
		__stencilRef = 0;
		__stencilReadMask = 0xFF;

		var gl = kha.SystemImpl.gl;

		maxBackBufferHeight = maxBackBufferWidth = gl.getParameter(GL.MAX_VIEWPORT_DIMS); // TODO: wat? this returns an Int32Array I think

		var anisoExtension = gl.getExtension("EXT_texture_filter_anisotropic");
		if (anisoExtension == null || !Reflect.hasField(anisoExtension, "MAX_TEXTURE_MAX_ANISOTROPY_EXT"))
			anisoExtension = gl.getExtension("MOZ_EXT_texture_filter_anisotropic");
		if (anisoExtension == null || !Reflect.hasField(anisoExtension, "MAX_TEXTURE_MAX_ANISOTROPY_EXT"))
			anisoExtension = gl.getExtension("WEBKIT_EXT_texture_filter_anisotropic");

		__supportsAnisotropicFiltering = (anisoExtension != null);
		if (__supportsAnisotropicFiltering) {
			TEXTURE_MAX_ANISOTROPY_EXT = anisoExtension.TEXTURE_MAX_ANISOTROPY_EXT;
			__maxAnisotropyTexture2D = gl.getParameter(anisoExtension.MAX_TEXTURE_MAX_ANISOTROPY_EXT);
		}

		var vendor = gl.getParameter(GL.VENDOR);
		var version = gl.getParameter(GL.VERSION);
		var renderer = gl.getParameter(GL.RENDERER);
		var glslVersion = gl.getParameter(GL.SHADING_LANGUAGE_VERSION);
		driverInfo = "OpenGL" + " Vendor=" + vendor + " Version=" + version + " Renderer=" + renderer + " GLSL=" + glslVersion;
	}

	public function clear(red:Float = 0, green:Float = 0, blue:Float = 0, alpha:Float = 1, depth:Float = 1, stencil:UInt = 0,
			mask:UInt = Context3DClearMask.ALL):Void {

		var gl = kha.SystemImpl.gl;

		var clearMask = 0;

		if (mask & Context3DClearMask.COLOR != 0) {
			clearMask |= GL.COLOR_BUFFER_BIT;
			gl.clearColor(red, green, blue, alpha);
		}

		if (mask & Context3DClearMask.DEPTH != 0) {
			clearMask |= GL.DEPTH_BUFFER_BIT;
			gl.clearDepth(depth);
		}

		if (mask & Context3DClearMask.STENCIL != 0) {
			clearMask |= GL.STENCIL_BUFFER_BIT;
			gl.clearStencil(stencil);
		}

		gl.clear(clearMask);
	}

	public function configureBackBuffer(width:Int, height:Int, antiAlias:Int, enableDepthAndStencil:Bool = true, wantsBestResolution:Bool = false,
			wantsBestResolutionOnBrowserZoom:Bool = false):Void {

		__updateBackbufferViewport();

		var scale = @:privateAccess __stage3D.__stage.window.scale;

		backBufferWidth = Math.ceil(width * scale);
		backBufferHeight = Math.ceil(height * scale);

		__backBufferAntiAlias = antiAlias;
		__backBufferEnableDepthAndStencil = enableDepthAndStencil;
		__backBufferWantsBestResolution = wantsBestResolution;
	}

	public function createCubeTexture(size:Int, format:Context3DTextureFormat, optimizeForRenderToTexture:Bool, streamingLevels:Int = 0):CubeTexture {
		return new CubeTexture(this, size, format, optimizeForRenderToTexture, streamingLevels);
	}

	public function createIndexBuffer(numIndices:Int, bufferUsage:Context3DBufferUsage = STATIC_DRAW):IndexBuffer3D {
		return new IndexBuffer3D(this, numIndices, bufferUsage);
	}

	public function createProgram():Program3D {
		return new Program3D(this);
	}

	public function createRectangleTexture(width:Int, height:Int, format:Context3DTextureFormat, optimizeForRenderToTexture:Bool):RectangleTexture {
		return new RectangleTexture(this, width, height, format, optimizeForRenderToTexture);
	}

	public function createTexture(width:Int, height:Int, format:Context3DTextureFormat, optimizeForRenderToTexture:Bool, streamingLevels:Int = 0):Texture {
		return new Texture(this, width, height, format, optimizeForRenderToTexture, streamingLevels);
	}

	public function createVertexBuffer(numVertices:Int, data32PerVertex:Int, bufferUsage:Context3DBufferUsage = STATIC_DRAW):VertexBuffer3D {
		return new VertexBuffer3D(this, numVertices, data32PerVertex, bufferUsage);
	}

	public function createVideoTexture():VideoTexture {
		return new VideoTexture(this);
	}

	public function dispose(recreate:Bool = true):Void {
		// TODO
	}

	@:access(openfl.display.BitmapData.image)
	public function drawToBitmapData(destination:BitmapData):Void {
		var window = @:privateAccess __stage3D.__stage.window;
		var image = window.readPixels();
		var heightOffset = image.height - backBufferHeight;

		destination.image.copyPixels(image,
			new Rectangle(Std.int(__stage3D.x), Std.int(__stage3D.y + heightOffset), backBufferWidth, backBufferHeight),
			new Point());
	}

	public function drawTriangles(indexBuffer:IndexBuffer3D, firstIndex:Int = 0, numTriangles:Int = -1):Void {
		if (__program == null) {
			return;
		}

		__flushSamplerState();
		__program.__flush();

		var count = (numTriangles == -1) ? indexBuffer.__numIndices : (numTriangles * 3);

		var gl = kha.SystemImpl.gl;
		gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexBuffer.__id);
		gl.drawElements(GL.TRIANGLES, count, indexBuffer.__elementType, firstIndex);
	}

	@:access(openfl.display3D.textures.TextureBase)
	function __flushSamplerState() {
		var gl = kha.SystemImpl.gl;

		var sampler = 0;
		while (__samplerDirty != 0) {
			if ((__samplerDirty & (1 << sampler)) != 0) {
				gl.activeTexture(GL.TEXTURE0 + sampler);

				var texture = __samplerTextures[sampler];
				if (texture != null) {
					gl.bindTexture(texture.__textureTarget, texture.__getTexture().glTexture);
					texture.__setSamplerState(__samplerStates[sampler]);
				} else {
					gl.bindTexture(GL.TEXTURE_2D, null);
				}

				__samplerDirty &= ~(1 << sampler);
			}
			sampler++;
		}
	}

	public function present():Void {}

	public function setBlendFactors(sourceFactor:Context3DBlendFactor, destinationFactor:Context3DBlendFactor):Void {
		var gl = kha.SystemImpl.gl;
		gl.enable(GL.BLEND);
		gl.blendFunc(__getGLBlendFactor(sourceFactor), __getGLBlendFactor(destinationFactor));
	}

	static function __getGLBlendFactor(blendFactor:Context3DBlendFactor):Int {
		return switch (blendFactor) {
			case DESTINATION_ALPHA: GL.DST_ALPHA;
			case DESTINATION_COLOR: GL.DST_COLOR;
			case ONE: GL.ONE;
			case ONE_MINUS_DESTINATION_ALPHA: GL.ONE_MINUS_DST_ALPHA;
			case ONE_MINUS_DESTINATION_COLOR: GL.ONE_MINUS_DST_COLOR;
			case ONE_MINUS_SOURCE_ALPHA: GL.ONE_MINUS_SRC_ALPHA;
			case ONE_MINUS_SOURCE_COLOR: GL.ONE_MINUS_SRC_COLOR;
			case SOURCE_ALPHA: GL.SRC_ALPHA;
			case SOURCE_COLOR: GL.SRC_COLOR;
			case ZERO: GL.ZERO;
			default:
				throw new IllegalOperationError();
		}
	}

	public function setColorMask(red:Bool, green:Bool, blue:Bool, alpha:Bool):Void {
		kha.SystemImpl.gl.colorMask(red, green, blue, alpha);
	}

	public function setCulling(triangleFaceToCull:Context3DTriangleFace):Void {
		var gl = kha.SystemImpl.gl;
		if (triangleFaceToCull == NONE) {
			gl.disable(GL.CULL_FACE);
		} else {
			gl.enable(GL.CULL_FACE);
			gl.cullFace(__getGLTriangleFace(triangleFaceToCull, true));
		}
	}

	public function setDepthTest(depthMask:Bool, passCompareMode:Context3DCompareMode):Void {
		var gl = kha.SystemImpl.gl;

		if (__backBufferEnableDepthAndStencil) {
			gl.enable(GL.DEPTH_TEST);
		} else {
			gl.disable(GL.DEPTH_TEST);
		}

		gl.depthMask(depthMask);
		gl.depthFunc(__getGLCompareMode(passCompareMode));
	}

	public function setProgram(program:Program3D):Void {
		if (program == null) {
			throw new IllegalOperationError();
		}

		program.__use();
		program.__setPositionScale(__positionScale);

		__program = program;
		__samplerDirty |= __program.__samplerUsageMask;

		for (i in 0...MAX_SAMPLERS) {
			__samplerStates[i].copyFrom(__program.__getSamplerState(i));
		}
	}

	public function setProgramConstantsFromByteArray(programType:Context3DProgramType, firstRegister:Int, numRegisters:Int, data:ByteArray,
			byteArrayOffset:UInt):Void {
		if (numRegisters == 0)
			return;

		if (numRegisters == -1) {
			numRegisters = ((data.length >> 2) - byteArrayOffset);
		}

		var isVertex = (programType == VERTEX);
		var dest = isVertex ? __vertexConstants : __fragmentConstants;

		var floatData = new Float32Array(data);
		var outOffset = firstRegister * 4;
		var inOffset = Std.int(byteArrayOffset / 4);

		for (i in 0...(numRegisters * 4)) {
			dest[outOffset + i] = floatData[inOffset + i];
		}

		if (__program != null) {
			__program.__markDirty(isVertex, firstRegister, numRegisters);
		}
	}

	public function setProgramConstantsFromMatrix(programType:Context3DProgramType, firstRegister:Int, matrix:Matrix3D, transposedMatrix:Bool = false):Void {
		var isVertex = (programType == VERTEX);
		var dest = isVertex ? __vertexConstants : __fragmentConstants;
		var source = matrix.rawData;
		var i = firstRegister * 4;

		if (transposedMatrix) {
			dest[i++] = source[0];
			dest[i++] = source[4];
			dest[i++] = source[8];
			dest[i++] = source[12];

			dest[i++] = source[1];
			dest[i++] = source[5];
			dest[i++] = source[9];
			dest[i++] = source[13];

			dest[i++] = source[2];
			dest[i++] = source[6];
			dest[i++] = source[10];
			dest[i++] = source[14];

			dest[i++] = source[3];
			dest[i++] = source[7];
			dest[i++] = source[11];
			dest[i++] = source[15];
		} else {
			dest[i++] = source[0];
			dest[i++] = source[1];
			dest[i++] = source[2];
			dest[i++] = source[3];

			dest[i++] = source[4];
			dest[i++] = source[5];
			dest[i++] = source[6];
			dest[i++] = source[7];

			dest[i++] = source[8];
			dest[i++] = source[9];
			dest[i++] = source[10];
			dest[i++] = source[11];

			dest[i++] = source[12];
			dest[i++] = source[13];
			dest[i++] = source[14];
			dest[i++] = source[15];
		}

		if (__program != null) {
			__program.__markDirty(isVertex, firstRegister, 4);
		}
	}

	public function setProgramConstantsFromVector(programType:Context3DProgramType, firstRegister:Int, data:Vector<Float>, numRegisters:Int = -1):Void {
		if (numRegisters == 0)
			return;

		if (numRegisters == -1) {
			numRegisters = (data.length >> 2);
		}

		var isVertex = (programType == VERTEX);
		var dest = isVertex ? __vertexConstants : __fragmentConstants;
		var source = data;

		var sourceIndex = 0;
		var destIndex = firstRegister * 4;

		for (i in 0...numRegisters) {
			dest[destIndex++] = source[sourceIndex++];
			dest[destIndex++] = source[sourceIndex++];
			dest[destIndex++] = source[sourceIndex++];
			dest[destIndex++] = source[sourceIndex++];
		}

		if (__program != null) {
			__program.__markDirty(isVertex, firstRegister, numRegisters);
		}
	}

	public function setRenderToBackBuffer():Void {
		var gl = kha.SystemImpl.gl;

		gl.bindFramebuffer(GL.FRAMEBUFFER, null);
		gl.frontFace(GL.CCW);

		__renderToTexture = null;
		__updateBackbufferViewport();
		__disableScissorRectangle();
		__updateDepthAndStencilState();

		__positionScale[1] = 1.0;

		if (__program != null) {
			__program.__setPositionScale(__positionScale);
		}
	}

	@:access(openfl.display3D.textures.TextureBase)
	public function setRenderToTexture(texture:TextureBase, enableDepthAndStencil:Bool = false, antiAlias:Int = 0, surfaceSelector:Int = 0):Void {
		var gl = kha.SystemImpl.gl;

		var width = texture.__width;
		var height = texture.__height;

		var create = texture.__framebuffer == null;

		if (create) {
			texture.__framebuffer = gl.createFramebuffer();
		}

		gl.bindFramebuffer(GL.FRAMEBUFFER, texture.__framebuffer);

		if (create) {
			if (Std.is(texture, Texture)) {
				gl.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0, GL.TEXTURE_2D, texture.__textureData.glTexture, 0);
			} else if (Std.is(texture, RectangleTexture)) {
				gl.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0, GL.TEXTURE_2D, texture.__textureData.glTexture, 0);
			} else if (Std.is(texture, CubeTexture)) {
				for (i in 0...6) {
					gl.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0, GL.TEXTURE_CUBE_MAP_POSITIVE_X + i, texture.__textureData.glTexture, 0);
				}
			} else {
				throw new Error("Invalid texture");
			}
		}

		if (create && enableDepthAndStencil) {
			texture.__depthStencilRenderbuffer = gl.createRenderbuffer();
			gl.bindRenderbuffer(GL.RENDERBUFFER, texture.__depthStencilRenderbuffer);
			gl.renderbufferStorage(GL.RENDERBUFFER, GL.DEPTH_STENCIL, width, height);
			gl.framebufferRenderbuffer(GL.FRAMEBUFFER, GL.DEPTH_STENCIL_ATTACHMENT, GL.RENDERBUFFER, texture.__depthStencilRenderbuffer);
			gl.bindRenderbuffer(GL.RENDERBUFFER, null);
		}

		gl.viewport(0, 0, width, height);

		__positionScale[1] = -1.0;
		if (__program != null) {
			__program.__setPositionScale(__positionScale);
		}

		gl.frontFace(GL.CW);

		__renderToTexture = texture;
		__rttDepthAndStencil = enableDepthAndStencil;
		__disableScissorRectangle();
		__updateDepthAndStencilState();
	}

	public function setSamplerStateAt(sampler:Int, wrap:Context3DWrapMode, filter:Context3DTextureFilter, mipfilter:Context3DMipFilter):Void {
		if (sampler < 0 || sampler > Context3D.MAX_SAMPLERS) {
			throw new Error("sampler out of range");
		}

		var state = __samplerStates[sampler];

		switch (wrap) {
			case Context3DWrapMode.CLAMP:
				state.wrapModeS = GL.CLAMP_TO_EDGE;
				state.wrapModeT = GL.CLAMP_TO_EDGE;

			case Context3DWrapMode.CLAMP_U_REPEAT_V:
				state.wrapModeS = GL.CLAMP_TO_EDGE;
				state.wrapModeT = GL.REPEAT;

			case Context3DWrapMode.REPEAT:
				state.wrapModeS = GL.REPEAT;
				state.wrapModeT = GL.REPEAT;

			case Context3DWrapMode.REPEAT_U_CLAMP_V:
				state.wrapModeS = GL.REPEAT;
				state.wrapModeT = GL.CLAMP_TO_EDGE;

			default:
				throw new Error("wrap bad enum");
		}

		switch (filter) {
			case Context3DTextureFilter.LINEAR:
				state.magFilter = GL.LINEAR;
				if (__supportsAnisotropicFiltering) {
					state.maxAniso = 1;
				}

			case Context3DTextureFilter.NEAREST:
				state.magFilter = GL.NEAREST;
				if (__supportsAnisotropicFiltering) {
					state.maxAniso = 1;
				}

			case Context3DTextureFilter.ANISOTROPIC2X:
				if (__supportsAnisotropicFiltering) {
					state.maxAniso = (__maxAnisotropyTexture2D < 2 ? __maxAnisotropyTexture2D : 2);
				}

			case Context3DTextureFilter.ANISOTROPIC4X:
				if (__supportsAnisotropicFiltering) {
					state.maxAniso = (__maxAnisotropyTexture2D < 4 ? __maxAnisotropyTexture2D : 4);
				}

			case Context3DTextureFilter.ANISOTROPIC8X:
				if (__supportsAnisotropicFiltering) {
					state.maxAniso = (__maxAnisotropyTexture2D < 8 ? __maxAnisotropyTexture2D : 8);
				}

			case Context3DTextureFilter.ANISOTROPIC16X:
				if (__supportsAnisotropicFiltering) {
					state.maxAniso = (__maxAnisotropyTexture2D < 16 ? __maxAnisotropyTexture2D : 16);
				}

			default:
				throw new Error("filter bad enum");
		}

		switch (mipfilter) {
			case Context3DMipFilter.MIPLINEAR:
				state.minFilter = filter == Context3DTextureFilter.NEAREST ? GL.NEAREST_MIPMAP_LINEAR : GL.LINEAR_MIPMAP_LINEAR;

			case Context3DMipFilter.MIPNEAREST:
				state.minFilter = filter == Context3DTextureFilter.NEAREST ? GL.NEAREST_MIPMAP_NEAREST : GL.LINEAR_MIPMAP_NEAREST;

			case Context3DMipFilter.MIPNONE:
				state.minFilter = filter == Context3DTextureFilter.NEAREST ? GL.NEAREST : GL.LINEAR;

			default:
				throw new Error("mipfiter bad enum");
		}
	}

	public function setScissorRectangle(rectangle:Rectangle):Void {
		if (rectangle != null) {
			var scale = @:privateAccess __stage3D.__stage.window.scale;
			__setScissorRectangle(Std.int(rectangle.x * scale), Std.int(rectangle.y * scale), Std.int(rectangle.width * scale), Std.int(rectangle.height * scale));
		} else {
			__disableScissorRectangle();
		}
	}

	public function setStencilActions(triangleFace:Context3DTriangleFace = FRONT_AND_BACK, compareMode:Context3DCompareMode = ALWAYS,
			actionOnBothPass:Context3DStencilAction = KEEP, actionOnDepthFail:Context3DStencilAction = KEEP,
			actionOnDepthPassStencilFail:Context3DStencilAction = KEEP):Void {

		__stencilCompareMode = compareMode;

		var gl = kha.SystemImpl.gl;
		gl.stencilOpSeparate(
			__getGLTriangleFace(triangleFace, false),
			__getGLStencilAction(actionOnDepthPassStencilFail),
			__getGLStencilAction(actionOnDepthFail),
			__getGLStencilAction(actionOnBothPass)
		);
		gl.stencilFunc(
			__getGLCompareMode(compareMode),
			__stencilRef,
			__stencilReadMask
		);
	}

	public function setStencilReferenceValue(referenceValue:UInt, readMask:UInt = 0xFF, writeMask:UInt = 0xFF):Void {
		__stencilReadMask = readMask;
		__stencilRef = referenceValue;

		var gl = kha.SystemImpl.gl;
		gl.stencilMask(writeMask);
		gl.stencilFunc(__getGLCompareMode(__stencilCompareMode), referenceValue, readMask);
	}

	static function __getGLCompareMode(compareMode:Context3DCompareMode):Int {
		return switch (compareMode) {
			case ALWAYS: GL.ALWAYS;
			case EQUAL: GL.EQUAL;
			case GREATER: GL.GREATER;
			case GREATER_EQUAL: GL.GEQUAL;
			case LESS: GL.LESS;
			case LESS_EQUAL: GL.LEQUAL;
			case NEVER: GL.NEVER;
			case NOT_EQUAL: GL.NOTEQUAL;
			default: throw new IllegalOperationError();
		};
	}

	static function __getGLTriangleFace(triangleFace:Context3DTriangleFace, swap:Bool):Int {
		return switch (triangleFace) {
			case FRONT: swap ? GL.BACK : GL.FRONT;
			case BACK: swap ? GL.FRONT : GL.BACK;
			case FRONT_AND_BACK: GL.FRONT_AND_BACK;
			case NONE: GL.NONE;
			default: throw new IllegalOperationError();
		};
	}

	static function __getGLStencilAction(stencilAction:Context3DStencilAction):Int {
		return switch (stencilAction) {
			case DECREMENT_SATURATE: GL.DECR;
			case DECREMENT_WRAP: GL.DECR_WRAP;
			case INCREMENT_SATURATE: GL.INCR;
			case INCREMENT_WRAP: GL.INCR_WRAP;
			case INVERT: GL.INVERT;
			case KEEP: GL.KEEP;
			case SET: GL.REPLACE;
			case ZERO: GL.ZERO;
			default: throw new IllegalOperationError();
		};
	}

	public function setTextureAt(sampler:Int, texture:TextureBase):Void {
		if (__samplerTextures[sampler] != texture) {
			__samplerTextures[sampler] = texture;
			__samplerDirty |= (1 << sampler);
		}
	}

	public function setVertexBufferAt(index:Int, buffer:VertexBuffer3D, bufferOffset:Int = 0, format:Context3DVertexBufferFormat = FLOAT_4):Void {
		var gl = kha.SystemImpl.gl;

		if (buffer == null) {
			gl.disableVertexAttribArray(index);
			gl.bindBuffer(GL.ARRAY_BUFFER, null);
			return;
		}

		gl.enableVertexAttribArray(index);
		gl.bindBuffer(GL.ARRAY_BUFFER, buffer.__id);

		var byteOffset = bufferOffset * 4;
		switch (format) {
			case BYTES_4:
				gl.vertexAttribPointer(index, 4, GL.UNSIGNED_BYTE, true, buffer.__stride, byteOffset);

			case FLOAT_4:
				gl.vertexAttribPointer(index, 4, GL.FLOAT, false, buffer.__stride, byteOffset);

			case FLOAT_3:
				gl.vertexAttribPointer(index, 3, GL.FLOAT, false, buffer.__stride, byteOffset);

			case FLOAT_2:
				gl.vertexAttribPointer(index, 2, GL.FLOAT, false, buffer.__stride, byteOffset);

			case FLOAT_1:
				gl.vertexAttribPointer(index, 1, GL.FLOAT, false, buffer.__stride, byteOffset);

			default:
				throw new IllegalOperationError();
		}
	}

	@:access(openfl.display.Stage3D)
	function __updateBackbufferViewport() {
		if (!Stage3D.__active) {
			Stage3D.__active = true;
			__renderSession.renderer.clear();
		}

		if (__renderToTexture == null && backBufferWidth > 0 && backBufferHeight > 0) {
			kha.SystemImpl.gl.viewport(Std.int(__stage3D.x), Std.int(__stage3D.y), backBufferWidth, backBufferHeight);
		}
	}

	function __updateDepthAndStencilState() {
		var gl = kha.SystemImpl.gl;
		var depthAndStencil = __renderToTexture != null ? __rttDepthAndStencil : __backBufferEnableDepthAndStencil;
		if (depthAndStencil) {
			gl.enable(GL.DEPTH_TEST);
			gl.enable(GL.STENCIL_TEST);
		} else {
			gl.disable(GL.DEPTH_TEST);
			gl.disable(GL.STENCIL_TEST);
		}
	}

	inline function __disableScissorRectangle() {
		kha.SystemImpl.gl.disable(GL.SCISSOR_TEST);
	}

	function __setScissorRectangle(x:Int, y:Int, width:Int, height:Int) {
		var gl = kha.SystemImpl.gl;

		gl.enable(GL.SCISSOR_TEST);

		var renderTargetHeight = 0;
		var offsetX = 0;
		var offsetY = 0;

		if (__renderToTexture != null) {
			renderTargetHeight = @:privateAccess __renderToTexture.__height;
		} else {
			renderTargetHeight = backBufferHeight;
			offsetX = Std.int(__stage3D.x);
			offsetY = Std.int(__stage3D.y);
		}

		gl.scissor(x + offsetX, renderTargetHeight - y - height + offsetY, width, height);
	}
}
