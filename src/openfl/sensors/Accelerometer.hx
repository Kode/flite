package openfl.sensors;

import haxe.Timer;
import openfl.errors.ArgumentError;
import openfl.events.AccelerometerEvent;
import openfl.events.EventDispatcher;

class Accelerometer extends EventDispatcher {
	// TODO: implement this somehow?
	public static final isSupported = true;
	public final muted = false;

	static inline final defaultInterval = 34;
	static var initialized = false;
	static var currentX = 0.0;
	static var currentY = 1.0;
	static var currentZ = 0.0;

	var __interval:Int;
	var __timer:Timer;

	public function new() {
		super();
		if (!initialized) {
			initialized = true;
			kha.input.Sensor.get(Accelerometer).notify(__notify);
		}
		setRequestedUpdateInterval(defaultInterval);
	}

	override public function addEventListener(type:String, listener:Dynamic->Void, useCapture:Bool = false, priority:Int = 0, useWeakReference:Bool = false):Void {
		super.addEventListener(type, listener, useCapture, priority, useWeakReference);
		__update();
	}

	public function setRequestedUpdateInterval(interval:Int):Void {
		if (interval < 0) {
			throw new ArgumentError();
		} else if (interval == 0) {
			interval = defaultInterval;
		}

		__interval = interval;

		if (__timer != null) {
			__timer.stop();
			__timer = null;
		}

		if (isSupported && !muted) {
			__timer = new Timer(__interval);
			__timer.run = __update;
		}
	}

	function __update() {
		var event = new AccelerometerEvent(AccelerometerEvent.UPDATE);
		event.timestamp = Timer.stamp();
		event.accelerationX = currentX;
		event.accelerationY = currentY;
		event.accelerationZ = currentZ;
		dispatchEvent(event);
	}

	static function __notify(x:Float, y:Float, z:Float) {
		currentX = x;
		currentY = y;
		currentZ = z;
	}
}
