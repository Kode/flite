package openfl._internal.app;

@:genericBuild(openfl._internal.app.EventMacro.build())
class Event<T> {}

class Event0 extends EventBase<() -> Void> {
	public function dispatch() {
		canceled = false;
		for (listener in __listeners) {
			listener();
			if (canceled) {
				break;
			}
		}
	}
}

class Event1<T> extends EventBase<T->Void> {
	public function dispatch(arg:T) {
		canceled = false;
		for (listener in __listeners) {
			listener(arg);
			if (canceled) {
				break;
			}
		}
	}
}

class Event2<T1, T2> extends EventBase<(T1, T2) -> Void> {
	public function dispatch(arg1:T1, arg2:T2) {
		canceled = false;
		for (listener in __listeners) {
			listener(arg1, arg2);
			if (canceled) {
				break;
			}
		}
	}
}

class Event3<T1, T2, T3> extends EventBase<(T1, T2, T3) -> Void> {
	public function dispatch(arg1:T1, arg2:T2, arg3:T3) {
		canceled = false;
		for (listener in __listeners) {
			listener(arg1, arg2, arg3);
			if (canceled) {
				break;
			}
		}
	}
}

private class EventBase<T> {
	public var canceled(default, null):Bool;

	var __listeners:Array<T>;

	public function new() {
		canceled = false;
		__listeners = new Array();
	}

	public function add(listener:T):Void {
		__listeners.push(listener);
	}

	public function cancel():Void {
		canceled = true;
	}

	public function has(listener:T):Bool {
		for (l in __listeners) {
			if (Reflect.compareMethods(l, listener))
				return true;
		}
		return false;
	}

	public function remove(listener:T):Void {
		var i = __listeners.length;
		while (--i >= 0) {
			if (Reflect.compareMethods(__listeners[i], listener)) {
				__listeners.splice(i, 1);
			}
		}
	}
}
