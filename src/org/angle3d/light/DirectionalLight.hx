package org.angle3d.light;

import org.angle3d.math.Vector3f;
import org.angle3d.scene.Spatial;

/**
 * DirectionalLight is a light coming from a certain direction in world space.
 * E.g sun or moon light.
 * <p>
 * Directional lights have no specific position in the scene, they always
 * come from their direction regardless of where an object is placed.
 */
class DirectionalLight extends Light
{
	/**
	 * the direction of the light.
	 * <p>
	 * Represents the vector direction the light is coming from.
	 * (1, 0, 0) would represent a directional light coming from the X axis.
	 *
	 */
	public var direction(get, set):Vector3f;
	
	private var mDirection:Vector3f;

	public function new(direction:Vector3f = null)
	{
		super();
		
		this.type = LightType.Directional;

		mDirection = new Vector3f(0, -1, 0);
		
		if (direction != null)
			mDirection.copyFrom(direction);
	}

	private function get_direction():Vector3f
	{
		return mDirection;
	}

	private function set_direction(dir:Vector3f):Vector3f
	{
		mDirection.copyFrom(dir);
		mDirection.normalizeLocal();
		return mDirection;
	}

	override public function computeLastDistance(owner:Spatial):Void
	{
		// directional lights are after ambient lights
        // but before all other lights.
        lastDistance = -1; 
	}
	
	override public function copyFrom(other:Light):Void
	{
		super.copyFrom(other);
		
		var otherLight:DirectionalLight = cast other;
		this.direction.copyFrom(otherLight.direction);
	}
	
	override public function clone():Light
	{
		var light:DirectionalLight = new DirectionalLight();
		light.copyFrom(this);
		return light;
	}
}

