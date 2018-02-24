package angle3d.input.controls;

import angle3d.error.Assert;

/**
 * A `KeyTrigger` is used as a mapping to keyboard keys.
 *
 */
class KeyTrigger implements Trigger
{
	public var keyCode:Int;

	/**
	 * Create a new `KeyTrigger` for the given keycode.
	 *
	 * @param keyCode the code for the key.
	 */
	public function new(keyCode:Int)
	{
		this.keyCode = keyCode;
	}

	public function getName():String
	{
		return "KeyCode " + keyCode;
	}

	public static inline function keyHash(keyCode:Int):Int
	{
		Assert.assert(keyCode >= 0 && keyCode <= 255, "keycode must be between 0 and 255");

		return keyCode & 0xff;
	}

	public function triggerHashCode():Int
	{
		return keyHash(keyCode);
	}
}

