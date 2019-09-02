// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================
// Most of the color transformation math was taken from the excellent ColorMatrix class by
// Mario Klingemann: http://www.quasimondo.com/archives/000565.php -- THANKS!!!
package starling.filters;

import flash.errors.ArgumentError;
import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;
import flash.display3D.Program3D;
import openfl.Vector;
import starling.core.Starling;
import starling.textures.Texture;
import starling.utils.Color;

/** The ColorMatrixFilter class lets you apply a 4x5 matrix transformation on the RGBA color 
 *  and alpha values of every pixel in the input image to produce a result with a new set
 *  of RGBA color and alpha values. It allows saturation changes, hue rotation,
 *  luminance to alpha, and various other effects.
 *
 *  <p>The class contains several convenience methods for frequently used color
 *  adjustments. All those methods change the current matrix, which means you can easily
 *  combine them in one filter:</p>
 *
 *  <listing>
 *  // create an inverted filter with 50% saturation and 180° hue rotation
 *  var filter:ColorMatrixFilter = new ColorMatrixFilter();
 *  filter.invert();
 *  filter.adjustSaturation(-0.5);
 *  filter.adjustHue(1.0);</listing>
 *
 *  <p>If you want to gradually animate one of the predefined color adjustments, either reset
 *  the matrix after each step, or use an identical adjustment value for each step; the
 *  changes will add up.</p>
 */
class ColorMatrixFilter extends FragmentFilter {
	private var mShaderProgram:Program3D;
	private var mUserMatrix:Vector<Float>; // offset in range 0-255
	private var mShaderMatrix:Vector<Float>; // offset in range 0-1, changed order

	private static inline var PROGRAM_NAME:String = "CMF";
	private static var MIN_COLOR:Vector<Float> = Vector.ofArray([0, 0, 0, 0.0001]);
	private static var IDENTITY:Vector<Float> = Vector.ofArray([1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0.]);
	private static inline var LUMA_R:Float = 0.299;
	private static inline var LUMA_G:Float = 0.587;
	private static inline var LUMA_B:Float = 0.114;

	/** helper objects */
	private static var sTmpMatrix1:Vector<Float> = new Vector<Float>(20, true);

	private static var sTmpMatrix2:Vector<Float> = new Vector<Float>();

	/** Creates a new ColorMatrixFilter instance with the specified matrix. 
	 * @param matrix a vector of 20 items arranged as a 4x5 matrix.
	 */
	public function new(matrix:Vector<Float> = null) {
		super();
		mUserMatrix = new Vector<Float>();
		mShaderMatrix = new Vector<Float>();

		this.matrix = matrix;
	}

	/** @private */
	private override function createPrograms():Void {
		var target:Starling = Starling.current;

		if (target.hasProgram(PROGRAM_NAME)) {
			mShaderProgram = target.getProgram(PROGRAM_NAME);
		} else {
			// fc0-3: matrix
			// fc4:   offset
			// fc5:   minimal allowed color value

			var fragmentShader:String = "tex ft0, v0,  fs0 <2d, clamp, linear, mipnone>  \n"
				+ // read texture color
				"max ft0, ft0, fc5              \n"
				+ // avoid division through zero in next step
				"div ft0.xyz, ft0.xyz, ft0.www  \n"
				+ // restore original (non-PMA) RGB values
				"m44 ft0, ft0, fc0              \n"
				+ // multiply color with 4x4 matrix
				"add ft0, ft0, fc4              \n"
				+ // add offset
				"mul ft0.xyz, ft0.xyz, ft0.www  \n"
				+ // multiply with alpha again (PMA)
				"mov oc, ft0                    \n"; // copy to output

			mShaderProgram = target.registerProgramFromSource(PROGRAM_NAME, FragmentFilter.STD_VERTEX_SHADER, fragmentShader);
		}
	}

