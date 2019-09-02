package openfl.display3D.textures;

import js.html.webgl.GL;
import js.lib.ArrayBufferView;
import js.lib.Uint8Array;
import openfl._internal.stage3D.atf.ATFReader;
import openfl._internal.stage3D.SamplerState;
import openfl._internal.stage3D.GLCompressedTextureFormats;
import openfl.display.BitmapData;
import openfl.events.Event;
import openfl.utils.ByteArray;

@:access(openfl.display3D.Context3D)
@:final class Texture extends TextureBase {
	private static var __lowMemoryMode:Bool = false;

	private function new(context:Context3D, width:Int, height:Int, format:Context3DTextureFormat, optimizeForRenderToTexture:Bool, streamingLevels:Int) {
		super(context);

		__width = width;
		__height = height;
		// __format = format;
		__optimizeForRenderToTexture = optimizeForRenderToTexture;
		__streamingLevels = streamingLevels;
		__textureTarget = GL.TEXTURE_2D;

		var gl = kha.SystemImpl.gl;

		gl.bindTexture(GL.TEXTURE_2D, __textureData.glTexture);
		gl.texImage2D(GL.TEXTURE_2D, 0, __internalFormat, width, height, 0, __format, GL.UNSIGNED_BYTE, null);
		gl.bindTexture(GL.TEXTURE_2D, null);
	}

	public function uploadCompressedTextureFromByteArray(data:ByteArray, byteArrayOffset:UInt, async:Bool = false):Void {
		if (!async) {
			__uploadCompressedTextureFromByteArray(data, byteArrayOffset);
		} else {
			haxe.Timer.delay(function() {
				__uploadCompressedTextureFromByteArray(data, byteArrayOffset);
				dispatchEvent(new Event(Event.TEXTURE_READY));
			}, 1);
		}
	}

	public function uploadFromBitmapData(source:BitmapData, miplevel:UInt = 0, generateMipmap:Bool = false):Void {
		if (source == null)
			return;

		var width = __width >> miplevel;
		var height = __height >> miplevel;

		if (width == 0 && height == 0)
			return;

		if (width == 0)
			width = 1;
		if (height == 0)
			height = 1;

		if (source.width != width || source.height != height) {
			var copy = new BitmapData(width, height, true, 0);
			copy.draw(source);
			source = copy;
		}

		var image = TextureBase.__getImage(kha.SystemImpl.gl, source);
		uploadFromTypedArray(image.getData(), miplevel);
	}

	public function uploadFromByteArray(data:ByteArray, byteArrayOffset:UInt, miplevel:UInt = 0):Void {
		var data = if (byteArrayOffset == 0) @:privateAccess (data : ByteArrayData).b else new Uint8Array(data, byteArrayOffset);
		uploadFromTypedArray(data, miplevel);
	}

	public function uploadFromTypedArray(data:ArrayBufferView, miplevel:UInt = 0):Void {
		if (data == null)
			return;

		var width = __width >> miplevel;
		var height = __height >> miplevel;

		if (width == 0 && height == 0)
			return;

		if (width == 0)
			width = 1;
		if (height == 0)
			height = 1;

		var gl = kha.SystemImpl.gl;
		gl.bindTexture(__textureTarget, __textureData.glTexture);
		gl.texImage2D(__textureTarget, miplevel, __internalFormat, width, height, 0, __format, GL.UNSIGNED_BYTE, data);
		gl.bindTexture(__textureTarget, null);
	}

	override function __applySamplerState(gl:GL, state:SamplerState) {
		if (state.minFilter != GL.NEAREST && state.minFilter != GL.LINEAR && !state.mipmapGenerated) {
			gl.generateMipmap(GL.TEXTURE_2D);
			state.mipmapGenerated = true;
		}

		if (state.maxAniso != 0.0) {
			gl.texParameterf(GL.TEXTURE_2D, Context3D.TEXTURE_MAX_ANISOTROPY_EXT, state.maxAniso);
		}

		super.__applySamplerState(gl, state);
	}

	function __uploadCompressedTextureFromByteArray(data:ByteArray, byteArrayOffset:UInt) {
		var reader = new ATFReader(data, byteArrayOffset);
		var alpha = reader.readHeader(__width, __height, false);

		var gl = kha.SystemImpl.gl;
		gl.bindTexture(__textureTarget, __textureData.glTexture);

		var hasTexture = false;
		reader.readTextures(function(target, level, gpuFormat, width, height, bytes) {
			var format = GLCompressedTextureFormats.__instance.toTextureFormat(alpha, gpuFormat);
			if (format == 0)
				return;

			hasTexture = true;
			__format = format;
			__internalFormat = format;

			gl.compressedTexImage2D(__textureTarget, level, __internalFormat, width, height, 0, bytes.getData());
		});

		if (!hasTexture) {
			var data = new Uint8Array(__width * __height * 4);
			gl.texImage2D(__textureTarget, 0, __internalFormat, __width, __height, 0, __format, GL.UNSIGNED_BYTE, data);
		}

		gl.bindTexture(__textureTarget, null);
	}
}
