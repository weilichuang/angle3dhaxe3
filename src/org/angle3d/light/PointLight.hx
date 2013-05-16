package org.angle3d.light;

import org.angle3d.math.Vector3f;
import org.angle3d.bounding.BoundingVolume;
import org.angle3d.scene.Spatial;
import org.angle3d.utils.Assert;

/**
 * Represents a point light.
 * A point light emits light from a given position into all directions in space.
 * E.g a lamp or a bright effect. Point light positions are in world space.
 * <p>
 * In addition to a position, point lights also have a radius which
 * can be used to attenuate the influence of the light depending on the
 * distance between the light and the effected object.
 *
 */
class PointLight extends Light
{
	public var position(get, set):Vector3f;
	public var invRadius(get, null):Float;
	
	private var mPosition:Vector3f;
	private var mInvRadius:Float;

	public function new()
	{
		super(LightType.Point);

		mPosition = new Vector3f();
		mRadius = 0;
		mInvRadius = 0;
	}

	/**
	 * Returns the world space position of the light.
	 *
	 * @return the world space position of the light.
	 *
	 * @see PointLight#setPosition(org.angle3d.math.Vector3f)
	 */
	
	private function get_position():Vector3f
	{
		return mPosition;
	}

	/**
	 * set_the world space position of the light.
	 *
	 * @param position the world space position of the light.
	 */
	private function set_position(value:Vector3f):Vector3f
	{
		return mPosition.copyFrom(value);
	}

	override private function set_radius(value:Float):Float
	{
		Assert.assert(value >= 0, "Light radius cannot be negative");

		mRadius = value;
		if (value != 0)
		{
			mInvRadius = 1 / value;
		}
		else
		{
			mInvRadius = 0;
		}
		
		return mRadius;
	}

	override public function computeLastDistance(owner:Spatial):Void
	{
		if (owner.worldBound != null)
		{
			var bv:BoundingVolume = owner.worldBound;
			lastDistance = bv.distanceSquaredTo(mPosition);
		}
		else
		{
			lastDistance = owner.getWorldTranslation().distanceSquared(mPosition);
		}
	}

	/**
	 * for internal use only
	 * @return the inverse of the radius
	 */
	
	private function get_invRadius():Float
	{
		return mInvRadius;
	}
}

