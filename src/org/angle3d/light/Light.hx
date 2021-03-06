package org.angle3d.light;

import org.angle3d.bounding.BoundingBox;
import org.angle3d.bounding.BoundingSphere;
import org.angle3d.math.Color;
import org.angle3d.renderer.Camera;
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
	 * the light type
	 */
	public var type(default, null):LightType;
	
	/**
     * Set to false in order to disable a light and have it filtered out from being included in rendering.
     */
	public var enabled(get, set):Bool;

	/**
	 * the color of the light.
	 */
	public var color(get, set):Color;
	
	/**
	 * the light name
	 */
	public var name:String;
	
	public var frustumCheckNeeded:Bool = true;
    public var isIntersectsFrustum:Bool  = false;
	
	/**
	 * Used in LightList for caching the distance
	 * to the owner spatial. Should be reset_after the sorting.
	 */
	public var lastDistance:Float;

	private var mColor:Color;
	private var mEnabled:Bool;

	public function new()
	{
		lastDistance = -1;

		mColor = new Color(1, 1, 1, 1);
		mEnabled = true;
	}
	
	/**
     * Determines if the light intersects with the given bounding box.
     * <p>
     * For non-local lights, such as `DirectionalLight`, `AmbientLight`, or `PointLight`
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
     * Determines if the light intersects with the given bounding sphere.
     * <p>
     * For non-local lights, such as `DirectionalLight`,`AmbientLight`, or `PointLight`
     * without influence radius, this method should always return true.
     * 
     * @param sphere The sphere to check intersection against.
     * 
     * @return True if the light intersects the sphere, false otherwise.
     */
    public function intersectsSphere(sphere:BoundingSphere):Bool
	{
		return true;
	}
    
    /**
     * Determines if the light intersects with the given camera frustum.
     * 
     * For non-local lights, such as `DirectionalLight`,`AmbientLight`, or `PointLight`
     * without influence radius, this method should always return true.
     * 
     * @param camera The camera frustum to check intersection against.

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
	 * @see `Light.setEnabled()`
	 */
	
	private inline function get_enabled():Bool
	{
		return mEnabled;
	}

	private function set_enabled(value:Bool):Bool
	{
		return mEnabled = value;
	}

	/**
	 * Sets the light color.
	 *
	 * @param color the light color.
	 */
	private inline function set_color(color:Color):Color
	{
		mColor.copyFrom(color);
		return mColor;
	}

	private inline function get_color():Color
	{
		return mColor;
	}

	/**
	 * Used internally to compute the last distance value.
	 */
	public function computeLastDistance(owner:Spatial):Void
	{

	}
	
	public function copyFrom(other:Light):Void
	{
		this.enabled = other.enabled;
		this.color.copyFrom(other.color);
	}
	
	public function clone():Light
	{
		var light:Light = new Light();
		light.copyFrom(this);
		return light;
	}
}

