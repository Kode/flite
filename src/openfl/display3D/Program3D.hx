package openfl.display3D;

import js.lib.Float32Array;
import js.html.webgl.GL;
import js.html.webgl.Program as GLProgram;
import js.html.webgl.Shader as GLShader;
import js.html.webgl.UniformLocation as GLUniformLocation;
import openfl._internal.utils.Log;
import openfl._internal.stage3D.AGALConverter;
import openfl._internal.stage3D.SamplerState;
import openfl.errors.IllegalOperationError;
import openfl.errors.Error;
import openfl.utils.ByteArray;
import openfl.Vector;

@:access(openfl.display3D.Context3D)
@:final class Program3D {
	private var __uniforms:Array<Uniform>;
	private var __samplerUniforms:Array<Uniform>;
	private var __alphaSamplerUniforms:Array<Uniform>;
	private var __context:Context3D;
	private var __fragmentShaderID:GLShader;
	private var __fragmentSource:String;
	private var __fragmentUniformMap:UniformMap;
	private var __positionScale:Uniform;
	private var __programID:GLProgram;
	private var __samplerStates:Vector<SamplerState>;
	private var __samplerUsageMask:Int;
	private var __vertexShaderID:GLShader;
	private var __vertexSource:String;
	private var __vertexUniformMap:UniformMap;

	private function new(context3D:Context3D) {
		__context = context3D;

		__samplerUsageMask = 0;

		__uniforms = [];
		__samplerUniforms = [];
		__alphaSamplerUniforms = [];

		__samplerStates = new Vector<SamplerState>(Context3D.MAX_SAMPLERS);
	}

	public function dispose():Void {
		var gl = kha.SystemImpl.gl;
		if (__programID != null) {
			gl.deleteProgram(__programID);
			__programID = null;
		}

		if (__vertexShaderID != null) {
			gl.deleteShader(__vertexShaderID);
			__vertexShaderID = null;
		}

		if (__fragmentShaderID != null) {
			gl.deleteShader(__fragmentShaderID);
			__fragmentShaderID = null;
		}
	}

	public function upload(vertexProgram:ByteArray, fragmentProgram:ByteArray):Void {
		dispose();

		var gl = kha.SystemImpl.gl;

		var samplerStates = new Array<SamplerState>();
		var vertexShaderSource = AGALConverter.convertToGLSL(gl, vertexProgram, null);
		var fragmentShaderSource = AGALConverter.convertToGLSL(gl, fragmentProgram, samplerStates);

		if (Log.level == LogLevel.VERBOSE) {
			Log.info(vertexShaderSource);
			Log.info(fragmentShaderSource);
		}

		__vertexSource = vertexShaderSource;
		__fragmentSource = fragmentShaderSource;

		__vertexShaderID = gl.createShader(GL.VERTEX_SHADER);
		gl.shaderSource(__vertexShaderID, vertexShaderSource);
		gl.compileShader(__vertexShaderID);

		var shaderCompiled = gl.getShaderParameter(__vertexShaderID, GL.COMPILE_STATUS);
		if (shaderCompiled == 0) {
			var vertexInfoLog = gl.getShaderInfoLog(__vertexShaderID);
			if (vertexInfoLog != null && vertexInfoLog.length != 0) {
				trace('vertex: ${vertexInfoLog}');
			}
			throw new Error("Error compiling vertex shader: " + vertexInfoLog);
		}

		__fragmentShaderID = gl.createShader(GL.FRAGMENT_SHADER);
		gl.shaderSource(__fragmentShaderID, fragmentShaderSource);
		gl.compileShader(__fragmentShaderID);

		var fragmentCompiled = gl.getShaderParameter(__fragmentShaderID, GL.COMPILE_STATUS);
		if (fragmentCompiled == 0) {
			var fragmentInfoLog = gl.getShaderInfoLog(__fragmentShaderID);
			if (fragmentInfoLog != null && fragmentInfoLog.length != 0) {
				trace('fragment: ${fragmentInfoLog}');
			}
			throw new Error("Error compiling fragment shader: " + fragmentInfoLog);
		}

		__programID = gl.createProgram();
		gl.attachShader(__programID, __vertexShaderID);
		gl.attachShader(__programID, __fragmentShaderID);

		for (i in 0...Context3D.MAX_ATTRIBUTES) {
			var name = "va" + i;
			if (vertexShaderSource.indexOf(" " + name) != -1) {
				gl.bindAttribLocation(__programID, i, name);
			}
		}

		gl.linkProgram(__programID);

		var infoLog = gl.getProgramInfoLog(__programID);
		if (infoLog != null && StringTools.trim(infoLog) != "") {
			trace('program: ${infoLog}');
		}

		__buildUniformList();

		for (i in 0...samplerStates.length) {
			__samplerStates[i] = samplerStates[i];
		}
	}

	function __buildUniformList() {
		__uniforms = [];
		__samplerUniforms = [];
		__alphaSamplerUniforms = [];
		__samplerUsageMask = 0;

		var gl = kha.SystemImpl.gl;

		var numActive = gl.getProgramParameter(__programID, GL.ACTIVE_UNIFORMS);

		var vertexUniforms = new Array<Uniform>();
		var fragmentUniforms = new Array<Uniform>();

		for (i in 0...numActive) {
			var info = gl.getActiveUniform(__programID, i);
			var name = info.name;
			var size = info.size;
			var uniformType = info.type;

			var uniform = new Uniform(gl);
			uniform.name = name;
			uniform.size = size;
			uniform.type = uniformType;
			uniform.location = gl.getUniformLocation(__programID, uniform.name);

			var indexBracket = uniform.name.indexOf('[');
			if (indexBracket >= 0) {
				uniform.name = uniform.name.substring(0, indexBracket);
			}

			uniform.regCount = switch (uniformType) {
				case GL.FLOAT_MAT2: 2;
				case GL.FLOAT_MAT3: 3;
				case GL.FLOAT_MAT4: 4;
				case _: 1;
			};

			uniform.regCount *= uniform.size;

			__uniforms.push(uniform);

			if (uniform.name == "vcPositionScale") {
				__positionScale = uniform;
			} else if (StringTools.startsWith(uniform.name, "vc")) {
				uniform.regIndex = Std.parseInt(uniform.name.substring(2));
				uniform.regData = __context.__vertexConstants;
				vertexUniforms.push(uniform);
			} else if (StringTools.startsWith(uniform.name, "fc")) {
				uniform.regIndex = Std.parseInt(uniform.name.substring(2));
				uniform.regData = __context.__fragmentConstants;
				fragmentUniforms.push(uniform);
			} else if (StringTools.startsWith(uniform.name, "sampler") && !StringTools.endsWith(uniform.name, "_alpha")) {
				uniform.regIndex = Std.parseInt(uniform.name.substring(7));
				__samplerUniforms.push(uniform);
				for (reg in 0...uniform.regCount) {
					__samplerUsageMask |= (1 << (uniform.regIndex + reg));
				}
			} else if (StringTools.startsWith(uniform.name, "sampler") && StringTools.endsWith(uniform.name, "_alpha")) {
				var len = uniform.name.indexOf("_") - 7;
				uniform.regIndex = Std.parseInt(uniform.name.substring(7, 7 + len)) + 4;
				__alphaSamplerUniforms.push(uniform);
			}

			if (Log.level == LogLevel.VERBOSE) {
				trace('${i} name:${uniform.name} type:${uniform.type} size:${uniform.size} location:${uniform.location}');
			}
		}

		__vertexUniformMap = new UniformMap(vertexUniforms);
		__fragmentUniformMap = new UniformMap(fragmentUniforms);
	}

	private function __flush():Void {
		__vertexUniformMap.flush();
		__fragmentUniformMap.flush();
	}

	private function __getSamplerState(sampler:Int):SamplerState {
		return __samplerStates[sampler];
	}

	private function __markDirty(isVertex:Bool, index:Int, count:Int):Void {
		if (isVertex) {
			__vertexUniformMap.markDirty(index, count);
		} else {
			__fragmentUniformMap.markDirty(index, count);
		}
	}

	private function __setPositionScale(positionScale:Float32Array):Void {
		if (__positionScale != null) {
			kha.SystemImpl.gl.uniform4fv(__positionScale.location, positionScale);
		}
	}

	public function __setSamplerState(sampler:Int, state:SamplerState):Void {
		__samplerStates[sampler] = state;
	}

	function __use() {
		var gl = kha.SystemImpl.gl;

		gl.useProgram(__programID);

		__vertexUniformMap.markAllDirty();
		__fragmentUniformMap.markAllDirty();

		for (sampler in __samplerUniforms) {
			if (sampler.regCount == 1) {
				gl.uniform1i(sampler.location, sampler.regIndex);
			} else {
				throw new IllegalOperationError("!!! TODO: uniform location on webgl");
				/*
					TODO: Figure out +i on Webgl.
					// sampler array?
					for(i in 0...sampler.regCount) {
						gl.uniform1i(sampler.location + i, sampler.regIndex + i);
					}
				 */
			}
		}

		for (sampler in __alphaSamplerUniforms) {
			if (sampler.regCount == 1) {
				gl.uniform1i(sampler.location, sampler.regIndex);
			} else {
				throw new IllegalOperationError("!!! TODO: uniform location on webgl");
				/*
					TODO: Figure out +i on Webgl.
					// sampler array?
					for(i in 0...sampler.regCount) {
						gl.uniform1i(sampler.location + i, sampler.regIndex + i);
					}
				 */
			}
		}
	}
}

