package org.angle3d.light;

import de.polygonal.core.math.Mathematics;
import org.angle3d.bounding.BoundingBox;
import org.angle3d.math.Plane;
import org.angle3d.math.Vector3f;
import org.angle3d.bounding.BoundingVolume;
import org.angle3d.math.FastMath;
import org.angle3d.renderer.Camera;
import org.angle3d.scene.Spatial;
import de.polygonal.ds.error.Assert;
import org.angle3d.utils.TempVars;

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
	
	private var outerAngleCosSqr:Float;
	private var outerAngleSinSqr:Float;
    private var outerAngleSinRcp:Float;
	private var outerAngleSin:Float;
	private var outerAngleCos:Float;

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
		
		computeAngleParameters();
	}
	
	override public function intersectsBox(box:BoundingBox, vars:TempVars):Bool
	{
		var bCenter:Vector3f = box.center;
		if (mSpotRange > 0) 
		{
            // Check spot range first.
            // Sphere v. box collision
            if (FastMath.abs(bCenter.x - mPosition.x) >= mSpotRange + box.xExtent ||
                FastMath.abs(bCenter.y - mPosition.y) >= mSpotRange + box.yExtent ||
                FastMath.abs(bCenter.z - mPosition.z) >= mSpotRange + box.zExtent)
			{
                return false;
            }
        }
        
        var otherRadiusSquared:Float = box.xExtent * box.xExtent + box.yExtent * box.yExtent + box.zExtent * box.zExtent;
        var otherRadius:Float = Math.sqrt(otherRadiusSquared);
        
        // Check if sphere is within spot angle.
        // Cone v. sphere collision.
        var E:Vector3f = mDirection.scale(otherRadius * outerAngleSinRcp, vars.vect1);
        var U:Vector3f = mPosition.subtract(E, vars.vect2);
        var D:Vector3f = bCenter.subtract(U, vars.vect3);

        var dsqr:Float = D.dot(D);
        var e:Float = mDirection.dot(D);
        if (e > 0 && e * e >= dsqr * outerAngleCosSqr) 
		{
            D = bCenter.subtract(mPosition, vars.vect3);
            dsqr = D.dot(D);
            e = -mDirection.dot(D);

            if (e > 0 && e * e >= dsqr * outerAngleSinSqr)
			{
                return dsqr <= otherRadiusSquared;
            } 
			else
			{
                return true;
            }
        }
        
        return false;
	}

    override public function intersectsFrustum(camera:Camera, vars:TempVars):Bool
	{
		var farPoint:Vector3f = vars.vect1.copyFrom(position).addLocal(vars.vect2.copyFrom(direction).scaleLocal(spotRange));
		
		var i:Int = 5;
        while (i >= 0)
		{
            //check origin against the plane
            var plane:Plane = camera.getWorldPlane(i);
            var dot:Float = plane.pseudoDistance(position);
            if (dot < 0)
			{                
                // outside, check the far point against the plane   
                dot = plane.pseudoDistance(farPoint);
                if (dot < 0)
				{                   
                    // outside, check the projection of the far point along the normal of the plane to the base disc perimeter of the cone
                    //computing the radius of the base disc
                    var farRadius:Float = (spotRange / outerAngleCos) * outerAngleSin;                    
                    //computing the projection direction : perpendicular to the light direction and coplanar with the direction vector and the normal vector
                    var perpDirection:Vector3f = vars.vect2.copyFrom(direction).crossLocal(plane.normal).normalizeLocal().crossLocal(direction);
                    //projecting the far point on the base disc perimeter
                    var projectedPoint:Vector3f = vars.vect3.copyFrom(farPoint).addLocal(perpDirection.scaleLocal(farRadius));
                    //checking against the plane
                    dot = plane.pseudoDistance(projectedPoint);
                    if (dot < 0)
					{                        
                        // Outside, the light can be culled
                        return false;
                    }
                }
            }
			
			i--;
		}
		
		return true;	
	}

	private function computeAngleParameters():Void
	{
		var innerCos:Float = Math.cos(mInnerAngle);
		outerAngleCos = Math.cos(mOuterAngle);
		mPackedAngleCos = Std.int(innerCos * 1000);
		
		 //due to approximations, very close angles can give the same cos
        //here we make sure outer cos is bellow inner cos.
        if (Std.int(mPackedAngleCos) == Std.int(outerAngleCos * 1000))
		{
            outerAngleCos -= 0.001;
        }
		mPackedAngleCos += outerAngleCos;
		
		#if debug
		Assert.assert(mPackedAngleCos != 0.0, "Packed angle cosine is invalid");
		#end
        
        // compute parameters needed for cone vs sphere check.
        outerAngleSin    = Math.sin(mOuterAngle);
        outerAngleCosSqr = outerAngleCos * outerAngleCos;
        outerAngleSinSqr = outerAngleSin * outerAngleSin;
        outerAngleSinRcp = 1.0 / outerAngleSin;
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
		computeAngleParameters();
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
		computeAngleParameters();
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

