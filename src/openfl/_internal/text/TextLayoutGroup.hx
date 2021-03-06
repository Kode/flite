package openfl._internal.text;

import openfl.text.TextFormat;

// TODO: Need to measure all characters (including whitespace) but include a value for non-whitespace characters separately (for sake of alignment and wrapping)
class TextLayoutGroup {
	public var ascent:Float;
	public var descent:Float;
	public var endIndex:Int;
	public var format:TextFormat;
	public var height:Float;
	public var leading:Int;
	public var lineIndex:Int;
	public var offsetX:Float;
	public var offsetY:Float;
	public var positions:Array<Float>;
	public var startIndex:Int;
	public var width:Float;

	public function new(format:TextFormat, startIndex:Int, endIndex:Int) {
		this.format = format;
		this.startIndex = startIndex;
		this.endIndex = endIndex;
	}

	public inline function getAdvance(index:Int):Float {
		return positions[index];
	}
}
