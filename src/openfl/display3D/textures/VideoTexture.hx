package openfl.display3D.textures;

import js.html.webgl.GL;
import haxe.Timer;
import openfl._internal.renderer.opengl.batcher.TextureData;
import openfl.events.Event;
import openfl.net.NetStream;

@:access(openfl.display3D.Context3D)
@:access(openfl.net.NetStream)
@:final class VideoTexture extends TextureBase {
	public var videoHeight(default, null):Int;
	public var videoWidth(default, null):Int;

	private var __netStream:NetStream;

	private function new(context:Context3D) {
		super(context);
		__textureTarget = GL.TEXTURE_2D;
	}

	// public function attachCamera (theCamera:Camera):Void {}

	public function attachNetStream(netStream:NetStream):Void {
		__netStream = netStream;

		if (__netStream.__video.readyState == 4) {
			Timer.delay(function() {
				__textureReady();
			}, 0);
		} else {
			__netStream.__video.addEventListener("canplay", function(_) {
				__textureReady();
			}, false);
		}
	}

	private override function __getTexture():TextureData {
		if (!__netStream.__video.paused) {
			var gl = kha.SystemImpl.gl;
			gl.bindTexture(__textureTarget, __textureData.glTexture);
			gl.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, GL.RGBA, GL.UNSIGNED_BYTE, __netStream.__video);
		}
		return __textureData;
	}

	private function __textureReady():Void {
		videoWidth = __netStream.__video.videoWidth;
		videoHeight = __netStream.__video.videoHeight;

		dispatchEvent(new Event(Event.TEXTURE_READY));
	}
}
