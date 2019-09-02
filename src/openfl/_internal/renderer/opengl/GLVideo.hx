package openfl._internal.renderer.opengl;

import openfl.media.Video;

@:access(openfl.geom.ColorTransform)
@:access(openfl.media.Video)
@:access(openfl.net.NetStream)
class GLVideo {
	public static function render(video:Video, renderSession:GLRenderSession):Void {
		if (!video.__renderable || video.__worldAlpha <= 0 || video.__stream == null)
			return;

		if (video.__stream.__video != null) {
			// var renderer = renderSession.renderer;
			// var gl = kha.SystemImpl.gl;

			// renderSession.blendModeManager.setBlendMode(video.__worldBlendMode);
			// renderSession.maskManager.pushObject(video);

			// var shader = renderSession.shaderManager.defaultShader;
			// renderSession.shaderManager.setShader(shader);

			// // shader.data.uImage0.input = bitmap.__bitmapData;
			// // shader.data.uImage0.smoothing = renderSession.allowSmoothing && (bitmap.smoothing || renderSession.forceSmoothing);
			// shader.uMatrix.value = renderer.getMatrix(video.__renderTransform);

			// var useColorTransform = !video.__worldColorTransform.__isDefault();
			// shader.uColorTransform.value = useColorTransform;

			// renderSession.shaderManager.updateShader();

			// gl.bindTexture(GL.TEXTURE_2D, video.__getTexture(gl));

			// if (video.smoothing) {
			// 	gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
			// 	gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
			// } else {
			// 	gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.NEAREST);
			// 	gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.NEAREST);
			// }

			// gl.bindBuffer(GL.ARRAY_BUFFER, video.__getBuffer(gl, video.__worldAlpha, video.__worldColorTransform));

			// gl.vertexAttribPointer(shader.aPosition.index, 3, GL.FLOAT, false, 26 * Float32Array.BYTES_PER_ELEMENT, 0);
			// gl.vertexAttribPointer(shader.aTexCoord.index, 2, GL.FLOAT, false, 26 * Float32Array.BYTES_PER_ELEMENT, 3 * Float32Array.BYTES_PER_ELEMENT);
			// gl.vertexAttribPointer(shader.aAlpha.index, 1, GL.FLOAT, false, 26 * Float32Array.BYTES_PER_ELEMENT, 5 * Float32Array.BYTES_PER_ELEMENT);

			// if (true || useColorTransform) {
			// 	gl.vertexAttribPointer(shader.aColorMultipliers0.index, 4, GL.FLOAT, false, 26 * Float32Array.BYTES_PER_ELEMENT,
			// 		6 * Float32Array.BYTES_PER_ELEMENT);
			// 	gl.vertexAttribPointer(shader.aColorMultipliers1.index, 4, GL.FLOAT, false, 26 * Float32Array.BYTES_PER_ELEMENT,
			// 		10 * Float32Array.BYTES_PER_ELEMENT);
			// 	gl.vertexAttribPointer(shader.aColorMultipliers2.index, 4, GL.FLOAT, false, 26 * Float32Array.BYTES_PER_ELEMENT,
			// 		14 * Float32Array.BYTES_PER_ELEMENT);
			// 	gl.vertexAttribPointer(shader.aColorMultipliers3.index, 4, GL.FLOAT, false, 26 * Float32Array.BYTES_PER_ELEMENT,
			// 		18 * Float32Array.BYTES_PER_ELEMENT);
			// 	gl.vertexAttribPointer(shader.aColorOffsets.index, 4, GL.FLOAT, false, 26 * Float32Array.BYTES_PER_ELEMENT,
			// 		22 * Float32Array.BYTES_PER_ELEMENT);
			// }

			// gl.drawArrays(GL.TRIANGLE_STRIP, 0, 4);

			// renderSession.maskManager.popObject(video);
		}
	}

	public static function renderMask(video:Video, renderSession:GLRenderSession):Void {
		if (video.__stream == null)
			return;

		if (video.__stream.__video != null) {
			// var renderer = renderSession.renderer;
			// var gl = kha.SystemImpl.gl;

			// var shader = renderSession.maskManager.maskShader;
			// renderSession.shaderManager.setShader(shader);

			// shader.uImage0.input = bitmap.__bitmapData;
			// shader.uImage0.smoothing = renderSession.allowSmoothing && (bitmap.smoothing || renderSession.forceSmoothing);
			// shader.uMatrix.value = renderer.getMatrix(video.__renderTransform);

			// renderSession.shaderManager.updateShader();

			// gl.bindTexture(GL.TEXTURE_2D, video.__getTexture(gl));

			// if (video.smoothing) {

			// 	gl.texParameteri (GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
			// 	gl.texParameteri (GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);

			// } else {

			// 	gl.texParameteri (GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.NEAREST);
			// 	gl.texParameteri (GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.NEAREST);

			// }

			// gl.bindBuffer(GL.ARRAY_BUFFER, video.__getBuffer(gl, video.__worldAlpha, video.__worldColorTransform));

			// gl.vertexAttribPointer(shader.aPosition.index, 3, GL.FLOAT, false, 26 * Float32Array.BYTES_PER_ELEMENT, 0);
			// gl.vertexAttribPointer(shader.aTexCoord.index, 2, GL.FLOAT, false, 26 * Float32Array.BYTES_PER_ELEMENT, 3 * Float32Array.BYTES_PER_ELEMENT);

			// gl.drawArrays(GL.TRIANGLE_STRIP, 0, 4);
		}
	}
}
