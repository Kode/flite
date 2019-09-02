package openfl.display;

import haxe.Timer;
import openfl._internal.renderer.opengl.GLRenderSession;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DProfile;
import openfl.display3D.Context3DRenderMode;
import openfl.events.ErrorEvent;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.Vector;

@:access(openfl.display3D.Context3D)
class Stage3D extends EventDispatcher {
	private static var __active:Bool;

	public var context3D(default, null):Context3D;
	public var visible:Bool;
	public var x(get, set):Float;
	public var y(get, set):Float;

	private var __contextRequested:Bool;
	private var __stage:Stage;
	private var __x:Float;
	private var __y:Float;

	private function new() {
		super();

		__x = 0;
		__y = 0;

		visible = true;
	}

	public function requestContext3D(context3DRenderMode:Context3DRenderMode = AUTO, profile:Context3DProfile = BASELINE):Void {
		__contextRequested = true;

		if (context3D != null) {
			Timer.delay(__dispatchCreate, 1);
		}
	}

	public function requestContext3DMatchingProfiles(profiles:Vector<Context3DProfile>):Void {
		requestContext3D();
	}

	private function __createContext(stage:Stage, renderSession:GLRenderSession):Void {
		__stage = stage;

		context3D = new Context3D(this, renderSession);
		__dispatchCreate();
	}

	private function __dispatchError():Void {
		__contextRequested = false;
		dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, "Context3D not available"));
	}

	private function __dispatchCreate():Void {
		if (__contextRequested) {
			__contextRequested = false;
			dispatchEvent(new Event(Event.CONTEXT3D_CREATE));
		}
	}

	private function __renderGL(stage:Stage, renderSession:GLRenderSession):Void {
		if (!visible)
			return;

		if (__contextRequested && context3D == null) {
			__createContext(stage, renderSession);
		}

		if (context3D != null) {
			// TODO: Better viewport fix
			context3D.__updateBackbufferViewport();

			// renderSession.blendModeManager.setBlendMode(null);

			// TODO: the commented check below is the result of the assumption that
			// shaderManager.currentShader being null means the we only used Context3D shaders
			// and we don't need to re-enable the Context3D program as it's already active.
			//
			// However this is now not the case, because our new BatchRenderer doesn't use
			// the shader manager as well: it sets shaderManager.currentShader to null and then
			// manually enables its own shader. So the check below becomes invalid.
			//
			// There are a number of more correct approaches to fix this, one of them being
			// to adapt BatchRenderer to use ShaderManager, but it's too intrusive at the moment,
			// so instead we just always enable the Stage3D program.

			// if (renderSession.shaderManager.currentShader != null) {
				// renderSession.shaderManager.setShader(null);
				if (context3D.__program != null) {
					@:privateAccess context3D.__program.__use();
				}
			// }
		}
	}

	private function __loseContext():Void {
		if (context3D != null) {
			__contextRequested = true; // because we want to dispatch `context3DCreate` on restore
		}

		context3D = null;
	}

	private function get_x():Float {
		return __x;
	}

	private function set_x(value:Float):Float {
		if (__x == value)
			return value;

		__x = value;

		if (context3D != null) {
			context3D.__updateBackbufferViewport();
		}

		return value;
	}

	private function get_y():Float {
		return __y;
	}

	private function set_y(value:Float):Float {
		if (__y == value)
			return value;

		__y = value;

		if (context3D != null) {
			context3D.__updateBackbufferViewport();
		}

		return value;
	}
}
