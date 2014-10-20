package org.angle3d.bullet.objects;

import com.bulletphysics.collision.dispatch.CollisionFlags;
import com.bulletphysics.collision.dispatch.CollisionObject;
import com.bulletphysics.collision.dispatch.PairCachingGhostObject;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.util.ObjectArrayList;
import org.angle3d.bullet.collision.PhysicsCollisionObject;
import org.angle3d.bullet.collision.shapes.CollisionShape;
import org.angle3d.bullet.util.Converter;
import org.angle3d.math.Matrix3f;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;
import vecmath.Quat4f;

/**
 * ...
 * @author weilichuang
 */
class PhysicsGhostObject extends PhysicsCollisionObject
{
	private var gObject:PairCachingGhostObject;
    private var locationDirty:Bool = false;
    //TEMP VARIABLES
    private var tmp_inverseWorldRotation:Quaternion = new Quaternion();
    private var tempTrans:Transform = new Transform();
    private var physicsLocation:org.angle3d.math.Transform = new org.angle3d.math.Transform();
    private var tempRot:Quat4f = new Quat4f();
    private var overlappingObjects:Array<PhysicsCollisionObject> = new Array<PhysicsCollisionObject>();

	public function new(shape:CollisionShape) 
	{
		super();
		collisionShape = shape;
        buildObject();
	}

    private function buildObject():Void
	{
        if (gObject == null) 
		{
            gObject = new PairCachingGhostObject();
            gObject.setCollisionFlags(gObject.getCollisionFlags() | CollisionFlags.NO_CONTACT_RESPONSE);
        }
        gObject.setCollisionShape(collisionShape.getCShape());
        gObject.setUserPointer(this);
    }

    override public function setCollisionShape(collisionShape:CollisionShape):Void
	{
        super.setCollisionShape(collisionShape);
        if (gObject == null)
		{
            buildObject();
        }
		else
		{
            gObject.setCollisionShape(collisionShape.getCShape());
        }
    }

    /**
     * Sets the physics object location
     * @param location the location of the actual physics object
     */
    public function setPhysicsLocation(location:Vector3f):Void
	{
        gObject.getWorldTransform(tempTrans);
        Converter.a2vVector3f(location, tempTrans.origin);
        gObject.setWorldTransform(tempTrans);
    }

    /**
     * Sets the physics object rotation
     * @param rotation the rotation of the actual physics object
     */
    public function setPhysicsRotationMatrix3f(rotation:Matrix3f):Void
	{
        gObject.getWorldTransform(tempTrans);
        Converter.a2vMatrix3f(rotation, tempTrans.basis);
        gObject.setWorldTransform(tempTrans);
    }

    /**
     * Sets the physics object rotation
     * @param rotation the rotation of the actual physics object
     */
    public function setPhysicsRotation(rotation:Quaternion):Void
	{
        gObject.getWorldTransform(tempTrans);
        Converter.aQuaterion2vMatrix3f(rotation, tempTrans.basis);
        gObject.setWorldTransform(tempTrans);
    }

    /**
     * @return the physicsLocation
     */
    public function getPhysicsTransform():org.angle3d.math.Transform 
	{
        return physicsLocation;
    }

    /**
     * @return the physicsLocation
     */
    public function getPhysicsLocation(trans:Vector3f = null):Vector3f
	{
        if (trans == null) 
		{
            trans = new Vector3f();
        }
        gObject.getWorldTransform(tempTrans);
        Converter.v2aVector3f(tempTrans.origin, physicsLocation.translation);
        return trans.copyFrom(physicsLocation.translation);
    }

    /**
     * @return the physicsLocation
     */
    public function getPhysicsRotation(rot:Quaternion = null):Quaternion
	{
        if (rot == null) {
            rot = new Quaternion();
        }
        gObject.getWorldTransform(tempTrans);
        Converter.v2aQuat(tempTrans.getRotation(tempRot), physicsLocation.rotation);
        return rot.copyFrom(physicsLocation.rotation);
    }

    /**
     * @return the physicsLocation
     */
    public function getPhysicsRotationMatrix(rot:Matrix3f = null):Matrix3f
	{
        if (rot == null) 
		{
            rot = new Matrix3f();
        }
        gObject.getWorldTransform(tempTrans);
        Converter.v2aQuat(tempTrans.getRotation(tempRot), physicsLocation.rotation);
        return rot.copyFromQuaternion(physicsLocation.rotation);
    }

    /**
     * used internally
     */
    public function getObjectId():PairCachingGhostObject
	{
        return gObject;
    }

    /**
     * destroys this PhysicsGhostNode and removes it from memory
     */
    public function destroy():Void
	{
    }

    /**
     * Another Object is overlapping with this GhostNode,
     * if and if only there CollisionShapes overlaps.
     * They could be both regular PhysicsRigidBodys or PhysicsGhostObjects.
     * @return All CollisionObjects overlapping with this GhostNode.
     */
    public function getOverlappingObjects():Array<PhysicsCollisionObject>
	{
        overlappingObjects = [];
		
		var pairs:ObjectArrayList<CollisionObject> = gObject.getOverlappingPairs();
		
		for (i in 0...pairs.size())
		{
			overlappingObjects.push(cast pairs.getQuick(i).getUserPointer());
		}

        return overlappingObjects;
    }

    /**
     *
     * @return With how many other CollisionObjects this GhostNode is currently overlapping.
     */
    public function getOverlappingCount():Int
	{
        return gObject.getNumOverlappingObjects();
    }

    /**
     *
     * @param index The index of the overlapping Node to retrieve.
     * @return The Overlapping CollisionObject at the given index.
     */
    public function getOverlapping(index:Int):PhysicsCollisionObject
	{
        return overlappingObjects[index];
    }

    public function setCcdSweptSphereRadius(radius:Float):Void 
	{
        gObject.setCcdSweptSphereRadius(radius);
    }

    public function setCcdMotionThreshold(threshold:Float):Void
	{
        gObject.setCcdMotionThreshold(threshold);
    }

    public function getCcdSweptSphereRadius():Float 
	{
        return gObject.getCcdSweptSphereRadius();
    }

    public function getCcdMotionThreshold():Float
	{
        return gObject.getCcdMotionThreshold();
    }

    public function getCcdSquareMotionThreshold():Float
	{
        return gObject.getCcdSquareMotionThreshold();
    }
}