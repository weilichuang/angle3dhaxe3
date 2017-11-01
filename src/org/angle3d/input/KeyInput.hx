package org.angle3d.input;

import flash.display.Stage;
import flash.events.KeyboardEvent;

import org.angle3d.input.event.KeyInputEvent;


/**
 * A specific API for interfacing with the keyboard.
 */
class KeyInput implements Input
{
	private var mStage:Stage;

	private var mListener:RawInputListener;

	public function new()
	{
		mStage = null;
		mListener = null;
	}

	/**
	* Initializes the native side to listen into events from the device.
	*/
	public function initialize(stage:Stage):Void
	{
		mStage = stage;

		if (mStage != null)
		{
			mStage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			mStage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		}
	}

	/**
	 * Queries the device for input. All events should be sent to the
	 * RawInputListener setInputListener.
	 *
	 * @see setInputListener(org.angle3d.input.RawInputListener)
	 */
	public function update():Void
	{

	}

	/**
	 * Ceases listening to events from the device.
	 */
	public function destroy():Void
	{
		if (mStage != null)
		{
			mStage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			mStage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			mStage = null;
		}

	}

	/**
	 * @return True if the device has been initialized and not destroyed.
	 * @see initialize()
	 * @see destroy()
	 */
	public function isInitialized():Bool
	{
		return mStage != null;
	}

	/**
	 * Sets the input listener to receive events from this device. The
	 * appropriate events should be dispatched through the callbacks
	 * in RawInputListener.
	 * @param listener
	 */
	public function setInputListener(listener:RawInputListener):Void
	{
		mListener = listener;
	}

	/**
	 * @return The current absolute time as milliseconds. This time is expected
	 * to be relative to the time given in InputEvents time property.
	 */
	public function getInputTime():Int
	{
		return Lib.getTimer();
	}
	
	private function onKeyDown(e:KeyboardEvent):Void
	{
		if (mListener != null)
		{
			var evt:KeyInputEvent = new KeyInputEvent(e.keyCode, String.fromCharCode(e.keyCode), true);
			evt.setTime(Lib.getTimer());
			mListener.onKeyEvent(evt);
		}
	}

	private function onKeyUp(e:KeyboardEvent):Void
	{
		if (mListener != null)
		{
			var evt:KeyInputEvent = new KeyInputEvent(e.keyCode, String.fromCharCode(e.keyCode), false);
			evt.setTime(Lib.getTimer());
			mListener.onKeyEvent(evt);
		}
	}
}

