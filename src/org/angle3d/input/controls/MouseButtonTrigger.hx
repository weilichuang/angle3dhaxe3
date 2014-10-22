package org.angle3d.input.controls;

import de.polygonal.ds.error.Assert;

/**
 * A <code>MouseButtonTrigger</code> is used as a mapping to receive events
 * from mouse buttons. It is generally expected for a mouse to have at least
 * a left and right mouse button, but some mice may have a lot more buttons
 * than that.
 *
 * @author Kirill Vainer
 */
class MouseButtonTrigger implements Trigger
{
	public var mouseButton:Int;

	/**
	 * Create a new <code>MouseButtonTrigger</code> to receive mouse button events.
	 *
	 * @param mouseButton Mouse button index. See BUTTON_*** constants in
	 * {@link MouseInput}.
	 */
	public function new(mouseButton:Int)
	{
		Assert.assert(mouseButton >= 0, "mouseButton > 0");
		this.mouseButton = mouseButton;
	}

	public function getName():String
	{
		return "Mouse Button " + mouseButton;
	}

	public static function mouseButtonHash(mouseButton:Int):Int
	{
		Assert.assert(mouseButton >= 0 && mouseButton <= 2, "keycode must be between 0 and 2");
		return 256 | (mouseButton & 0xff);
	}

	public function triggerHashCode():Int
	{
		return mouseButtonHash(mouseButton);
	}
}

