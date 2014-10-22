package org.angle3d.bullet.collision;
import com.bulletphysics.collision.narrowphase.ManifoldPoint;
import org.angle3d.math.Vector3f;
import org.angle3d.bullet.util.Converter;
import org.angle3d.scene.Spatial;

/**
 * A CollisionEvent stores all information about a collision in the PhysicsWorld.
 * Do not store this Object, as it will be reused after the collision() method has been called.
 * Get/reference all data you need in the collide method.
 * 
 * @author weilichuang
 */
class PhysicsCollisionEvent
{
	public static inline var TYPE_ADDED:Int = 0;
    public static inline var TYPE_PROCESSED:Int = 1;
    public static inline var TYPE_DESTROYED:Int = 2;
	
	public var source:PhysicsCollisionObject;
    private var type:Int;
    private var nodeA:PhysicsCollisionObject;
    private var nodeB:PhysicsCollisionObject;
    private var cp:ManifoldPoint;

    public function new(type:Int, source:PhysicsCollisionObject, nodeB:PhysicsCollisionObject, cp:ManifoldPoint)
	{
		this.source = source;
        this.type = type;
        this.nodeA = source;
        this.nodeB = nodeB;
        this.cp = cp;
    }

    /**
     * used by event factory, called when event is destroyed
     */
    public inline function clean():Void
	{
        source = null;
        type = 0;
        nodeA = null;
        nodeB = null;
        cp = null;
    }

    /**
     * used by event factory, called when event reused
     */
    public inline function refactor(type:Int, source:PhysicsCollisionObject, nodeB:PhysicsCollisionObject, cp:ManifoldPoint):Void
	{
        this.source = source;
        this.type = type;
        this.nodeA = source;
        this.nodeB = nodeB;
        this.cp = cp;
    }

    public inline function getType():Int
	{
        return type;
    }

    /**
     * @return A Spatial if the UserObject of the PhysicsCollisionObject is a Spatial
     */
    public function getNodeA():Spatial
	{
        if (Std.is(nodeA.getUserObject(), Spatial))
		{
            return cast nodeA.getUserObject();
        }
        return null;
    }

    /**
     * @return A Spatial if the UserObject of the PhysicsCollisionObject is a Spatial
     */
    public function getNodeB():Spatial
	{
        if (Std.is(nodeB.getUserObject(), Spatial))
		{
            return cast nodeB.getUserObject();
        }
        return null;
    }

    public function getObjectA():PhysicsCollisionObject
	{
        return nodeA;
    }

    public function getObjectB():PhysicsCollisionObject
	{
        return nodeB;
    }

    public function getAppliedImpulse():Float
	{
        return cp.appliedImpulse;
    }

    public function getAppliedImpulseLateral1():Float
	{
        return cp.appliedImpulseLateral1;
    }

    public function getAppliedImpulseLateral2():Float
	{
        return cp.appliedImpulseLateral2;
    }

    public function getCombinedFriction():Float
	{
        return cp.combinedFriction;
    }

    public function getCombinedRestitution():Float
	{
        return cp.combinedRestitution;
    }

    public function getDistance1():Float
	{
        return cp.distance1;
    }

    public function getIndex0():Int
	{
        return cp.index0;
    }

    public function getIndex1():Int
	{
        return cp.index1;
    }

    public function getLateralFrictionDir1():Vector3f
	{
        return Converter.v2aVector3f(cp.lateralFrictionDir1);
    }

    public function getLateralFrictionDir2():Vector3f
	{
        return Converter.v2aVector3f(cp.lateralFrictionDir2);
    }

    public function isLateralFrictionInitialized():Bool
	{
        return cp.lateralFrictionInitialized;
    }

    public function getLifeTime():Int
	{
        return cp.lifeTime;
    }

    public function getLocalPointA():Vector3f
	{
        return Converter.v2aVector3f(cp.localPointA);
    }

    public function getLocalPointB():Vector3f
	{
        return Converter.v2aVector3f(cp.localPointB);
    }

    public function getNormalWorldOnB():Vector3f
	{
        return Converter.v2aVector3f(cp.normalWorldOnB);
    }

    public function getPartId0():Int
	{
        return cp.partId0;
    }

    public function getPartId1():Int
	{
        return cp.partId1;
    }

    public function getPositionWorldOnA():Vector3f
	{
        return Converter.v2aVector3f(cp.positionWorldOnA);
    }

    public function getPositionWorldOnB():Vector3f
	{
        return Converter.v2aVector3f(cp.positionWorldOnB);
    }

    public function getUserPersistentData():Dynamic
	{
        return cp.userPersistentData;
    }
	
}