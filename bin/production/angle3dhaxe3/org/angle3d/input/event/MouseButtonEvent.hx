package org.angle3d.input.event;


/**
 * Mouse button press/release event.
 *
 * @author Kirill Vainer
 */
class MouseButtonEvent extends InputEvent
{
	public var x:Float;
	public var y:Float;
	public var pressed:Bool;

	public function new(pressed:Bool, x:Float, y:Float)
	{
		super();

		this.pressed = pressed;
		this.x = x;
		this.y = y;
	}

	/**
	 * Returns true if the mouse button was released, false if it was pressed.
	 *
	 * @return true if the mouse button was released, false if it was pressed.
	 */
	public var released(get, null):Bool;
	private inline function get_released():Bool
	{
		return !pressed;
	}

	public function getButtonIndex():Int
	{
		return 0;
	}
}

