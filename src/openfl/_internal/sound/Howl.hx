package openfl._internal.sound;

import haxe.Constraints.Function;

@:native("Howl")
extern class Howl {
	function new(options:HowlOptions);
	function duration(?id:Int):Int;
	function fade(from:Float, to:Float, len:Int, ?id:Int):Howl;
	function load():Howl;
	@:overload(function(id:Int):Bool {})
	@:overload(function(loop:Bool):Howl {})
	@:overload(function(loop:Bool, id:Int):Howl {})
	function loop():Bool;
	function mute(muted:Bool, ?id:Int):Howl;
	function off(event:String, fn:Function, ?id:Int):Howl;
	function on(event:String, fn:Function, ?id:Int):Howl;
	function once(event:String, fn:Function, ?id:Int):Howl;
	function pause(?id:Int):Howl;
	@:overload(function(id:Int):Int {})
	function play(?sprite:String):Int;
	function playing(?id:Int):Bool;
	@:overload(function(id:Int):Float {})
	@:overload(function(rate:Float):Howl {})
	@:overload(function(rate:Float, id:Int):Howl {})
	function rate():Float;
	function state():String;
	@:overload(function(id:Int):Float {})
	@:overload(function(seek:Float):Howl {})
	@:overload(function(seek:Float, id:Int):Howl {})
	function seek():Float;
	function stop(?id:Int):Howl;
	function unload():Void;
	@:overload(function(id:Int):Float {})
	@:overload(function(vol:Float):Howl {})
	@:overload(function(vol:Float, id:Int):Howl {})
	function volume():Float;
}

typedef HowlOptions = {
	src:Array<String>,
	?volume:Float,
	?html5:Bool,
	?loop:Bool,
	?preload:Bool,
	?autoplay:Bool,
	?mute:Bool,
	?sprite:Dynamic,
	?rate:Float,
	?pool:Float,
	?format:Array<String>,
	?onload:Function,
	?onloaderror:Function,
	?onplay:Function,
	?onend:Function,
	?onpause:Function,
	?onstop:Function,
	?onmute:Function,
	?onvolume:Function,
	?onrate:Function,
	?onseek:Function,
	?onfade:Function
}
