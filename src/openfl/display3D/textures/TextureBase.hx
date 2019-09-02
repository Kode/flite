package openfl.display3D.textures;

import js.html.webgl.Framebuffer as GLFramebuffer;
import js.html.webgl.Renderbuffer as GLRenderbuffer;
import js.html.webgl.GL;
import openfl._internal.graphics.Image;
import openfl._internal.graphics.utils.ImageCanvasUtil;
import openfl._internal.renderer.opengl.batcher.TextureData;
import openfl._internal.stage3D.GLCompressedTextureFormats;
import openfl._internal.stage3D.SamplerState;
import openfl.display.BitmapData;
import openfl.events.EventDispatcher;

@:access(openfl.display3D.Context3D)
class TextureBase extends EventDispatcher {
	private var __alphaTexture:Texture;
	private var __context:Context3D;
	private var __depthRenderbuffer:GLRenderbuffer;
	private var __depthStencilRenderbuffer:GLRenderbuffer;
	private var __format:Int;
	private var __framebuffer:GLFramebuffer;
	private var __height:Int;
	private var __internalFormat:Int;
	private var __optimizeForRenderToTexture:Bool;
	private var __samplerState:SamplerState;
	private var __stencilRenderbuffer:GLRenderbuffer;
	private var __streamingLevels:Int;
	private var __textureContext:GL;
	private var __textureData:TextureData;
	private var __textureTarget:Int;
	private var __width:Int;

	private function new(context:Context3D) {
		super();

		__context = context;
		// __textureTarget = target;

		var gl = kha.SystemImpl.gl;

		__textureData = new TextureData(TextureData.createImageFromGLTexture(gl.createTexture()));
		__textureContext = gl;
		__internalFormat = GL.RGBA;
		__format = GL.RGBA;

		if (GLCompressedTextureFormats.__instance == null) {
			GLCompressedTextureFormats.__instance = new GLCompressedTextureFormats(gl);
		}
	}

	public function dispose():Void {
		var gl = kha.SystemImpl.gl;

		if (__alphaTexture != null) {
			__alphaTexture.dispose();
		}

		if (__depthStencilRenderbuffer != null) {
			gl.deleteRenderbuffer(__depthStencilRenderbuffer);
		}

		if (__depthRenderbuffer != null) {
			gl.deleteRenderbuffer(__depthRenderbuffer);
		}

		if (__stencilRenderbuffer != null) {
			gl.deleteRenderbuffer(__stencilRenderbuffer);
		}

		if (__framebuffer != null) {
			gl.deleteFramebuffer(__framebuffer);
		}

		gl.deleteTexture(__textureData.glTexture);
	}

	@:access(openfl.display.BitmapData)
	public static function __getImage(gl:GL, bitmapData:BitmapData):Image {
		if (!bitmapData.__isValid || !bitmapData.__prepareImage()) {
			return null;
		}

		var image = bitmapData.image;

		image.sync();

		gl.pixelStorei(GL.UNPACK_PREMULTIPLY_ALPHA_WEBGL, 1);

		return image;
	}

	private function __getTexture():TextureData {
		return __textureData;
	}

	@:access(openfl._internal.stage3D.SamplerState)
	inline function __setSamplerState(state:SamplerState) {
		if (!state.equals(__samplerState)) {
			__applySamplerState(kha.SystemImpl.gl, state);
			__samplerState = state;
			__samplerState.__samplerDirty = false;
		}
	}

	function __applySamplerState(gl:GL, state:SamplerState) {
		gl.texParameteri(__textureTarget, GL.TEXTURE_MIN_FILTER, state.minFilter);
		gl.texParameteri(__textureTarget, GL.TEXTURE_MAG_FILTER, state.magFilter);
		gl.texParameteri(__textureTarget, GL.TEXTURE_WRAP_S, state.wrapModeS);
		gl.texParameteri(__textureTarget, GL.TEXTURE_WRAP_T, state.wrapModeT);

		if (state.lodBias != 0.0) {
			// TODO
			// throw new IllegalOperationError("Lod bias setting not supported yet");
		}
	}
}
