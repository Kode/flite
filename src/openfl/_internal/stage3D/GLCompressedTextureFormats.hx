package openfl._internal.stage3D;

import js.html.webgl.GL;
import openfl._internal.stage3D.atf.ATFGPUFormat;

class GLCompressedTextureFormats {
	private var __formatMap = new Map<ATFGPUFormat, Int>();
	private var __formatMapAlpha = new Map<ATFGPUFormat, Int>();

	public static var __instance:Null<GLCompressedTextureFormats>;

	public static inline function reset() {
		__instance = null;
	}

	public function new(gl:GL) {
		checkDXT(gl);
		checkETC1(gl);
		checkPVRTC(gl);
	}

	public function checkDXT(gl:GL):Void {
		#if (js && html5)
		var compressedExtension = gl.getExtension("WEBGL_compressed_texture_s3tc");
		#else
		var compressedExtension = gl.getExtension("EXT_texture_compression_s3tc");
		#end

		if (compressedExtension != null) {
			__formatMap[DXT] = compressedExtension.COMPRESSED_RGBA_S3TC_DXT1_EXT;
			__formatMapAlpha[DXT] = compressedExtension.COMPRESSED_RGBA_S3TC_DXT5_EXT;
		}
	}

	public function checkETC1(gl:GL):Void {
		#if (js && html5)
		var compressedExtension = gl.getExtension("WEBGL_compressed_texture_etc1");
		if (compressedExtension != null) {
			__formatMap[ETC1] = compressedExtension.COMPRESSED_RGB_ETC1_WEBGL;
		}
		#else
		var compressedExtension = gl.getExtension("OES_compressed_ETC1_RGB8_texture");
		if (compressedExtension != null) {
			__formatMap[ETC1] = compressedExtension.ETC1_RGB8_OES;
		}
		#end
	}

	public function checkPVRTC(gl:GL):Void {
		#if (js && html5)
		// WEBGL_compressed_texture_pvrtc is not available on iOS Safari
		var compressedExtension = gl.getExtension("WEBKIT_WEBGL_compressed_texture_pvrtc");
		#else
		var compressedExtension = gl.getExtension("IMG_texture_compression_pvrtc");
		#end

		if (compressedExtension != null) {
			__formatMap[PVRTC] = compressedExtension.COMPRESSED_RGB_PVRTC_4BPPV1_IMG;
			__formatMapAlpha[PVRTC] = compressedExtension.COMPRESSED_RGBA_PVRTC_4BPPV1_IMG;
		}
	}

	public function toTextureFormat(alpha:Bool, gpuFormat:ATFGPUFormat):Int {
		if (alpha)
			return __formatMap[gpuFormat];
		else
			return __formatMapAlpha[gpuFormat];
	}
}
