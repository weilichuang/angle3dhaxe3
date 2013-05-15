package org.angle3d.input.controls;


/**
 * A trigger represents a physical input, such as a keyboard key, a mouse
 * button, or joystick axis.
 */
interface Trigger
{
	/**
	 * @return A user friendly name for the trigger.
	 */
	function getName():String;

	/**
	 * Returns the hash code for the trigger.
	 *
	 * @return the hash code for the trigger.
	 */
	function triggerHashCode():Int;
}

