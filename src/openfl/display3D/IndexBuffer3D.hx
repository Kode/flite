package openfl.display3D;

import js.html.webgl.Buffer as GLBuffer;
import js.lib.ArrayBufferView;
import js.lib.Int16Array;
import js.html.webgl.GL;
import openfl.utils.ByteArray;
import openfl.Vector;

@:access(openfl.display3D.Context3D)
final class IndexBuffer3D {
	var __context:Context3D;
	var __elementType:Int;
	var __id:GLBuffer;
	var __numIndices:Int;
	var __tempInt16Array:Int16Array;
	var __usage:Int;

	function new(context3D:Context3D, numIndices:Int, bufferUsage:Context3DBufferUsage) {
		__context = context3D;
		__numIndices = numIndices;
		__elementType = GL.UNSIGNED_SHORT;
		__usage = (bufferUsage == Context3DBufferUsage.DYNAMIC_DRAW) ? GL.DYNAMIC_DRAW : GL.STATIC_DRAW;
		__id = kha.SystemImpl.gl.createBuffer();
	}

	public function dispose():Void {
		var gl = kha.SystemImpl.gl;
		if (gl.isBuffer(__id)) { // prevent the warning when the id becomes invalid after context loss+restore
			gl.deleteBuffer(__id);
		}
	}

	public function uploadFromByteArray(data:ByteArray, byteArrayOffset:Int, startOffset:Int, count:Int):Void {
		var offset = byteArrayOffset + startOffset * 2;
		uploadFromTypedArray(new Int16Array(data, offset, count));
	}

	public function uploadFromTypedArray(data:ArrayBufferView):Void {
		if (data == null)
			return;

		var gl = kha.SystemImpl.gl;
		gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, __id);
		gl.bufferData(GL.ELEMENT_ARRAY_BUFFER, data, __usage);
	}

	public function uploadFromVector(data:Vector<UInt>, startOffset:Int, count:Int):Void {
		if (data == null)
			return;

		// TODO: Optimize more
		var length = startOffset + count;

		var existingInt16Array = __tempInt16Array;
		if (__tempInt16Array == null || __tempInt16Array.length < count) {
			__tempInt16Array = new Int16Array(count);
			if (existingInt16Array != null) {
				__tempInt16Array.set(existingInt16Array);
			}
		}

		for (i in startOffset...length) {
			__tempInt16Array[i - startOffset] = data[i];
		}

		uploadFromTypedArray(__tempInt16Array);
	}
}
