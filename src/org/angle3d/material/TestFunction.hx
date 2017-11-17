package org.angle3d.material;

/**
 * `TestFunction` specifies the testing function for stencil test
 * function and alpha test function.
 *
 * <p>The functions work similarly as described except that for stencil
 * test function, the reference value given in the stencil command is
 * the input value while the reference is the value already in the stencil
 * buffer.
 */
/**
 * Describes light rendering mode.
 */
@:enum abstract TestFunction(Int) {

	/**
	 * The test always fails
	 */
	var Never = 0;
	/**
	 * The test succeeds if the input value is equal to the reference value.
	 */
	var Equal = 1;
	/**
	 * The test succeeds if the input value is less than the reference value.
	 */
	var Less = 2;
	/**
	 * The test succeeds if the input value is less than or equal to
	 * the reference value.
	 */
	var LessOrEqual = 3;
	/**
	 * The test succeeds if the input value is greater than the reference value.
	 */
	var Greater = 4;
	/**
	 * The test succeeds if the input value is greater than or equal to
	 * the reference value.
	 */
	var GreaterOrEqual = 5;
	/**
	 * The test succeeds if the input value does not equal the
	 * reference value.
	 */
	var NotEqual = 6;
	/**
	 * The test always passes
	 */
	var Always = 7;
}