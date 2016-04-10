package org.angle3d.input;

import org.angle3d.input.event.KeyInputEvent;
import org.angle3d.input.event.MouseButtonEvent;
import org.angle3d.input.event.MouseMotionEvent;
import org.angle3d.input.event.MouseWheelEvent;

/**
 * An interface used for receiving raw input from devices.
 */
interface RawInputListener
{
	/**
	 * Called before a batch of input will be sent to this
	 * `RawInputListener`.
	 */
	function beforeInput():Void;

	/**
	 * Called after a batch of input was sent to this
	 * `RawInputListener`.
	 *
	 * The listener should set_the {InputEvent#setConsumed() consumed flag}
	 * on any events that have been consumed either at this call or previous calls.
	 */
	function afterInput():Void;

	/**
	 * Invoked on mouse movement/motion events.
	 *
	 * @param evt
	 */
	function onMouseMotionEvent(evt:MouseMotionEvent):Void;

	function onMouseWheelEvent(evt:MouseWheelEvent):Void;

	/**
	 * Invoked on mouse button events.
	 *
	 * @param evt
	 */
	function onMouseButtonEvent(evt:MouseButtonEvent):Void;

	/**
	 * Invoked on keyboard key press or release events.
	 *
	 * @param evt
	 */
	function onKeyEvent(evt:KeyInputEvent):Void;
}

