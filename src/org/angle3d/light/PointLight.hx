package org.angle3d.light;

import org.angle3d.bounding.BoundingBox;
import org.angle3d.bounding.BoundingSphere;
import org.angle3d.bounding.Intersection;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.bounding.BoundingVolume;
import org.angle3d.renderer.Camera;
import org.angle3d.scene.Spatial;
import de.polygonal.ds.error.Assert;
import org.angle3d.utils.TempVars;

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
	public var radius(get, set):Float;
	public var position(get, set):Vector3f;
	public var invRadius(get, null):Float;
	
	private var mPosition:Vector3f;
	
	private var mRadius:Float;
	private var mInvRadius:Float;
	
	public function new(position:Vector3f=null)
	{
		super();
		this.type = LightType.Point;
		mPosition = new Vector3f();
		mRadius = 0;
		mInvRadius = 0;
		
		if (position != null)
			mPosition.copyFrom(position);
	}
	
	override public function intersectsBox(box:BoundingBox):Bool
	{
		if (this.radius == 0)
		{
            return true;
        } 
		else
		{
            // Sphere v. box collision
			return Intersection.intersectBoxSphere(box, mPosition, mRadius);
        }
	}
	
	override public function intersectsSphere(sphere:BoundingSphere):Bool
	{
		if (this.radius == 0)
		{
            return true;
        }
		else
		{
            // Sphere v. sphere collision
            return Intersection.intersectSphereSphere(sphere, position, radius);
        }
	}

    override public function intersectsFrustum(camera:Camera):Bool
	{
		if (this.radius == 0)
		{
            return true;
        }
		

		var i:Int = 5;
		while (i >= 0)
		{
			if (camera.getWorldPlane(i).pseudoDistance(position) <= -radius)
			{
				return false;
			}
			i--;
		}
		return true;
	}

	/**
	 * Returns the world space position of the light.
	 *
	 * @return the world space position of the light.
	 *
	 * @see PointLight#setPosition(org.angle3d.math.Vector3f)
	 */
	
	private inline function get_position():Vector3f
	{
		return mPosition;
	}

	/**
	 * set_the world space position of the light.
	 *
	 * @param position the world space position of the light.
	 */
	private inline function set_position(value:Vector3f):Vector3f
	{
		return mPosition.copyFrom(value);
	}
	
	/**
	 * Returns the radius of the light influence. A radius of 0 means
	 * the light has no attenuation.
	 *
	 * @return the radius of the light
	 */
	
	private inline function get_radius():Float
	{
		return mRadius;
	}

	private inline function set_radius(value:Float):Float
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
	
	private inline function get_invRadius():Float
	{
		return mInvRadius;
	}
	
	override public function copyFrom(other:Light):Void
	{
		super.copyFrom(other);
		
		var otherPointLight:PointLight = cast other;
		this.radius = otherPointLight.radius;
		this.position.copyFrom(otherPointLight.position);
		this.invRadius = otherPointLight.invRadius;
	}
	
	override public function clone():Light
	{
		var light:PointLight = new PointLight();
		light.copyFrom(this);
		return light;
	}
}

