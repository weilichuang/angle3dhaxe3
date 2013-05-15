package org.angle3d.input.event;


/**
 * Mouse movement event.
 * <p>
 * Movement events are only generated if the mouse is on-screen.
 *
 * @author Kirill Vainer
 */
class MouseMotionEvent extends InputEvent
{
	public var x:Float;
	public var y:Float;
	public var dx:Float;
	public var dy:Float;

	public function new(x:Float, y:Float, dx:Float, dy:Float)
	{
		super();
		this.x = x;
		this.y = y;
		this.dx = dx;
		this.dy = dy;
	}

	public function toString():String
	{
		return "MouseMotion(x=" + x + ", y=" + y + ", dx=" + dx + ", dy=" + dy + ")";
	}
}

