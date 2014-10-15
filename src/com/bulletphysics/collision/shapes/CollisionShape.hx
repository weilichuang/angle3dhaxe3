package com.bulletphysics.collision.shapes;
import com.bulletphysics.collision.broadphase.BroadphaseNativeType;
import com.bulletphysics.collision.broadphase.BroadphaseNativeTypeUtil;
import com.bulletphysics.linearmath.Transform;
import vecmath.Vector3f;

/**
 * BoxShape is a box primitive around the origin, its sides axis aligned with length
 * specified by half extents, in local shape coordinates. When used as part of a
 * {@link CollisionObject} or {@link RigidBody} it will be an oriented box in world space.
 * @author weilichuang
 */
class CollisionShape
{
	private var userPointer:Dynamic;

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
		
		tmp.sub(aabbMax, aabbMin);
		radius[0] = tmp.length() * 0.5;
		
		tmp.add(aabbMin, aabbMax);
		center.scale(0.5, tmp);
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
		disc[0] += center.length();
		return disc[0];
	}
	
	/**
	 * calculateTemporalAabb calculates the enclosing aabb for the moving object over interval [0..timeStep)
     * result is conservative
	 */
	public function calculateTemporalAabb(curTrans:Transform, linvel:Vector3f, angvel:Vector3f, timeStep:Float, temporalAabbMin:Vector3f, temporalAabbMax:Vector3f):Void
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
        linMotion.scale(timeStep);

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
        var angularMotion:Float = angvel.length() * getAngularMotionDisc() * timeStep;
        var angularMotion3d:Vector3f = new Vector3f();
        angularMotion3d.setTo(angularMotion, angularMotion, angularMotion);
        temporalAabbMin.setTo(temporalAabbMinx, temporalAabbMiny, temporalAabbMinz);
        temporalAabbMax.setTo(temporalAabbMaxx, temporalAabbMaxy, temporalAabbMaxz);

        temporalAabbMin.sub(angularMotion3d);
        temporalAabbMax.add(angularMotion3d);
	}
	
	public function isPolyhedral():Bool
	{
		return BroadphaseNativeTypeUtil.isPolyhedral(getShapeType());
	}
	
	public function isConvex():Bool
	{
		return BroadphaseNativeTypeUtil.isConvex(getShapeType());
	}
	
	/**
	 * 凹形
	 * @return
	 */
	public function isConcave():Bool
	{
		return BroadphaseNativeTypeUtil.isConcave(getShapeType());
	}
	
	public function isCompound():Bool
	{
		return BroadphaseNativeTypeUtil.isCompound(getShapeType());
	}
	
	public function isVoxelWorld():Bool
	{
		return BroadphaseNativeTypeUtil.isVoxelWorld(getShapeType());
	}
	
	/**
	 * isInfinite is used to catch simulation error (aabb check)
	 * @return
	 */
	public function isInfinite():Bool
	{
		return BroadphaseNativeTypeUtil.isInfinite(getShapeType());
	}
	
	public function getShapeType():BroadphaseNativeType
	{
		return null;
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
    public function setUserPointer(userPtr:Dynamic):Void
	{
        userPointer = userPtr;
    }

    public function getUserPointer():Dynamic
	{
        return userPointer;
    }
}