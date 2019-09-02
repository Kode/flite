package openfl._internal.sound;

import openfl._internal.app.Event;

class AudioSource {
	public var onComplete = new Event<Void->Void>();
	public var buffer:AudioBuffer;
	public var currentTime(get, set):Int;
	public var gain(get, set):Float;
	public var length(get, set):Int;
	public var loops:Int;
	public var offset:Int;
	public var pan(get,set):Float;

	var _gain:Float;
	var _length:Int;
	var _position_x:Float; // pan
	var _position_z:Float; // pan
	var id:Int;
	var playing:Bool;
	var completed:Bool;

	public function new(buffer:AudioBuffer) {
		this.buffer = buffer;

		id = -1;
		offset = 0;
		loops = 0;
		_gain = 1;
		_position_x = _position_z = 0;
	}

	public function dispose():Void {}

	public function play():Void {
		if (playing || buffer == null) {
			return;
		}

		playing = true;
		completed = false;

		var time = get_currentTime();

		var cacheVolume = (cast buffer.src)._volume;
		(cast buffer.src)._volume = gain;

		id = buffer.src.play();

		(cast buffer.src)._volume = cacheVolume;
		// set_gain(parent.gain);

		set_pan(_position_x);

		buffer.src.on("end", howl_onEnd, id);

		set_currentTime(time);
	}

	public function pause():Void {
		playing = false;
		if (buffer != null)
			buffer.src.pause(id);
	}

	public function stop():Void {
		playing = false;
		if (buffer != null)
			buffer.src.stop(id);
	}

	function howl_onEnd() {
		playing = false;
		if (loops > 0) {
			loops--;
			stop();
			// set_currentTime(0);
			play();
		} else {
			buffer.src.stop(id);
			completed = true;
			onComplete.dispatch();
		}
	}

	function get_currentTime():Int {
		if (id == -1) {
			return 0;
		}

		if (completed) {
			return length;
		} else if (buffer != null) {
			var time = Std.int(buffer.src.seek(id) * 1000) - offset;
			if (time < 0)
				return 0;
			return time;
		}

		return 0;
	}

	function set_currentTime(value:Int):Int {
		if (buffer != null) {
			// if (playing) buffer.src.play (id);
			var pos = (value + offset) / 1000;
			if (pos < 0)
				pos = 0;
			buffer.src.seek(pos, id);
		}
		return value;
	}

	function get_gain():Float {
		return _gain;
	}

	function set_gain(value:Float):Float {
		// set howler volume only if we have an active id.
		// Passing -1 might create issues in future play()'s.
		if (buffer != null && id != -1) {
			buffer.src.volume(value, id);
		}
		return _gain = value;
	}

	function get_length():Int {
		if (_length != 0) {
			return _length;
		}

		if (buffer != null) {
			return Std.int(buffer.src.duration() * 1000);
		}

		return 0;
	}

	inline function set_length(value:Int):Int {
		return _length = value;
	}

	inline function get_pan():Float {
		return _position_x;
	}

	inline function set_pan(pan:Float):Float {
		_position_x = pan;
		_position_z = -1 * Math.sqrt(1 - Math.pow(pan, 2));
		// TODO: Use 3D audio plugin
		return pan;
	}
}
