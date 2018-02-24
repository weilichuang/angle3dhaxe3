package angle3d.material;
 
/**
 * <code>StencilOperation</code> specifies the stencil operation to use
 * in a certain scenario
 */
@:enum abstract StencilOperation(Int) {
	/**
	 * Keep the current value.
	 */
	var Keep = 0;
	/**
	 * Set the value to 0
	 */
	var Zero = 1;
	/**
	 * Replace the value in the stencil buffer with the reference value.
	 */
	var Replace = 2;
	/**
	 * Increment the value in the stencil buffer, clamp once reaching
	 * the maximum value.
	 */
	var Increment = 3;
	/**
	 * Increment the value in the stencil buffer and wrap to 0 when
	 * reaching the maximum value.
	 */
	var IncrementWrap = 4;
	/**
	 * Decrement the value in the stencil buffer and clamp once reaching 0.
	 */
	var Decrement = 5;
	/**
	 * Decrement the value in the stencil buffer and wrap to the maximum
	 * value when reaching 0.
	 */
	var DecrementWrap = 6;
	/**
	 * Does a bitwise invert of the value in the stencil buffer.
	 */
	var Invert = 7;
}