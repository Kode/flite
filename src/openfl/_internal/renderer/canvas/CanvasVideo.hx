package openfl._internal.renderer.canvas;

import openfl.media.Video;

@:access(openfl.media.Video)
@:access(openfl.net.NetStream)
class CanvasVideo {
	public static function render(video:Video, renderSession:CanvasRenderSession):Void {
		if (!video.__renderable || video.__worldAlpha <= 0 || video.__stream == null)
			return;

		var context = renderSession.context;

		if (video.__stream.__video != null) {
			renderSession.blendModeManager.setBlendMode(video.__worldBlendMode);
			renderSession.maskManager.pushObject(video);

			context.globalAlpha = video.__worldAlpha;
			var transform = video.__worldTransform;
			var scrollRect = video.__scrollRect;
			var smoothing = video.smoothing;
			var pixelRatio = renderSession.pixelRatio;

			context.setTransform(transform.a * pixelRatio, transform.b, transform.c, transform.d * pixelRatio, transform.tx * pixelRatio,
				transform.ty * pixelRatio);

			if (!smoothing) {
				CanvasSmoothing.setEnabled(context, false);
			}

			if (scrollRect == null) {
				context.drawImage(video.__stream.__video, 0, 0, video.width, video.height);
			} else {
				context.drawImage(video.__stream.__video, scrollRect.x, scrollRect.y, scrollRect.width, scrollRect.height, scrollRect.x, scrollRect.y,
					scrollRect.width, scrollRect.height);
			}

			if (!smoothing) {
				CanvasSmoothing.setEnabled(context, true);
			}

			renderSession.maskManager.popObject(video);
		}
	}
}
