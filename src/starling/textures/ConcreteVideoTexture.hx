// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================
package starling.textures;

import flash.display3D.Context3DTextureFormat;
import flash.display3D.textures.TextureBase;
import flash.errors.ArgumentError;

/** A concrete texture that may only be used for a 'VideoTexture' base.
 *  For internal use only. */
class ConcreteVideoTexture extends ConcreteTexture {
	/** Creates a new VideoTexture. 'base' must be of type 'VideoTexture'. */
	public function new(base:TextureBase, scale:Float = 1) {
		// we must not reference the "VideoTexture" class directly
		// because it's only available in AIR.

		var format:Context3DTextureFormat = Context3DTextureFormat.BGRA;
		var width:Null<Int> = Reflect.getProperty(base, "videoWidth");
		var height:Null<Int> = Reflect.getProperty(base, "videoHeight");
		if (width == null)
			width = 0;
		if (height == null)
			height = 0;

		super(base, format, width, height, false, false, false, scale, false);

		#if flash
		var baseClass:Class<Dynamic> = Type.getClass(base);
		var className:String = Type.getClassName(baseClass);
		if (className != "flash.display3D.textures.VideoTexture")
			throw new ArgumentError("'base' must be VideoTexture");
		#end
	}

	/** The actual width of the video in pixels. */
	override private function get_nativeWidth():Float {
		return Reflect.getProperty(base, "videoWidth");
	}

	/** The actual height of the video in pixels. */
	override private function get_nativeHeight():Float {
		return Reflect.getProperty(base, "videoHeight");
	}

	/** inheritDoc */
	override private function get_width():Float {
		return nativeWidth / scale;
	}

	/** inheritDoc */
	override private function get_height():Float {
		return nativeHeight / scale;
	}
}
