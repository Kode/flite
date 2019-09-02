// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================
package starling.filters;

/** A class that provides constant values for filter modes. The values are used in the
 *  FragmentFilter.mode property and define how a filter result is combined with the
 *  original object. */
class FragmentFilterMode {
	/** The filter is displayed below the filtered object. */
	public static inline var BELOW:String = "below";

	/** The filter is replacing the filtered object. */
	public static inline var REPLACE:String = "replace";

	/** The filter is displayed above the filtered object. */
	public static inline var ABOVE:String = "above";
}
