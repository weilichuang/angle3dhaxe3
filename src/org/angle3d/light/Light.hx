package org.angle3d.light;

import org.angle3d.math.Color;
import org.angle3d.scene.Spatial;
import org.angle3d.utils.Cloneable;

/**
 * Abstract class for representing a light source.
 * <p>
 * All light source types have a color.
 */

class Light implements Cloneable
{
	public var type(default, null):LightType;
	
	public var name:String;

	/**
     * If light is disabled, it will not have any 
     */
	public var enabled(get, set):Bool;
	public var intensity(get, set):Float;
	public var color(get, set):Color;
	
	/**
	 * Used in LightList for caching the distance
	 * to the owner spatial. Should be reset_after the sorting.
	 */
	public var lastDistance:Float;

	private var mColor:Color;
	
	/**
	 * If light is disabled, it will not take effect.
	 */
	private var mEnabled:Bool;


	public function new(type:LightType)
	{
		this.type = LightType.None;
		
		lastDistance = -1;

		mColor = new Color(1, 1, 1, 1);
		mEnabled = true;
	}

	/**
	 * Returns true if the light is enabled
	 *
	 * @return true if the light is enabled
	 *
	 * @see Light#setEnabled(Bool)
	 */
	
	private function get_enabled():Bool
	{
		return mEnabled;
	}

	private function set_enabled(value:Bool):Bool
	{
		return mEnabled = value;
	}

	/**
	 * Intensity of the light. Allowed values are between 0-1, from dark to light sequentially.
	 * @return Intensity of the light source.
	 *
	 */
	
	private function set_intensity(value:Float):Float
	{
		return mColor.a = value;
	}

	private function get_intensity():Float
	{
		return mColor.a;
	}

	/**
	 * Sets the light color.
	 *
	 * @param color the light color.
	 */
	
	private function set_color(color:Color):Color
	{
		mColor.copyFrom(color);
		return mColor;
	}

	private function get_color():Color
	{
		return mColor;
	}

	/**
	 * Used internally to compute the last distance value.
	 */
	public function computeLastDistance(owner:Spatial):Void
	{

	}
}

