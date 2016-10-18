package org.angle3d.input.controls;

import org.angle3d.input.MouseInput;
import org.angle3d.error.Assert;

/**
 * A `MouseAxisTrigger` is used as a mapping to mouse axis,
 * a mouse axis is movement along the X axis (left/right), Y axis (up/down)
 * and the mouse wheel (scroll up/down).
 *
 */
class MouseAxisTrigger implements Trigger
{
	public var mouseAxis:Int;
	public var negative:Bool;

	/**
	 * Create a new `MouseAxisTrigger`.
	 * <p>
	 * @param mouseAxis Mouse axis. See AXIS_*** constants in `MouseInput`
	 * @param negative True if listen to negative axis events, false if
	 * listen to positive axis events.
	 */
	public function new(mouseAxis:Int, negative:Bool)
	{
		Assert.assert(mouseAxis >= 0 && mouseAxis <= 2, "Mouse Axis must be between 0 and 2");

		this.mouseAxis = mouseAxis;
		this.negative = negative;
	}

	public function getName():String
	{
		var sign:String = negative ? "Negative" : "Positive";
		switch (mouseAxis)
		{
			case MouseInput.AXIS_X:
				return "Mouse X Axis " + sign;
			case MouseInput.AXIS_Y:
				return "Mouse Y Axis " + sign;
			case MouseInput.AXIS_WHEEL:
				return "Mouse Wheel " + sign;
		}
		return "";
	}

	public static inline function mouseAxisHash(mouseAxis:Int, negative:Bool):Int
	{
		Assert.assert(mouseAxis >= 0 && mouseAxis <= 2, "Mouse Axis must be between 0 and 2");

		return (negative ? 768 : 512) | (mouseAxis & 0xff);
	}

	public function triggerHashCode():Int
	{
		return mouseAxisHash(mouseAxis, negative);
	}
}

