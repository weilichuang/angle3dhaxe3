package org.angle3d.light;

import org.angle3d.math.Vector3f;
import org.angle3d.bounding.BoundingVolume;
import org.angle3d.math.FastMath;
import org.angle3d.scene.Spatial;
import org.angle3d.utils.Assert;

/**
 * Represents a spot light.
 * A spot light emmit a cone of light from a position and in a direction.
 * It can be used to fake torch lights or car's lights.
 * <p>
 * In addition to a position and a direction, spot lights also have a range which
 * can be used to attenuate the influence of the light depending on the
 * distance between the light and the effected object.
 * Also the angle of the cone can be tweaked by changing the spot inner angle and the spot outer angle.
 * the spot inner angle determin the cone of light where light has full influence.
 * the spot outer angle determin the cone global cone of light of the spot light.
 * the light intensity slowly decrease between the inner cone and the outer cone.
 */
class SpotLight extends Light
{
	public var direction(get, set):Vector3f;
	public var position(get, set):Vector3f;
	public var spotRange(get, set):Float;
	public var invSpotRange(get, null):Float;
	public var innerAngle(get, set):Float;
	public var outerAngle(get, set):Float;
	public var packedAngleCos(get, null):Float;
	
	private var mPosition:Vector3f;
	private var mDirection:Vector3f;

	private var mInnerAngle:Float;
	private var mOuterAngle:Float;
	private var mSpotRange:Float;
	private var mInvSpotRange:Float;
	private var mPackedAngleCos:Float;

	public function new()
	{
		super(LightType.Spot);

		mPosition = new Vector3f();
		mDirection = new Vector3f(0, -1, 0);

		mInnerAngle = Math.PI / (4 * 8);
		mOuterAngle = Math.PI / (4 * 6);
		mSpotRange = 100;
		mInvSpotRange = 1 / 100;
		mPackedAngleCos = 0;
		
		computePackedCos();
	}

	private function computePackedCos():Void
	{
		var innerCos:Float = Math.cos(mInnerAngle);
		var outerCos:Float = Math.cos(mOuterAngle);
		mPackedAngleCos = Std.int(innerCos * 1000);
		
		 //due to approximations, very close angles can give the same cos
        //here we make sure outer cos is bellow inner cos.
        if (Std.int(mPackedAngleCos) == Std.int(outerCos * 1000))
		{
            outerCos -= 0.001;
        }
		mPackedAngleCos += outerCos;
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

	
	private function get_direction():Vector3f
	{
		return mDirection;
	}

	private function set_direction(direction:Vector3f):Vector3f
	{
		return mDirection.copyFrom(direction);
	}

	
	private function get_position():Vector3f
	{
		return mPosition;
	}

	private function set_position(position:Vector3f):Vector3f
	{
		return mPosition.copyFrom(position);
	}

	
	private function get_spotRange():Float
	{
		return mSpotRange;
	}

	/**
	 * set_the range of the light influence.
	 * <p>
	 * Setting a non-zero range indicates the light should use attenuation.
	 * If a pixel's distance to this light's position
	 * is greater than the light's range, then the pixel will not be
	 * effected by this light, if the distance is less than the range, then
	 * the magnitude of the influence is equal to distance / range.
	 *
	 * @param spotRange the range of the light influence.
	 *
	 * @throws IllegalArgumentException If spotRange is negative
	 */
	private function set_spotRange(value:Float):Float
	{
		Assert.assert(value >= 0, "SpotLight range cannot be negative");

		mSpotRange = value;
		if (value != 0)
		{
			mInvSpotRange = 1 / value;
		}
		else
		{
			mInvSpotRange = 0;
		}
		return mSpotRange;
	}

	/**
	 * for internal use only
	 * @return the inverse of the spot range
	 */
	
	private function get_invSpotRange():Float
	{
		return mInvSpotRange;
	}

	/**
	 * returns the spot inner angle
	 * @return the spot inner angle
	 */
	
	private function get_innerAngle():Float
	{
		return mInnerAngle;
	}

	private function set_innerAngle(value:Float):Float
	{
		mInnerAngle = value;
		computePackedCos();
		return mInnerAngle;
	}

	/**
	 * returns the spot outer angle
	 * @return the spot outer angle
	 */
	
	private function get_outerAngle():Float
	{
		return mOuterAngle;
	}

	/**
	 * Sets the outer angle of the cone of influence.
	 * This angle is the angle between the spot direction axis and the outer border of the cone of influence.
	 * this should be greater than the inner angle or the result will be unexpected.
	 * @param spotOuterAngle
	 */
	private function set_outerAngle(value:Float):Float
	{
		mOuterAngle = value;
		computePackedCos();
		return mOuterAngle;
	}

	/**
	 * for internal use only
	 * @return the cosines of the inner and outter angle packed in a float
	 */
	
	private function get_packedAngleCos():Float
	{
		return mPackedAngleCos;
	}
}

