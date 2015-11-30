package org.angle3d.input.event;


/**
 * Keyboard key event.
 *
 * 
 */
class KeyInputEvent extends InputEvent
{
	public var keyCode:Int;
	public var keyChar:String;
	public var pressed:Bool;

	public function new(keyCode:Int, keyChar:String, pressed:Bool)
	{
		super();

		this.keyCode = keyCode;
		this.keyChar = keyChar;
		this.pressed = pressed;
	}

	/**
	 * Returns true if this event is a key release, false if it was a key press.
	 *
	 * @return true if this event is a key release, false if it was a key press.
	 */
	public var released(get, null):Bool;
	private inline function get_released():Bool
	{
		return !pressed;
	}

	public function toString():String
	{
		var str:String = "Key(CODE=" + keyCode;
		str = str + ", CHAR=" + keyChar;

		if (pressed)
		{
			return str + ", PRESSED)";
		}
		else
		{
			return str + ", RELEASED)";
		}
	}
}

