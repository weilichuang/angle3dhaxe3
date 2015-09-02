package org.angle3d.light;

import org.angle3d.bounding.BoundingBox;
import org.angle3d.math.Color;
import org.angle3d.renderer.Camera;
import org.angle3d.scene.Spatial;
import org.angle3d.utils.Cloneable;
import org.angle3d.utils.TempVars;

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
	
	public var frustumCheckNeeded:Bool = true;
    public var isIntersectsFrustum:Bool  = false;
	
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

	public var owner:Spatial;

	public function new(type:LightType)
	{
		this.type = type;
		
		lastDistance = -1;

		mColor = new Color(1, 1, 1, 1);
		mEnabled = true;
	}
	
	/**
     * Determines if the light intersects with the given bounding box.
     * <p>
     * For non-local lights, such as {@link DirectionalLight directional lights},
     * {@link AmbientLight ambient lights}, or {@link PointLight point lights}
     * without influence radius, this method should always return true.
     * 
     * @param box The box to check intersection against.
     * @return True if the light intersects the box, false otherwise.
     */
    public function intersectsBox(box:BoundingBox):Bool
	{
		return true;
	}
    
    /**
     * Determines if the lgiht intersects with the given camera frustum.
     * 
     * For non-local lights, such as {@link DirectionalLight directional lights},
     * {@link AmbientLight ambient lights}, or {@link PointLight point lights}
     * without influence radius, this method should always return true.
     * 
     * @param camera The camera frustum to check intersection against.
     * @param vars TempVars in case it is needed.
     * @return True if the light intersects the frustum, false otherwise.
     */
    public function intersectsFrustum(camera:Camera):Bool
	{
		return true;
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

