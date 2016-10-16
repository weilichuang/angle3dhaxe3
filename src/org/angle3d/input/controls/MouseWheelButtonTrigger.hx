package org.angle3d.input.controls;

import org.angle3d.error.Assert;

/**
 * A `MouseButtonTrigger` is used as a mapping to receive events
 * from mouse buttons. It is generally expected for a mouse to have at least
 * a left and right mouse button, but some mice may have a lot more buttons
 * than that.
 *
 * 
 */
class MouseWheelButtonTrigger extends MouseButtonTrigger
{
	/**
	 * Create a new `MouseButtonTrigger` to receive mouse button events.
	 *
	 * @param mouseButton Mouse button index. See BUTTON_*** constants in
	 * {MouseInput}.
	 */
	public function new()
	{
		super(2);
	}

	override public function triggerHashCode():Int
	{
		return MouseButtonTrigger.mouseButtonHash(mouseButton);
	}
}

