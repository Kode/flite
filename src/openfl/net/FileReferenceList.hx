package openfl.net;

import openfl.events.EventDispatcher;

class FileReferenceList extends EventDispatcher {
	public var fileList(default, null):Array<FileReference>;

	public function new() {
		super();
	}

	public function browse(typeFilter:Array<FileFilter> = null):Bool {
		return false;
	}
}
