package openfl._internal.utils;

#if !js @:generic #end
class ObjectPool<T> {
	final create:()->T;
	final clean:Null<T->Void>;
	var inactiveObjects:Int;
	var inactiveObject0:Null<T>;
	var inactiveObject1:Null<T>;
	final inactiveObjectList:List<T>;

	public function new(create:()->T, ?clean:T->Void) {
		this.create = create;
		this.clean = clean;
		inactiveObjects = 0;
		inactiveObjectList = new List<T>();
	}

	public function get():T {
		if (inactiveObjects > 0) {
			return getInactive();
		} else {
			return create();
		}
	}

	public function release(object:T) {
		if (clean != null) clean(object);
		addInactive(object);
	}

	inline function addInactive(object:T) {
		if (inactiveObject0 == null) {
			inactiveObject0 = object;
		} else if (inactiveObject1 == null) {
			inactiveObject1 = object;
		} else {
			inactiveObjectList.add(object);
		}
		inactiveObjects++;
	}

	inline function getInactive():T {
		var object;

		if (inactiveObject0 != null) {
			object = inactiveObject0;
			inactiveObject0 = null;
		} else if (inactiveObject1 != null) {
			object = inactiveObject1;
			inactiveObject1 = null;
		} else {
			object = inactiveObjectList.pop();
			if (inactiveObjectList.length > 0) {
				inactiveObject0 = inactiveObjectList.pop();
			}
			if (inactiveObjectList.length > 0) {
				inactiveObject1 = inactiveObjectList.pop();
			}
		}

		inactiveObjects--;

		return object;
	}
}