@:dox(hide) class Uniform {
	public var name:String;
	public var location:GLUniformLocation;
	public var type:Int;
	public var size:Int;
	public var regData:Float32Array;
	public var regIndex:Int;
	public var regCount:Int;
	public var isDirty:Bool;
	public var gl:GL;

	public function new(gl) {
		this.gl = gl;
		isDirty = true;
	}

	public function flush() {
		var index = regIndex * 4;
		switch (type) {
			case GL.FLOAT_MAT2:
				gl.uniformMatrix2fv(location, false, __getRegisters(index, size * 2 * 2));
			case GL.FLOAT_MAT3:
				gl.uniformMatrix3fv(location, false, __getRegisters(index, size * 3 * 3));
			case GL.FLOAT_MAT4:
				gl.uniformMatrix4fv(location, false, __getRegisters(index, size * 4 * 4));
			case GL.FLOAT_VEC2:
				gl.uniform2fv(location, __getRegisters(index, regCount * 2));
			case GL.FLOAT_VEC3:
				gl.uniform3fv(location, __getRegisters(index, regCount * 3));
			case GL.FLOAT_VEC4:
				gl.uniform4fv(location, __getRegisters(index, regCount * 4));
			default:
				gl.uniform4fv(location, __getRegisters(index, regCount * 4));
		}
	}

	inline function __getRegisters(index:Int, size:Int):Float32Array {
		return regData.subarray(index, index + size);
	}
}

