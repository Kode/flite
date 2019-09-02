package openfl.display3D;

import js.lib.ArrayBufferView;
import js.lib.Float32Array;
import js.html.webgl.GL;
import js.html.webgl.Buffer as GLBuffer;
import openfl.utils.ByteArray;
import openfl.Vector;

@:access(openfl.display3D.Context3D)
class VertexBuffer3D {
	var __context:Context3D;
	var __id:GLBuffer;
	var __numVertices:Int;
	var __stride:Int;
	var __tempFloat32Array:Float32Array;
	var __usage:Int;
	var __vertexSize:Int;

	function new(context3D:Context3D, numVertices:Int, dataPerVertex:Int, bufferUsage:Context3DBufferUsage) {
		__context = context3D;
		__numVertices = numVertices;
		__vertexSize = dataPerVertex;
		__stride = dataPerVertex * 4;
		__usage = (bufferUsage == Context3DBufferUsage.DYNAMIC_DRAW) ? GL.DYNAMIC_DRAW : GL.STATIC_DRAW;
		__id = kha.SystemImpl.gl.createBuffer();
	}

	public function dispose():Void {
		var gl = kha.SystemImpl.gl;
		if (gl.isBuffer(__id)) { // prevent the warning when the id becomes invalid after context loss+restore
			gl.deleteBuffer(__id);
		}
	}

	public function uploadFromByteArray(data:ByteArray, byteArrayOffset:Int, startVertex:Int, numVertices:Int):Void {
		var offset = byteArrayOffset + startVertex * __stride;
		var length = numVertices * __vertexSize;
		uploadFromTypedArray(new Float32Array(data, offset, length));
	}

	public function uploadFromTypedArray(data:ArrayBufferView):Void {
		if (data == null)
			return;

		var gl = kha.SystemImpl.gl;
		gl.bindBuffer(GL.ARRAY_BUFFER, __id);
		gl.bufferData(GL.ARRAY_BUFFER, data, __usage);
	}

	public function uploadFromVector(data:Vector<Float>, startVertex:Int, numVertices:Int):Void {
		if (data == null)
			return;

		// TODO: Optimize more

		var start = startVertex * __vertexSize;
		var count = numVertices * __vertexSize;
		var length = start + count;

		var existingFloat32Array = __tempFloat32Array;
		if (__tempFloat32Array == null || __tempFloat32Array.length < count) {
			__tempFloat32Array = new Float32Array(count);
			if (existingFloat32Array != null) {
				__tempFloat32Array.set(existingFloat32Array);
			}
		}

		for (i in start...length) {
			__tempFloat32Array[i - start] = data[i];
		}

		uploadFromTypedArray(__tempFloat32Array);
	}
}
