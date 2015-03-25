package org.angle3d.input.event;


/**
 * An abstract input event.
 */
class InputEvent
{
	private var time:Float;

	private var consumed:Bool;

	public function new()
	{
		consumed = false;
	}

	/**
	 * The time when the event occurred. This is relative to
	 * {@link Input#getInputTimeNanos() }.
	 *
	 * @return time when the event occured
	 */
	public inline function getTime():Float
	{
		return time;
	}

	/**
	 * set_the time when the event occurred.
	 *
	 * @param time time when the event occurred.
	 */
	public inline function setTime(time:Int):Void
	{
		this.time = time;
	}

	/**
	 * Returns true if the input event has been consumed, meaning it is no longer valid
	 * and should not be forwarded to input listeners.
	 *
	 * @return true if the input event has been consumed
	 */
	public function isConsumed():Bool
	{
		return consumed;
	}

	/**
	 * Call to mark this input event as consumed, meaning it is no longer valid
	 * and should not be forwarded to input listeners.
	 */
	public function setConsumed():Void
	{
		this.consumed = true;
	}
}

