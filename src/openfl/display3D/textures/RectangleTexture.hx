package openfl.display3D.textures;

import js.lib.ArrayBufferView;
import js.lib.Uint8Array;
import js.html.webgl.GL;
import openfl._internal.stage3D.SamplerState;
import openfl.display.BitmapData;
import openfl.utils.ByteArray;

@:access(openfl.display3D.Context3D)
@:final class RectangleTexture extends TextureBase {
	private function new(context:Context3D, width:Int, height:Int, format:String, optimizeForRenderToTexture:Bool) {
		super(context);

		__width = width;
		__height = height;
		// __format = format;
		__optimizeForRenderToTexture = optimizeForRenderToTexture;
		__textureTarget = GL.TEXTURE_2D;

		uploadFromTypedArray(null);
	}

	public function uploadFromBitmapData(source:BitmapData):Void {
		if (source == null)
			return;

		var image = TextureBase.__getImage(kha.SystemImpl.gl, source);
		if (image == null)
			return;

		uploadFromTypedArray(image.getData());
	}

	public function uploadFromByteArray(data:ByteArray, byteArrayOffset:UInt):Void {
		var data = if (byteArrayOffset == 0) @:privateAccess (data : ByteArrayData).b else new Uint8Array(data, byteArrayOffset);
		uploadFromTypedArray(data);
	}

	public function uploadFromTypedArray(data:ArrayBufferView):Void {
		// if (__format != Context3DTextureFormat.BGRA) {
		// throw new IllegalOperationError();
		// }

		var gl = kha.SystemImpl.gl;
		gl.bindTexture(__textureTarget, __textureData.glTexture);
		gl.texImage2D(__textureTarget, 0, __internalFormat, __width, __height, 0, __format, GL.UNSIGNED_BYTE, data);
		gl.bindTexture(__textureTarget, null);
	}

	override function __applySamplerState(gl:GL, state:SamplerState) {
		if (state.maxAniso != 0.0) {
			gl.texParameterf(GL.TEXTURE_2D, Context3D.TEXTURE_MAX_ANISOTROPY_EXT, state.maxAniso);
		}
		super.__applySamplerState(gl, state);
	}
}
