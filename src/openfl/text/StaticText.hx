package openfl.text;

import openfl.display.DisplayObject;
import openfl.display.Graphics;

@:access(openfl.display.Graphics)
class StaticText extends DisplayObject {
	public var text(default, null):String;

	private function new() {
		super();

		__graphics = new Graphics(this);
	}
}
