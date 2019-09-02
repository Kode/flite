package openfl.display3D.textures;

import js.lib.ArrayBufferView;
import js.lib.Uint8Array;
import js.html.webgl.GL;
import openfl._internal.stage3D.atf.ATFReader;
import openfl._internal.stage3D.SamplerState;
import openfl._internal.stage3D.GLCompressedTextureFormats;
import openfl.display.BitmapData;
import openfl.events.Event;
import openfl.utils.ByteArray;
import openfl.errors.IllegalOperationError;

@:access(openfl.display3D.Context3D)
@:final class CubeTexture extends TextureBase {
	private var __size:Int;
	private var __uploadedSides:Int;

	private function new(context:Context3D, size:Int, format:Context3DTextureFormat, optimizeForRenderToTexture:Bool, streamingLevels:Int) {
		super(context);

		__size = size;
		__width = __height = __size;
		// __format = format;
		__optimizeForRenderToTexture = optimizeForRenderToTexture;
		__streamingLevels = streamingLevels;
		__textureTarget = GL.TEXTURE_CUBE_MAP;
		__uploadedSides = 0;
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

	public function uploadFromBitmapData(source:BitmapData, side:UInt, miplevel:UInt = 0, generateMipmap:Bool = false):Void {
		if (source == null)
			return;

		var size = __size >> miplevel;
		if (size == 0)
			return;

		// if (source.width != size || source.height != size) {
		//
		// var copy = new BitmapData (size, size, true, 0);
		// copy.draw (source);
		// source = copy;
		//
		// }

		var image = TextureBase.__getImage(kha.SystemImpl.gl, source);
		uploadFromTypedArray(image.getData(), side, miplevel);
	}

	public function uploadFromByteArray(data:ByteArray, byteArrayOffset:UInt, side:UInt, miplevel:UInt = 0):Void {
		var data = if (byteArrayOffset == 0) @:privateAccess (data : ByteArrayData).b else new Uint8Array(data, byteArrayOffset);
		uploadFromTypedArray(data, side, miplevel);
	}

	public function uploadFromTypedArray(data:ArrayBufferView, side:UInt, miplevel:UInt = 0):Void {
		if (data == null)
			return;

		var size = __size >> miplevel;
		if (size == 0)
			return;

		var target = __sideToTarget(side);

		var gl = kha.SystemImpl.gl;
		gl.bindTexture(__textureTarget, __textureData.glTexture);
		gl.texImage2D(target, miplevel, __internalFormat, size, size, 0, __format, GL.UNSIGNED_BYTE, data);
		gl.bindTexture(__textureTarget, null);

		__uploadedSides |= 1 << side;
	}

	override function __applySamplerState(gl:GL, state:SamplerState) {
		if (state.minFilter != GL.NEAREST && state.minFilter != GL.LINEAR && !state.mipmapGenerated) {
			gl.generateMipmap(GL.TEXTURE_CUBE_MAP);
			state.mipmapGenerated = true;
		}

		if (state.maxAniso != 0.0) {
			gl.texParameterf(GL.TEXTURE_CUBE_MAP, Context3D.TEXTURE_MAX_ANISOTROPY_EXT, state.maxAniso);
		}

		super.__applySamplerState(gl, state);
	}

	function __uploadCompressedTextureFromByteArray(data:ByteArray, byteArrayOffset:UInt):Void {
		var reader = new ATFReader(data, byteArrayOffset);
		var alpha = reader.readHeader(__size, __size, true);

		var gl = kha.SystemImpl.gl;

		gl.bindTexture(__textureTarget, __textureData.glTexture);

		var hasTexture = false;

		reader.readTextures(function(side, level, gpuFormat, width, height, bytes) {
			var format = GLCompressedTextureFormats.__instance.toTextureFormat(alpha, gpuFormat);
			if (format == 0)
				return;

			hasTexture = true;

			__format = format;

			var target = __sideToTarget(side);
			gl.compressedTexImage2D(target, level, __internalFormat, width, height, 0, bytes.getData());
		});

		if (!hasTexture) {
			for (side in 0...6) {
				var data = new Uint8Array(__size * __size * 4);
				gl.texImage2D(__sideToTarget(side), 0, __internalFormat, __size, __size, 0, __format, GL.UNSIGNED_BYTE, data);
			}
		}

		gl.bindTexture(__textureTarget, null);
	}

	static function __sideToTarget(side:UInt) {
		return switch (side) {
			case 0: GL.TEXTURE_CUBE_MAP_NEGATIVE_X;
			case 1: GL.TEXTURE_CUBE_MAP_POSITIVE_X;
			case 2: GL.TEXTURE_CUBE_MAP_NEGATIVE_Y;
			case 3: GL.TEXTURE_CUBE_MAP_POSITIVE_Y;
			case 4: GL.TEXTURE_CUBE_MAP_NEGATIVE_Z;
			case 5: GL.TEXTURE_CUBE_MAP_POSITIVE_Z;
			default: throw new IllegalOperationError();
		}
	}
}
