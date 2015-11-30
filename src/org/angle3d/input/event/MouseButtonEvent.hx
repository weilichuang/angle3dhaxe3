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
	public var buttonIndex:Int = 0;
	
	/**
	 * Returns true if the mouse button was released, false if it was pressed.
	 */
	public var released(get, null):Bool;

	public function new(pressed:Bool, x:Float, y:Float,buttonIndex:Int)
	{
		super();

		this.pressed = pressed;
		this.x = x;
		this.y = y;
		this.buttonIndex = buttonIndex;
	}

	private inline function get_released():Bool
	{
		return !pressed;
	}
	
	/**
	 * 0-left button,1-middle button,2-right button
	 * @return
	 */
	public inline function getButtonIndex():Int
	{
		return buttonIndex;
	}
}

