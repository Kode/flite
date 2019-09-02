package openfl._internal.app;

@:allow(openfl._internal.app.Future)
abstract Promise<T>(Future<T>) from Future<T> {
	public var future(get, never):Future<T>;
	public var isComplete(get, never):Bool;
	public var isError(get, never):Bool;

	public inline function new() {
		this = new Future<T>();
	}

	public function complete(data:T):Promise<T> {
		if (!future.isError) {
			future.isComplete = true;
			future.value = data;

			if (future.__completeListeners != null) {
				for (listener in future.__completeListeners) {
					listener(data);
				}

				future.__completeListeners = null;
			}
		}

		return this;
	}

	public function completeWith(future:Future<T>):Promise<T> {
		future.onComplete(complete);
		future.onError(error);
		future.onProgress(progress);

		return this;
	}

	public function error(msg:Dynamic):Promise<T> {
		if (!future.isComplete) {
			future.isError = true;
			future.error = msg;

			if (future.__errorListeners != null) {
				for (listener in future.__errorListeners) {
					listener(msg);
				}

				future.__errorListeners = null;
			}
		}

		return this;
	}

	public function progress(progress:Int, total:Int):Promise<T> {
		if (!future.isError && !future.isComplete) {
			if (future.__progressListeners != null) {
				for (listener in future.__progressListeners) {
					listener(progress, total);
				}
			}
		}

		return this;
	}

	inline function get_future():Future<T> {
		return this;
	}

	inline function get_isComplete():Bool {
		return future.isComplete;
	}

	inline function get_isError():Bool {
		return future.isError;
	}
}
