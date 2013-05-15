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
	/**
	 * Used in LightList for caching the distance
	 * to the owner spatial. Should be reset_after the sorting.
	 */
	public var lastDistance:Float;

	private var mType:LightType;

	private var mColor:Color;

	/**
	 * 所有灯光都应该有个范围，超过范围的灯光就不起作用
	 */
	private var mRadius:Float;

	/**
	 * If light is disabled, it will not take effect.
	 */
	private var mEnabled:Bool;


	public function new(type:LightType)
	{
		mType = type;

		lastDistance = -1;

		mColor = new Color(1, 1, 1, 1);
		mEnabled = true;
	}

	public var type(get, null):LightType;
	private function get_type():LightType
	{
		return mType;
	}

	/**
	 * Returns the radius of the light influence. A radius of 0 means
	 * the light has no attenuation.
	 *
	 * @return the radius of the light
	 */
	public var radius(get, set):Float;
	private function get_radius():Float
	{
		return mRadius;
	}

	/**
	 * set_the radius of the light influence.
	 * <p>
	 * Setting a non-zero radius indicates the light should use attenuation.
	 * If a pixel's distance to this light's position
	 * is greater than the light's radius, then the pixel will not be
	 * effected by this light, if the distance is less than the radius, then
	 * the magnitude of the influence is equal to distance / radius.
	 *
	 * @param radius the radius of the light influence.
	 *
	 */
	private function set_radius(value:Float):Float
	{
		return mRadius = value;
	}

	/**
	 * Returns true if the light is enabled
	 *
	 * @return true if the light is enabled
	 *
	 * @see Light#setEnabled(Bool)
	 */
	public var enabled(get, set):Bool;
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
	public var intensity(get, set):Float;
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
	public var color(get, set):Int;
	private function set_color(color:Int):Int
	{
		mColor.setRGB(color);
		return mColor.getColor();
	}

	private function get_color():Int
	{
		return mColor.getColor();
	}

	/**
	 * Used internally to compute the last distance value.
	 */
	public function computeLastDistance(owner:Spatial):Void
	{

	}
}

