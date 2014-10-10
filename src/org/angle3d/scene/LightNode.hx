package org.angle3d.scene;

import org.angle3d.light.Light;
import org.angle3d.scene.control.LightControl;

/**
 * LightNode is used to link together a  Light object
 * with a Node object.
 *
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
		mLightControl.light = light;
	}
	
	public function getLight():Light
	{
		return mLightControl.light;
	}
	
	public function setControlDir(dir:String):Void
	{
		mLightControl.controlDir = dir;
	}

	public function getControlDir():String
	{
		return mLightControl.controlDir;
	}
}

