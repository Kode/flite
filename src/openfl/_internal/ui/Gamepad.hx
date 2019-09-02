package openfl._internal.ui;

import openfl._internal.app.Event;

class Gamepad {
	public static final devices = new Map<Int, Gamepad>();
	public static final onConnect = new Event<Gamepad->Void>();

	public var connected(default, null):Bool;
	public var guid(get, never):String;
	public var id(default, null):Int;
	public var name(get, never):String;
	public var onAxisMove = new Event<GamepadAxis->Float->Void>();
	public var onButtonDown = new Event<GamepadButton->Void>();
	public var onButtonUp = new Event<GamepadButton->Void>();
	public var onDisconnect = new Event<Void->Void>();

	public function new(id:Int) {
		this.id = id;
		connected = true;
	}

	public static function __connect(id:Int):Void {
		if (!devices.exists(id)) {
			var gamepad = new Gamepad(id);
			devices.set(id, gamepad);
			onConnect.dispatch(gamepad);
		}
	}

	public static function __disconnect(id:Int):Void {
		var gamepad = devices.get(id);
		if (gamepad != null)
			gamepad.connected = false;
		devices.remove(id);
		if (gamepad != null)
			gamepad.onDisconnect.dispatch();
	}

	inline function get_guid():String {
		var devices = __getDeviceData();
		return devices[this.id].id;
	}

	inline function get_name():String {
		var devices = __getDeviceData();
		return devices[this.id].id;
	}

	static function __getDeviceData():Array<js.html.Gamepad> {
		return
			(untyped navigator.getGamepads) ? untyped navigator.getGamepads() : (untyped navigator.webkitGetGamepads) ? untyped navigator.webkitGetGamepads() : null;
	}
}