@:dox(hide) class UniformMap {
	// TODO: it would be better to use a bitmask with a dirty bit per uniform, but not super important now
	private var __allDirty:Bool;
	private var __anyDirty:Bool;
	private var __registerLookup:Vector<Uniform>;
	private var __uniforms:Array<Uniform>;

	public function new(list:Array<Uniform>) {
		__uniforms = list;

		__uniforms.sort(function(a, b):Int {
			return Reflect.compare(a.regIndex, b.regIndex);
		});

		var total = 0;

		for (uniform in __uniforms) {
			if (uniform.regIndex + uniform.regCount > total) {
				total = uniform.regIndex + uniform.regCount;
			}
		}

		__registerLookup = new Vector<Uniform>(total);

		for (uniform in __uniforms) {
			for (i in 0...uniform.regCount) {
				__registerLookup[uniform.regIndex + i] = uniform;
			}
		}

		__anyDirty = __allDirty = true;
	}

	public function flush():Void {
		if (__anyDirty) {
			for (uniform in __uniforms) {
				if (__allDirty || uniform.isDirty) {
					uniform.flush();
					uniform.isDirty = false;
				}
			}

			__anyDirty = __allDirty = false;
		}
	}

	public function markAllDirty():Void {
		__allDirty = true;
		__anyDirty = true;
	}

	public function markDirty(start:Int, count:Int):Void {
		if (__allDirty) {
			return;
		}

		var end = start + count;

		if (end > __registerLookup.length) {
			end = __registerLookup.length;
		}

		var index = start;

		while (index < end) {
			var uniform = __registerLookup[index];

			if (uniform != null) {
				uniform.isDirty = true;
				__anyDirty = true;

				index = uniform.regIndex + uniform.regCount;
			} else {
				index++;
			}
		}
	}
}
