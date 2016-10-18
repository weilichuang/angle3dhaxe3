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
class MouseButtonTrigger implements Trigger
{
	public var mouseButton:Int;
	
	private var _hashCode:Int;

	/**
	 * Create a new `MouseButtonTrigger` to receive mouse button events.
	 *
	 * @param mouseButton Mouse button index. See BUTTON_*** constants in
	 * `MouseInput`.
	 */
	public function new(mouseButton:Int)
	{
		Assert.assert(mouseButton >= 0, "mouseButton > 0");
		this.mouseButton = mouseButton;
		
		_hashCode = mouseButtonHash(mouseButton);
	}

	public function getName():String
	{
		return "Mouse Button " + mouseButton;
	}

	public static inline function mouseButtonHash(mouseButton:Int):Int
	{
		Assert.assert(mouseButton >= 0 && mouseButton <= 2, "keycode must be between 0 and 2");
		return 256 | (mouseButton & 0xff);
	}

	public function triggerHashCode():Int
	{
		return _hashCode;
	}
}

