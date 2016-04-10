package org.angle3d.input;

import flash.display.Stage;
import flash.events.IEventDispatcher;

/**
 * Abstract interface for an input device.
 *
 * @see MouseInput
 * @see KeyInput
 * @see JoyInput
 */
interface Input
{

	/**
	 * Initializes the native side to listen into events from the device.
	 */
	function initialize(stage:Stage):Void;

	/**
	 * Queries the device for input. All events should be sent to the
	 * RawInputListener set_with setInputListener.
	 *
	 * @see setInputListener(org.angle3d.input.RawInputListener)
	 */
	function update():Void;

	/**
	 * Ceases listening to events from the device.
	 */
	function destroy():Void;

	/**
	 * @return True if the device has been initialized and not destroyed.
	 * @see initialize()
	 * @see destroy()
	 */
	function isInitialized():Bool;

	/**
	 * Sets the input listener to receive events from this device. The
	 * appropriate events should be dispatched through the callbacks
	 * in RawInputListener.
	 * @param listener
	 */
	function setInputListener(listener:RawInputListener):Void;

	/**
	 * @return The current absolute time as milliseconds. This time is expected
	 * to be relative to the time given in InputEvents time property.
	 */
	function getInputTime():Int;
}

