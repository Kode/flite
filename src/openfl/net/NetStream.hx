package openfl.net;

import haxe.Timer;
import openfl.events.EventDispatcher;
import openfl.events.NetStatusEvent;
import openfl.media.SoundTransform;
import js.html.VideoElement;
import js.Browser;

class NetStream extends EventDispatcher {
	public var audioCodec(default, null):Int;
	public var bufferLength(default, null):Float;
	public var bufferTime:Float;
	public var bytesLoaded(default, null):Int;
	public var bytesTotal(default, null):Int;
	public var checkPolicyFile:Bool;
	public var client:Dynamic;
	public var currentFPS(default, null):Float;
	public var decodedFrames(default, null):Int;
	public var liveDelay(default, null):Float;
	public var objectEncoding(default, null):Int;
	public var soundTransform:SoundTransform;
	public var speed(get, set):Float;
	public var time(default, null):Float;
	public var videoCode(default, null):Int;

	private var __connection:NetConnection;
	private var __timer:Timer;
	private var __video(default, null):VideoElement;

	public function new(connection:NetConnection, peerID:String = null):Void {
		super();

		__connection = connection;

		__video = Browser.document.createVideoElement();

		__video.setAttribute("playsinline", "");
		__video.setAttribute("webkit-playsinline", "");

		__video.addEventListener("error", video_onError, false);
		__video.addEventListener("waiting", video_onWaiting, false);
		__video.addEventListener("ended", video_onEnd, false);
		__video.addEventListener("pause", video_onPause, false);
		__video.addEventListener("seeking", video_onSeeking, false);
		__video.addEventListener("playing", video_onPlaying, false);
		__video.addEventListener("timeupdate", video_onTimeUpdate, false);
		__video.addEventListener("loadstart", video_onLoadStart, false);
		__video.addEventListener("stalled", video_onStalled, false);
		__video.addEventListener("durationchanged", video_onDurationChanged, false);
		__video.addEventListener("canplay", video_onCanPlay, false);
		__video.addEventListener("canplaythrough", video_onCanPlayThrough, false);
		__video.addEventListener("loadedmetadata", video_onLoadMetaData, false);
	}

	public function close():Void {
		__video.pause();
		__video.src = "";
		time = 0;
	}

	public function pause():Void {
		__video.pause();
	}

	public function play(url:String, ?_, ?_, ?_, ?_, ?_):Void {
		__video.src = url;
		__video.play();
	}

	public function requestVideoStatus():Void {
		if (__timer == null) {
			__timer = new Timer(1);
		}

		__timer.run = function() {
			if (__video.paused) {
				__playStatus("NetStream.Play.pause");
			} else {
				__playStatus("NetStream.Play.playing");
			}

			__timer.stop();
		};
	}

	public function resume():Void {
		__video.play();
	}

	public function seek(time:Float):Void {
		if (time < 0) {
			time = 0;
		} else if (time > __video.duration) {
			time = __video.duration;
		}

		__video.currentTime = time;
	}

	public function togglePause():Void {
		if (__video.paused) {
			__video.play();
		} else {
			__video.pause();
		}
	}

	private function __playStatus(code:String):Void {
		if (client != null) {
			try {
				client.onPlayStatus({
					code: code,
					duration: __video.duration,
					position: __video.currentTime,
					speed: __video.playbackRate,
					start: (cast __video).startTime
				});
			} catch (e:Dynamic) {}
		}
	}

	// Event Handlers

	private function video_onCanPlay(event:Dynamic):Void {
		__playStatus("NetStream.Play.canplay");
	}

	private function video_onCanPlayThrough(event:Dynamic):Void {
		__playStatus("NetStream.Play.canplaythrough");
	}

	private function video_onDurationChanged(event:Dynamic):Void {
		__playStatus("NetStream.Play.durationchanged");
	}

	private function video_onEnd(event:Dynamic):Void {
		__connection.dispatchEvent(new NetStatusEvent(NetStatusEvent.NET_STATUS, false, false, {code: "NetStream.Play.Stop"}));
		__playStatus("NetStream.Play.Complete");
	}

	private function video_onError(event:Dynamic):Void {
		__connection.dispatchEvent(new NetStatusEvent(NetStatusEvent.NET_STATUS, false, false, {code: "NetStream.Play.Stop"}));
		__playStatus("NetStream.Play.error");
	}

	private function video_onLoadMetaData(event:Dynamic):Void {
		if (client != null) {
			try {
				var handler = client.onMetaData;
				handler({
					width: __video.videoWidth,
					height: __video.videoHeight,
					duration: __video.duration
				});
			} catch (e:Dynamic) {}
		}
	}

	private function video_onLoadStart(event:Dynamic):Void {
		__playStatus("NetStream.Play.loadstart");
	}

	private function video_onPause(event:Dynamic):Void {
		__playStatus("NetStream.Play.pause");
	}

	private function video_onPlaying(event:Dynamic):Void {
		__connection.dispatchEvent(new NetStatusEvent(NetStatusEvent.NET_STATUS, false, false, {code: "NetStream.Play.Start"}));
		__playStatus("NetStream.Play.playing");
	}

	private function video_onSeeking(event:Dynamic):Void {
		__playStatus("NetStream.Play.seeking");
	}

	private function video_onStalled(event:Dynamic):Void {
		__playStatus("NetStream.Play.stalled");
	}

	private function video_onTimeUpdate(event:Dynamic):Void {
		time = __video.currentTime;
		__playStatus("NetStream.Play.timeupdate");
	}

	private function video_onWaiting(event:Dynamic):Void {
		__playStatus("NetStream.Play.waiting");
	}

	// Get & Set Methods

	private function get_speed():Float {
		return __video.playbackRate;
	}

	private function set_speed(value:Float):Float {
		return __video.playbackRate = value;
	}
}