	/** @private */
	private override function activate(pass:Int, context:Context3D, texture:Texture):Void {
		context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, mShaderMatrix);
		context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 5, MIN_COLOR);
		context.setProgram(mShaderProgram);
	}

	// color manipulation

	/** Inverts the colors of the filtered objects. */
	public function invert():ColorMatrixFilter {
		return concatValues(-1, 0, 0, 0, 255, 0, -1, 0, 0, 255, 0, 0, -1, 0, 255, 0, 0, 0, 1, 0);
	}

	/** Changes the saturation. Typical values are in the range (-1, 1).
	 * Values above zero will raise, values below zero will reduce the saturation.
	 * '-1' will produce a grayscale image. */
	public function adjustSaturation(sat:Float):ColorMatrixFilter {
		sat += 1;

		var invSat:Float = 1 - sat;
		var invLumR:Float = invSat * LUMA_R;
		var invLumG:Float = invSat * LUMA_G;
		var invLumB:Float = invSat * LUMA_B;

		return concatValues((invLumR + sat), invLumG, invLumB, 0, 0, invLumR, (invLumG + sat), invLumB, 0, 0, invLumR, invLumG, (invLumB + sat), 0, 0, 0, 0,
			0, 1, 0);
	}

	/** Changes the contrast. Typical values are in the range (-1, 1).
	 * Values above zero will raise, values below zero will reduce the contrast. */
	public function adjustContrast(value:Float):ColorMatrixFilter {
		var s:Float = value + 1;
		var o:Float = 128 * (1 - s);

		return concatValues(s, 0, 0, 0, o, 0, s, 0, 0, o, 0, 0, s, 0, o, 0, 0, 0, 1, 0);
	}

	/** Changes the brightness. Typical values are in the range (-1, 1).
	 * Values above zero will make the image brighter, values below zero will make it darker. */
	public function adjustBrightness(value:Float):ColorMatrixFilter {
		value *= 255;

		return concatValues(1, 0, 0, 0, value, 0, 1, 0, 0, value, 0, 0, 1, 0, value, 0, 0, 0, 1, 0);
	}

	/** Changes the hue of the image. Typical values are in the range (-1, 1). */
	public function adjustHue(value:Float):ColorMatrixFilter {
		value *= Math.PI;

		var cos:Float = Math.cos(value);
		var sin:Float = Math.sin(value);

		return concatValues(((LUMA_R + (cos * (1 - LUMA_R))) + (sin * -(LUMA_R))), ((LUMA_G + (cos * -(LUMA_G))) + (sin * -(LUMA_G))),
			((LUMA_B + (cos * -(LUMA_B))) + (sin * (1 - LUMA_B))), 0, 0, ((LUMA_R + (cos * -(LUMA_R))) + (sin * 0.143)),
			((LUMA_G + (cos * (1 - LUMA_G))) + (sin * 0.14)), ((LUMA_B + (cos * -(LUMA_B))) + (sin * -0.283)), 0, 0,
			((LUMA_R + (cos * -(LUMA_R))) + (sin * -((1 - LUMA_R)))), ((LUMA_G + (cos * -(LUMA_G))) + (sin * LUMA_G)),
			((LUMA_B + (cos * (1 - LUMA_B))) + (sin * LUMA_B)), 0, 0, 0, 0, 0, 1, 0);
	}

	/** Tints the image in a certain color, analog to what can be done in Flash Pro.
	 * @param color the RGB color with which the image should be tinted.
	 * @param amount the intensity with which tinting should be applied. Range (0, 1). */
	public function tint(color:UInt, amount:Float = 1.0):ColorMatrixFilter {
		var r:Float = Color.getRed(color) / 255.0;
		var g:Float = Color.getGreen(color) / 255.0;
		var b:Float = Color.getBlue(color) / 255.0;
		var q:Float = 1 - amount;

		var rA:Float = amount * r;
		var gA:Float = amount * g;
		var bA:Float = amount * b;

		return concatValues(q
			+ rA * LUMA_R, rA * LUMA_G, rA * LUMA_B, 0, 0, gA * LUMA_R, q
			+ gA * LUMA_G, gA * LUMA_B, 0, 0, bA * LUMA_R, bA * LUMA_G, q
			+ bA * LUMA_B, 0, 0, 0, 0, 0, 1, 0);
	}

	// matrix manipulation

	/** Changes the filter matrix back to the identity matrix. */
	public function reset():ColorMatrixFilter {
		matrix = null;
		return this;
	}

	/** Concatenates the current matrix with another one. */
	public function concat(matrix:Vector<Float>):ColorMatrixFilter {
		var i:Int = 0;

		for (y in 0...4) {
			for (x in 0...5) {
				sTmpMatrix1[i + x] = matrix[i] * mUserMatrix[x] + matrix[i + 1] * mUserMatrix[x + 5] + matrix[i + 2] * mUserMatrix[x + 10]
					+ matrix[i + 3] * mUserMatrix[x + 15] + (x == 4 ? matrix[i + 4] : 0);
			}

			i += 5;
		}

		copyMatrix(sTmpMatrix1, mUserMatrix);
		updateShaderMatrix();
		return this;
	}

	/** Concatenates the current matrix with another one, passing its contents directly. */
	private function concatValues(m0:Float, m1:Float, m2:Float, m3:Float, m4:Float, m5:Float, m6:Float, m7:Float, m8:Float, m9:Float, m10:Float, m11:Float,
			m12:Float, m13:Float, m14:Float, m15:Float, m16:Float, m17:Float, m18:Float, m19:Float):ColorMatrixFilter {
		pushValues(sTmpMatrix2, m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15, m16, m17, m18, m19);

		concat(sTmpMatrix2);
		return this;
	}

	private function pushValues(vector:Vector<Float>, m0:Float, m1:Float, m2:Float, m3:Float, m4:Float, m5:Float, m6:Float, m7:Float, m8:Float, m9:Float,
			m10:Float, m11:Float, m12:Float, m13:Float, m14:Float, m15:Float, m16:Float, m17:Float, m18:Float, m19:Float):Void {
		// avoid GC from Vector.ofArray
		vector.length = 20;
		vector[0] = m0;
		vector[1] = m1;
		vector[2] = m2;
		vector[3] = m3;
		vector[4] = m4;
		vector[5] = m5;
		vector[6] = m6;
		vector[7] = m7;
		vector[8] = m8;
		vector[9] = m9;
		vector[10] = m10;
		vector[11] = m11;
		vector[12] = m12;
		vector[13] = m13;
		vector[14] = m14;
		vector[15] = m15;
		vector[16] = m16;
		vector[17] = m17;
		vector[18] = m18;
		vector[19] = m19;
	}

	private function copyMatrix(from:Vector<Float>, to:Vector<Float>):Void {
		for (i in 0...20)
			to[i] = from[i];
	}

	private function updateShaderMatrix():Void {
		// the shader needs the matrix components in a different order,
		// and it needs the offsets in the range 0-1.

		pushValues(mShaderMatrix, mUserMatrix[0], mUserMatrix[1], mUserMatrix[2], mUserMatrix[3], mUserMatrix[5], mUserMatrix[6], mUserMatrix[7],
			mUserMatrix[8], mUserMatrix[10], mUserMatrix[11], mUserMatrix[12], mUserMatrix[13], mUserMatrix[15], mUserMatrix[16], mUserMatrix[17],
			mUserMatrix[18], mUserMatrix[4] / 255.0, mUserMatrix[9] / 255.0, mUserMatrix[14] / 255.0, mUserMatrix[19] / 255.0);
	}

	// properties

	/** A vector of 20 items arranged as a 4x5 matrix. */
	public var matrix(get, set):Vector<Float>;

	private function get_matrix():Vector<Float> {
		return mUserMatrix;
	}

	private function set_matrix(value:Vector<Float>):Vector<Float> {
		if (value != null && value.length != 20)
			throw new ArgumentError("Invalid matrix length: must be 20");

		if (value == null) {
			mUserMatrix = IDENTITY.copy();
		} else {
			copyMatrix(value, mUserMatrix);
		}

		updateShaderMatrix();
		return value;
	}
}
