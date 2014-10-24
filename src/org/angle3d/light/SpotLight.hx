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
		if (this.spotRange > 0) 
		{
            // Check spot range first.
            // Sphere v. box collision
            if (FastMath.abs(box.center.x - position.x) >= spotRange + box.xExtent
             || FastMath.abs(box.center.y - position.y) >= spotRange + box.yExtent
             || FastMath.abs(box.center.z - position.z) >= spotRange + box.zExtent)
			{
                return false;
            }
        }
        
        var otherCenter:Vector3f = box.center;
        var radVect:Vector3f = vars.vect4;
        radVect.setTo(box.xExtent, box.yExtent, box.zExtent);
        var otherRadiusSquared:Float = radVect.lengthSquared;
        var otherRadius:Float = Math.sqrt(otherRadiusSquared);
        
        // Check if sphere is within spot angle.
        // Cone v. sphere collision.
        var E:Vector3f = direction.scale(otherRadius * outerAngleSinRcp, vars.vect1);
        var U:Vector3f = position.subtract(E, vars.vect2);
        var D:Vector3f = otherCenter.subtract(U, vars.vect3);

        var dsqr:Float = D.dot(D);
        var e:Float = direction.dot(D);

        if (e > 0 && e * e >= dsqr * outerAngleCosSqr) 
		{
            D = otherCenter.subtract(position, vars.vect3);
            dsqr = D.dot(D);
            e = -direction.dot(D);

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
		if (this.spotRange == 0)
		{
            return true;
        } 
		else
		{
            // Do a frustum v. OBB test.
            
            // Determine OBB extents assuming OBB center is the middle
            // point between the cone's vertex and its range.
            var sideExtent:Float    = spotRange * 0.5 * outerAngleSin;
            var forwardExtent:Float = spotRange * 0.5;
            
            // Create OBB axes via direction and Y up vector.
            var xAxis:Vector3f = Vector3f.Y_AXIS.cross(direction, vars.vect1).normalizeLocal();
            var yAxis:Vector3f = direction.cross(xAxis, vars.vect2).normalizeLocal();
            var obbCenter:Vector3f = direction.scale(spotRange * 0.5, vars.vect3).addLocal(position);

			var i:Int = 5;
            while (i >= 0)
			{
                var plane:Plane = camera.getWorldPlane(i);
                var planeNormal:Vector3f = plane.normal;
                
                // OBB v. plane intersection
                var radius:Float = FastMath.abs(sideExtent * (planeNormal.dot(xAxis)))
                             + FastMath.abs(sideExtent * (planeNormal.dot(yAxis)))
                             + FastMath.abs(forwardExtent * (planeNormal.dot(direction)));
                
                var distance:Float = plane.pseudoDistance(obbCenter);
                if (distance <= -radius) 
				{
                    return false;
                }
				
				i--;
            }
            return true;
        }
	}

	private function computeAngleParameters():Void
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
		
		if (packedAngleCos == 0.0)
		{
            throw ("Packed angle cosine is invalid");
        }
        
        // compute parameters needed for cone vs sphere check.
        outerAngleSin    = Math.sin(mOuterAngle);
        outerAngleCosSqr = outerCos * outerCos;
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

