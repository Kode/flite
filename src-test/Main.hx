import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.display.Bitmap;
import openfl.display.BitmapData;

class Main extends openfl.display.Sprite {
	function new() {
		super();

		addChild(new Bitmap(new BitmapData(100, 100, true, 0x88FF0000)));
		addChild(new Bitmap(new BitmapData(50, 50, true, 0x4400FF00)));

		// return;
		addEventListener(Event.ADDED_TO_STAGE, function(_) {
			var bmd = openfl.display.BitmapData.fromKhaImage(kha.Assets.images.battle_tank_0);

			var frames = [];
			var atlasData:{frames:Array<Array<Any>>} = haxe.Json.parse(kha.Assets.blobs.battle_tank_0_json.toString());
			atlasData.frames.sort((a, b) -> Reflect.compare(a[0], b[0]));
			for (frame in atlasData.frames) {
				var x = frame[1];
				var y = frame[2];
				var w = frame[3];
				var h = frame[4];
				var r = frame[5];
				var fx = 0, fy = 0;
				var fw = w, fh = h;
				if (!Std.is(r, Bool)) {
					fx = r;
					fy = frame[6];
					fw = frame[7];
					fh = frame[8];
					r = frame[9];
				}
				frames.push(new openfl.display.SubBitmapData(bmd, x, y, w, h, fx, fy, fw, fh, r));
			}

			var bmp = new openfl.display.Bitmap(frames[0]);
			// bmp.filters = [ new openfl.filters.DropShadowFilter() ];

			// stage.addEventListener(MouseEvent.MOUSE_MOVE, function(e:MouseEvent) {
			// 	trace(e.stageX);
			// 	trace(e.stageY);
			// });

			var sprite = new openfl.display.Sprite();
			// sprite.transform.colorTransform = new openfl.geom.ColorTransform(1, 0, 0);
			addChild(sprite);
			sprite.addEventListener(MouseEvent.ROLL_OVER, _ -> bmp.scaleX = 1.5);
			sprite.addEventListener(MouseEvent.ROLL_OUT, _ -> bmp.scaleX = 1);

			var shape = new openfl.display.Shape();
			shape.graphics.beginFill(0xFF0000, 0.75);
			shape.graphics.drawCircle(25, 25, 25);
			shape.graphics.endFill();
			shape.x = 30;
			shape.y = 15;
			shape.blendMode = ADD;
			// var bmd = new openfl.display.BitmapData(50, 50);
			// bmd.draw(shape);
			// var shape = new openfl.display.Bitmap(bmd);
			addChild(shape);

			var shape = new openfl.display.Shape();
			shape.graphics.beginFill(0xFF0000, 0.75);
			shape.graphics.drawCircle(25, 25, 25);
			shape.graphics.endFill();
			shape.x = 60;
			shape.y = 15;
			shape.blendMode = SUBTRACT;
			addChild(shape);

			sprite.addChild(bmp);
			sprite.addEventListener(MouseEvent.CLICK, function(_) {
				if (bmp.mask == null)
					bmp.mask = shape;
				else
					bmp.mask = null;
			});

			var frameId = 0;
			kha.Scheduler.addTimeTask(() -> {
				frameId++;
				if (frameId >= frames.length) frameId = 0;
				bmp.bitmapData = frames[frameId];
			}, 0, 1 / 10);

			var tf = new openfl.text.TextField();
			tf.type = INPUT;
			tf.text = "hello, world!";
			tf.border = true;
			tf.y = 150;
			addChild(tf);
		});
	}

	static function main() {
		kha.System.start({}, function(window) {
			kha.Assets.loadEverything(function() {
				openfl._internal.app.Application.start();
				openfl.Lib.current.addChild(new Main());
			});
		});
	}
}
