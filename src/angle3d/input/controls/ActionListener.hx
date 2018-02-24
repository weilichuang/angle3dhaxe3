package angle3d.input.controls;


/**
 * `ActionListener` is used to receive input events in "digital" style.
 * <p>
 * Generally all button inputs, such as keyboard, mouse button, and joystick button,
 * will be represented exactly. Analog inputs will be converted into digital.
 * <p>
 * When an action listener is registered to a natively digital input, such as a button,
 * the event will be invoked when the button is pressed, with `value`
 * set to `true`, and will be invoked again when the button is released,
 * with `value` set to `false`.
 *
 */
interface ActionListener extends InputListener
{
	/**
	 * Called when an input to which this listener is registered to is invoked.
	 *
	 * @param name The name of the mapping that was invoked
	 * @param isPressed True if the action is "pressed", false otherwise
	 * @param tpf The time per frame value.
	 */
	function onAction(name:String, isPressed:Bool, tpf:Float):Void;
}

