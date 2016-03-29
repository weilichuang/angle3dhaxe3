package com.bulletphysics.collision.shapes;
import com.bulletphysics.collision.broadphase.BroadphaseNativeType;
import com.bulletphysics.collision.broadphase.BroadphaseNativeTypeUtil;
import com.bulletphysics.linearmath.Transform;
import org.angle3d.math.Vector3f;

/**
 * BoxShape is a box primitive around the origin, its sides axis aligned with length
 * specified by half extents, in local shape coordinates. When used as part of a
 * {CollisionObject} or {RigidBody} it will be an oriented box in world space.
 * @author weilichuang
 */
class CollisionShape
{
	private var userPointer:Dynamic;
	private var _shapeType:BroadphaseNativeType = BroadphaseNativeType.NONE;
	
	public var shapeType(get, never):BroadphaseNativeType;

	public function new() 
	{
		
	}
	
	/**
	 * return the axis aligned bounding box in the coordinate frame of the given transform t
	 * @param	t
	 * @param	aabbMin
	 * @param	aabbMax
	 */
	public function getAabb(t:Transform, aabbMin:Vector3f, aabbMax:Vector3f):Void
	{
		
	}
	
	public function getBoundingSphere(center:Vector3f, radius:Array<Float>):Void
	{
		var tmp:Vector3f = new Vector3f();
		
		var tr:Transform = new Transform();
		tr.setIdentity();
		
		var aabbMin:Vector3f = new Vector3f();
		var aabbMax:Vector3f = new Vector3f();
		
		getAabb(tr, aabbMin, aabbMax);
		
		tmp.subtractBy(aabbMax, aabbMin);
		radius[0] = tmp.length * 0.5;
		
		tmp.addBy(aabbMin, aabbMax);
		center.scaleBy(0.5, tmp);
	}
	
	/**
	 * returns the maximus radius needed for Conservative Advancement to handle time-of-impact with rotations.
	 * @return
	 */
	public function getAngularMotionDisc():Float
	{
		var center:Vector3f = new Vector3f();
		var disc:Array<Float> = [0];
		getBoundingSphere(center, disc);
		disc[0] += center.length;
		return disc[0];
	}
	
	/**
	 * calculateTemporalAabb calculates the enclosing aabb for the moving object over interval [0..timeStep)
     * result is conservative
	 */
	public function calculateTemporalAabb(curTrans:Transform, linvel:Vector3f, angvel:Vector3f, timeStep:Float,
										temporalAabbMin:Vector3f, temporalAabbMax:Vector3f):Void
	{
		//start with static aabb
		getAabb(curTrans, temporalAabbMin, temporalAabbMax);
		
		var temporalAabbMaxx:Float = temporalAabbMax.x;
        var temporalAabbMaxy:Float = temporalAabbMax.y;
        var temporalAabbMaxz:Float = temporalAabbMax.z;
        var temporalAabbMinx:Float = temporalAabbMin.x;
        var temporalAabbMiny:Float = temporalAabbMin.y;
        var temporalAabbMinz:Float = temporalAabbMin.z;

        // add linear motion
        var linMotion:Vector3f = linvel.clone();
        linMotion.scaleLocal(timeStep);

        //todo: simd would have a vector max/min operation, instead of per-element access
        if (linMotion.x > 0) 
		{
            temporalAabbMaxx += linMotion.x;
        } 
		else
		{
            temporalAabbMinx += linMotion.x;
        }
		
        if (linMotion.y > 0) 
		{
            temporalAabbMaxy += linMotion.y;
        }
		else
		{
            temporalAabbMiny += linMotion.y;
        }
		
        if (linMotion.z > 0)
		{
            temporalAabbMaxz += linMotion.z;
        }
		else
		{
            temporalAabbMinz += linMotion.z;
        }

        //add conservative angular motion
        var angularMotion:Float = angvel.length * getAngularMotionDisc() * timeStep;
        var angularMotion3d:Vector3f = new Vector3f();
        angularMotion3d.setTo(angularMotion, angularMotion, angularMotion);
        temporalAabbMin.setTo(temporalAabbMinx, temporalAabbMiny, temporalAabbMinz);
        temporalAabbMax.setTo(temporalAabbMaxx, temporalAabbMaxy, temporalAabbMaxz);

        temporalAabbMin.subtractLocal(angularMotion3d);
        temporalAabbMax.addLocal(angularMotion3d);
	}
	
	public inline function isPolyhedral():Bool
	{
		return BroadphaseNativeTypeUtil.isPolyhedral(shapeType);
	}
	
	public inline function isConvex():Bool
	{
		return BroadphaseNativeTypeUtil.isConvex(shapeType);
	}
	
	/**
	 * 凹形
	 * @return
	 */
	public inline function isConcave():Bool
	{
		return BroadphaseNativeTypeUtil.isConcave(shapeType);
	}
	
	public inline function isCompound():Bool
	{
		return BroadphaseNativeTypeUtil.isCompound(shapeType);
	}
	
	/**
	 * isInfinite is used to catch simulation error (aabb check)
	 * @return
	 */
	public inline function isInfinite():Bool
	{
		return BroadphaseNativeTypeUtil.isInfinite(shapeType);
	}
	
	private inline function get_shapeType():BroadphaseNativeType
	{
		return _shapeType;
	}

    public function setLocalScaling(scaling:Vector3f):Void
	{
		
	}

    // TODO: returns const
    public function getLocalScaling(out:Vector3f):Vector3f
	{
		return out;
	}

    public function calculateLocalInertia(mass:Float,inertia:Vector3f):Void
	{
		
	}


    //debugging support
    public function getName():String
	{
		return Std.string(this);
	}

    //#endif //__SPU__
    public function setMargin(margin:Float):Void
	{
		
	}

    public function getMargin():Float
	{
		return 0;
	}

    // optional user data pointer
    public inline function setUserPointer(userPtr:Dynamic):Void
	{
        userPointer = userPtr;
    }

    public inline function getUserPointer():Dynamic
	{
        return userPointer;
    }
}