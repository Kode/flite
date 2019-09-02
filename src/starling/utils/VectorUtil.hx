// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================
package starling.utils;

import openfl.Vector;

/** A utility class containing methods related to the Vector class.
 *
 *  <p>Many methods of the Vector class cause the creation of temporary objects, which is
 *  problematic for any code that repeats very often. The utility methods in this class
 *  can be used to avoid that.</p> */
class VectorUtil {
	/** Inserts a value into the 'int'-Vector at the specified index. Supports negative
	 * indices (counting from the end); gaps will be filled up with zeroes. */
	public static function insertIntAt(vector:Vector<Int>, index:UInt, value:Int):Void {
		var i:UInt;
		var length:UInt = vector.length;

		if (index < 0)
			index += length + 1;
		if (index < 0)
			index = 0;

		i = index - 1;
		while (i >= length) {
			vector[i] = 0;
			--i;
		}

		i = length;
		while (i > index) {
			vector[i] = vector[i - 1];
			--i;
		}

		vector[index] = value;
	}

	/** Removes the value at the specified index from the 'int'-Vector. Pass a negative
	 * index to specify a position relative to the end of the vector. */
	public static function removeIntAt(vector:Vector<Int>, index:UInt):Int {
		var length:UInt = vector.length;

		if (index < 0)
			index += length;
		if (index < 0)
			index = 0;
		else if (index >= length)
			index = length - 1;

		var value:Int = vector[index];

		for (i in index + 1...length)
			vector[i - 1] = vector[i];

		vector.length = vector.length - 1;
		return value;
	}

	/** Inserts a value into the 'uint'-Vector at the specified index. Supports negative
	 * indices (counting from the end); gaps will be filled up with zeroes. */
	public static function insertUnsignedIntAt(vector:Vector<UInt>, index:UInt, value:UInt):Void {
		var i:UInt;
		var length:UInt = vector.length;

		if (index < 0)
			index += length + 1;
		if (index < 0)
			index = 0;

		i = index - 1;
		while (i >= length) {
			vector[i] = 0;
			--i;
		}

		i = length;
		while (i > index) {
			vector[i] = vector[i - 1];
			--i;
		}

		vector[index] = value;
	}

	/** Removes the value at the specified index from the 'int'-Vector. Pass a negative
	 * index to specify a position relative to the end of the vector. */
	public static function removeUnsignedIntAt(vector:Vector<UInt>, index:UInt):UInt {
		var length:UInt = vector.length;

		if (index < 0)
			index += length;
		if (index < 0)
			index = 0;
		else if (index >= length)
			index = length - 1;

		var value:UInt = vector[index];

		for (i in index + 1...length)
			vector[i - 1] = vector[i];

		vector.length = length - 1;
		return value;
	}

	/** Inserts a value into the 'Number'-Vector at the specified index. Supports negative
	 * indices (counting from the end); gaps will be filled up with <code>NaN</code> values. */
	public static function insertNumberAt(vector:Vector<Float>, index:UInt, value:Float):Void {
		var i:UInt;
		var length:UInt = vector.length;

		if (index < 0)
			index += length + 1;
		if (index < 0)
			index = 0;

		i = index - 1;
		while (i >= length) {
			vector[i] = Math.NaN;
			--i;
		}

		i = length;
		while (i > index) {
			vector[i] = vector[i - 1];
			--i;
		}

		vector[index] = value;
	}

	/** Removes the value at the specified index from the 'Number'-Vector. Pass a negative
	 * index to specify a position relative to the end of the vector. */
	public static function removeNumberAt(vector:Vector<Float>, index:UInt):Float {
		var length:UInt = vector.length;

		if (index < 0)
			index += length;
		if (index < 0)
			index = 0;
		else if (index >= length)
			index = length - 1;

		var value:Float = vector[index];

		for (i in index + 1...length)
			vector[i - 1] = vector[i];

		vector.length = length - 1;
		return value;
	}
}
