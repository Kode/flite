package openfl._internal.renderer.opengl.batcher;

import kha.arrays.Float32Array;
import kha.FastFloat;

class QuadTextureData {
	public var data(default, null):TextureData;

	/** Texture coordinates (0x0-1x1 for full texture, some region for atlas sub-textures) **/
	public var uvs(default, null):Float32Array;

	/** Is the texture with premultiplied alpha or not **/
	public var premultipliedAlpha(default, null):Bool;

	public static inline function createFullFrame(data:TextureData, pma:Bool):QuadTextureData {
		return new QuadTextureData(data, fullFrameUVs, pma);
	}

	public static inline function createRegion(data:TextureData, u0:Float, v0:Float, u1:Float, v1:Float, u2:Float, v2:Float, u3:Float, v3:Float, pma:Bool):QuadTextureData {
		return new QuadTextureData(data, createArray(
			u0, v0,
			u1, v1,
			u2, v2,
			u3, v3
		), pma);
	}

	static var fullFrameUVs = createArray(
		0, 0,
		1, 0,
		1, 1,
		0, 1
	);

	function new(data, uvs, premultipliedAlpha) {
		this.data = data;
		this.uvs = uvs;
		this.premultipliedAlpha = premultipliedAlpha;
	}

	static function createArray(u0:FastFloat, v0:FastFloat, u1:FastFloat, v1:FastFloat, u2:FastFloat, v2:FastFloat, u3:FastFloat, v3:FastFloat):Float32Array {
		var a = new Float32Array(8);
		a[0] = u0; a[1] = v0;
		a[2] = u1; a[3] = v1;
		a[4] = u2; a[5] = v2;
		a[6] = u3; a[7] = v3;
		return a;
	}
}
