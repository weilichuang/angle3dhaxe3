package com.bulletphysics.collision.dispatch;
import com.bulletphysics.collision.broadphase.BroadphaseProxy;
import com.bulletphysics.collision.shapes.CollisionShape;
import com.bulletphysics.linearmath.Transform;
import vecmath.Vector3f;

/**
 * CollisionObject can be used to manage collision detection objects.
 * It maintains all information that is needed for a collision detection: {@link CollisionShape},
 * {@link Transform} and {@link BroadphaseProxy AABB proxy}. It can be added to {@link CollisionWorld}.
 * @author weilichuang
 */
class CollisionObject
{
	// island management, m_activationState1
    public static inline var ACTIVE_TAG:Int = 1;
    public static inline var ISLAND_SLEEPING:Int = 2;
    public static inline var WANTS_DEACTIVATION:Int = 3;
    public static inline var DISABLE_DEACTIVATION:Int = 4;
    public static inline var DISABLE_SIMULATION:Int = 5;
	
	private var worldTransform:Transform = new Transform();
	
	//m_interpolationWorldTransform is used for CCD and interpolation
    //it can be either previous or future (predicted) transform
    private var interpolationWorldTransform:Transform = new Transform();
	
	//those two are experimental: just added for bullet time effect, so you can still apply impulses (directly modifying velocities)
    //without destroying the continuous interpolated motion (which uses this interpolation velocities)
    private var interpolationLinearVelocity:Vector3f = new Vector3f();
    private var interpolationAngularVelocity:Vector3f = new Vector3f();
    private var broadphaseHandle:BroadphaseProxy;
    private var collisionShape:CollisionShape;
	
	// rootCollisionShape is temporarily used to store the original collision shape
    // The collisionShape might be temporarily replaced by a child collision shape during collision detection purposes
    // If it is null, the collisionShape is not temporarily replaced.
    private var rootCollisionShape:CollisionShape;
	
	private var collisionFlags:Int;
    private var islandTag1:Int;
    private var companionId:Int;
    private var activationState1:Int;
    private var deactivationTime:Float;
	
	//摩擦力
    private var friction:Float;
	//弹力
    private var restitution:Float;

    ///users can point to their objects, m_userPointer is not used by Bullet, see setUserPointer/getUserPointer
    private var userObjectPointer:Dynamic;

    // internalType is reserved to distinguish Bullet's CollisionObject, RigidBody, SoftBody etc.
    // do not assign your own internalType unless you write a new dynamics object class.
    private var internalType:CollisionObjectType = CollisionObjectType.COLLISION_OBJECT;

    ///time of impact calculation
    private var hitFraction:Float;
    ///Swept sphere radius (0.0 by default), see btConvexConvexAlgorithm::
    private var ccdSweptSphereRadius:Float;

    /// Don't do continuous collision detection if the motion (in one step) is less then ccdMotionThreshold
    private var ccdMotionThreshold:Float = 0;
    /// If some object should have elaborate collision filtering by sub-classes
    private var _checkCollideWith:Bool;

	public function new() 
	{
		this.collisionFlags = CollisionFlags.STATIC_OBJECT;
        this.islandTag1 = -1;
        this.companionId = -1;
        this.activationState1 = 1;
        this.friction = 0.5;
        this.hitFraction = 1;
	}
	
	public function checkCollideWithOverride(co:CollisionObject):Bool
	{
        return true;
    }

    public inline function mergesSimulationIslands():Bool
	{
        ///static objects, kinematic and object without contact response don't merge islands
        return ((collisionFlags & (CollisionFlags.STATIC_OBJECT | CollisionFlags.KINEMATIC_OBJECT | CollisionFlags.NO_CONTACT_RESPONSE)) == 0);
    }

    public inline function isStaticObject():Bool 
	{
        return (collisionFlags & CollisionFlags.STATIC_OBJECT) != 0;
    }

    public inline function isKinematicObject():Bool 
	{
        return (collisionFlags & CollisionFlags.KINEMATIC_OBJECT) != 0;
    }

    public inline function isStaticOrKinematicObject():Bool 
	{
        return (collisionFlags & CollisionFlags.KINEMATIC_STATIC_OBJECT) != 0;
    }

    public inline function hasContactResponse():Bool 
	{
        return (collisionFlags & CollisionFlags.NO_CONTACT_RESPONSE) == 0;
    }

    public inline function getCollisionShape():CollisionShape
	{
        return collisionShape;
    }

    public function setCollisionShape(collisionShape:CollisionShape):Void 
	{
        this.collisionShape = collisionShape;
        this.rootCollisionShape = collisionShape;
    }

    public function getRootCollisionShape():CollisionShape
	{
        return rootCollisionShape;
    }

    /**
     * Avoid using this internal API call.
     * internalSetTemporaryCollisionShape is used to temporary replace the actual collision shape by a child collision shape.
     */
    public function internalSetTemporaryCollisionShape(collisionShape:CollisionShape):Void  
	{
        this.collisionShape = collisionShape;
    }

    public function getActivationState():Int  
	{
        return activationState1;
    }

