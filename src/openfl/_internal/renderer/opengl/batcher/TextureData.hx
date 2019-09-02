package openfl._internal.renderer.opengl.batcher;

import js.html.webgl.Texture;

class TextureData {
	/** Actual GL texture **/
	public final image:kha.Image;

	/** Batcher-specific data about this texture (so we don't have to allocate more storage and do lookups) **/
	public var textureUnitId = -1;

	public var enabledTick = 0;
	public var lastSmoothing = false;

	public var glTexture(get,never):Texture; // TODO: remove this
	inline function get_glTexture():Texture return (cast image : kha.WebGLImage).texture;

	public function new(image) {
		this.image = image;
	}

	public static function createImageFromGLTexture(texture:Texture):kha.Image {
		var i = new kha.WebGLImage(0, 0, RGBA32, false, NoDepthAndStencil, 0);
		i.texture = texture;
		return i;
	}
}
