package org.angle3d.input.event;

/**
 * Mouse movement event.
 * <p>
 * Movement events are only generated if the mouse is on-screen.
 *
 * @author Kirill Vainer
 */
class MouseWheelEvent extends InputEvent
{
	public var wheel:Int;
	public var deltaWheel:Int;

	public function new(wheel:Int, deltaWheel:Int)
	{
		super();
		this.wheel = wheel;
		this.deltaWheel = deltaWheel;
	}

	public function toString():String
	{
		return "MouseWheel(wheel=" + wheel + ", deltaWheel=" + deltaWheel + ")";
	}

	public function getButtonIndex():Int
	{
		return 2;
	}
}

