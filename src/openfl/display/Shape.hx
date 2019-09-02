package openfl.display;

@:access(openfl.display.Graphics)
class Shape extends DisplayObject {
	public var graphics(get, never):Graphics;

	public function new() {
		super();
	}

	private function get_graphics():Graphics {
		if (__graphics == null) {
			__graphics = new Graphics(this);
		}

		return __graphics;
	}
}
