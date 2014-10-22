package org.angle3d.light;

import org.angle3d.bounding.BoundingBox;
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
	
	public function new()
	{
		super(LightType.Point);

		mPosition = new Vector3f();
		mRadius = 0;
		mInvRadius = 0;
	}
	
	override public function intersectsBox(box:BoundingBox, vars:TempVars):Bool
	{
		if (this.radius == 0)
		{
            return true;
        } 
		else
		{
            // Sphere v. box collision
            return FastMath.abs(box.center.x - position.x) < radius + box.xExtent
                && FastMath.abs(box.center.y - position.y) < radius + box.yExtent
                && FastMath.abs(box.center.z - position.z) < radius + box.zExtent;
        }
	}

    override public function intersectsFrustum(camera:Camera, vars:TempVars):Bool
	{
		if (this.radius == 0)
		{
            return true;
        } 
		else 
		{
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
	
	/**
	 * Returns the radius of the light influence. A radius of 0 means
	 * the light has no attenuation.
	 *
	 * @return the radius of the light
	 */
	
	private function get_radius():Float
	{
		return mRadius;
	}

	private function set_radius(value:Float):Float
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

