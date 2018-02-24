package angle3d.input;

import angle3d.input.event.KeyInputEvent;
import angle3d.input.event.MouseButtonEvent;
import angle3d.input.event.MouseMotionEvent;
import angle3d.input.event.MouseWheelEvent;

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
	 * The listener should set the `InputEvent.setConsumed` consumed flag}
	 * on any events that have been consumed either at this call or previous calls.
	 */
	function afterInput():Void;

	/**
	 * Invoked on mouse movement/motion events.
	 *
	 * @param evt
	 */
	function onMouseMotionEvent(evt:MouseMotionEvent):Void;

	/**
	 * Invoked on mouse wheel events.
	 *
	 * @param evt
	 */
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

