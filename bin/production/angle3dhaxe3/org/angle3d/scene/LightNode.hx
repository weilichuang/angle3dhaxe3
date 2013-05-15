package org.angle3d.scene;

import org.angle3d.light.Light;
import org.angle3d.scene.control.LightControl;

/**
 * <code>LightNode</code> is used to link together a {@link Light} object
 * with a {@link Node} object.
 *
 * @author Tim8Dev
 */
class LightNode extends Node
{
	private var mLightControl:LightControl;

	public function new(name:String, light:Light)
	{
		super(name);
		mLightControl = new LightControl(light);
		addControl(mLightControl);
	}

	/**
	 * Enable or disable the <code>LightNode</code> functionality.
	 *
	 * @param enabled If false, the functionality of LightNode will
	 * be disabled.
	 */
	public function setEnabled(enabled:Bool):Void
	{
		mLightControl.enabled = enabled;
	}

	public function isEnabled():Bool
	{
		return mLightControl.enabled;
	}

	public function setLight(light:Light):Void
	{
		mLightControl.setLight(light);
	}
	
	public function getLight():Light
	{
		return mLightControl.getLight();
	}
	
	public function setControlDir(dir:String):Void
	{
		mLightControl.setControlDir(dir);
	}

	public function getControlDir():String
	{
		return mLightControl.getControlDir();
	}
}