    public function setActivationState(newState:Int):Void 
	{
        if ((activationState1 != DISABLE_DEACTIVATION) && (activationState1 != DISABLE_SIMULATION))
		{
            this.activationState1 = newState;
        }
    }

    public function getDeactivationTime():Float
	{
        return deactivationTime;
    }

    public function setDeactivationTime(deactivationTime:Float):Void 
	{
        this.deactivationTime = deactivationTime;
    }

    public function forceActivationState(newState:Int):Void  
	{
        this.activationState1 = newState;
    }

    public function activate(forceActivation:Bool = false):Void  
	{
        if (forceActivation || (collisionFlags & (CollisionFlags.STATIC_OBJECT | CollisionFlags.KINEMATIC_OBJECT)) == 0) 
		{
            setActivationState(ACTIVE_TAG);
            deactivationTime = 0;
        }
    }

    public function isActive():Bool
	{
        return ((getActivationState() != ISLAND_SLEEPING) && (getActivationState() != DISABLE_SIMULATION));
    }

    public function getRestitution():Float
	{
        return restitution;
    }

    public function setRestitution(restitution:Float):Void
	{
        this.restitution = restitution;
    }

    public function getFriction():Float 
	{
        return friction;
    }

    public function setFriction(friction:Float):Void 
	{
        this.friction = friction;
    }

    // reserved for Bullet internal usage
    public function getInternalType():CollisionObjectType
	{
        return internalType;
    }

    public inline function getWorldTransform(out:Transform):Transform  
	{
        out.fromTransform(worldTransform);
        return out;
    }

    public inline function setWorldTransform(worldTransform:Transform):Void
	{
        this.worldTransform.fromTransform(worldTransform);
    }

    public function getBroadphaseHandle():BroadphaseProxy
	{
        return broadphaseHandle;
    }

    public function setBroadphaseHandle(broadphaseHandle:BroadphaseProxy):Void 
	{
        this.broadphaseHandle = broadphaseHandle;
    }

    public function  getInterpolationWorldTransform(out:Transform):Transform
	{
        out.fromTransform(interpolationWorldTransform);
        return out;
    }

    public function setInterpolationWorldTransform(interpolationWorldTransform:Transform):Void  
	{
        this.interpolationWorldTransform.fromTransform(interpolationWorldTransform);
    }

    public function setInterpolationLinearVelocity(linvel:Vector3f):Void
	{
        interpolationLinearVelocity.fromVector3f(linvel);
    }

    public function setInterpolationAngularVelocity(angvel:Vector3f):Void
	{
        interpolationAngularVelocity.fromVector3f(angvel);
    }

    public function getInterpolationLinearVelocity(out:Vector3f):Vector3f 
	{
        out.fromVector3f(interpolationLinearVelocity);
        return out;
    }

    public function getInterpolationAngularVelocity(out:Vector3f):Vector3f 
	{
        out.fromVector3f(interpolationAngularVelocity);
        return out;
    }

    public function getIslandTag():Int
	{
        return islandTag1;
    }

    public function setIslandTag(islandTag:Int):Void 
	{
        this.islandTag1 = islandTag;
    }

    public function getCompanionId():Int
	{
        return companionId;
    }

    public function setCompanionId(companionId:Int):Void  
	{
        this.companionId = companionId;
    }

    public function getHitFraction():Float
	{
        return hitFraction;
    }

    public function setHitFraction(hitFraction:Float):Void
	{
        this.hitFraction = hitFraction;
    }

    public function getCollisionFlags():Int
	{
        return collisionFlags;
    }

    public function setCollisionFlags(collisionFlags:Int):Void
	{
        this.collisionFlags = collisionFlags;
    }

    // Swept sphere radius (0.0 by default), see btConvexConvexAlgorithm::
    public function getCcdSweptSphereRadius():Float
	{
        return ccdSweptSphereRadius;
    }

    // Swept sphere radius (0.0 by default), see btConvexConvexAlgorithm::
    public function setCcdSweptSphereRadius(ccdSweptSphereRadius:Float):Void
	{
        this.ccdSweptSphereRadius = ccdSweptSphereRadius;
    }

    public function getCcdMotionThreshold():Float 
	{
        return ccdMotionThreshold;
    }

    public function getCcdSquareMotionThreshold():Float
	{
        return ccdMotionThreshold * ccdMotionThreshold;
    }

    // Don't do continuous collision detection if the motion (in one step) is less then ccdMotionThreshold
    public function setCcdMotionThreshold(ccdMotionThreshold:Float):Void
	{
        // JAVA NOTE: fixed bug with usage of ccdMotionThreshold*ccdMotionThreshold
        this.ccdMotionThreshold = ccdMotionThreshold;
    }

    public function getUserPointer():Dynamic
	{
        return userObjectPointer;
    }

    public function setUserPointer(userObjectPointer:Dynamic):Void 
	{
        this.userObjectPointer = userObjectPointer;
    }

    public function checkCollideWith(co:CollisionObject):Bool 
	{
        if (_checkCollideWith)
		{
            return checkCollideWithOverride(co);
        }

        return true;
    }
}