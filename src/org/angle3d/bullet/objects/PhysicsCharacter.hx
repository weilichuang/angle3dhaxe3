package org.angle3d.bullet.objects;

import com.bulletphysics.collision.dispatch.CollisionFlags;
import com.bulletphysics.collision.dispatch.PairCachingGhostObject;
import com.bulletphysics.collision.shapes.ConvexShape;
import com.bulletphysics.dynamics.character.KinematicCharacterController;
import com.bulletphysics.linearmath.Transform;
import org.angle3d.bullet.collision.PhysicsCollisionObject;
import org.angle3d.bullet.collision.shapes.CollisionShape;
import org.angle3d.bullet.util.Converter;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;

/**
 * ...
 * @author weilichuang
 */
class PhysicsCharacter extends PhysicsCollisionObject
{
	private var character:KinematicCharacterController;
    private var stepHeight:Float;
    private var walkDirection:Vector3f = new Vector3f();
    private var fallSpeed:Float = 55.0;
    private var jumpSpeed:Float = 10.0;
    private var upAxis:Int = 1;
    private var gObject:PairCachingGhostObject;
    private var locationDirty:Bool = false;
    //TEMP VARIABLES
    private var tmp_inverseWorldRotation:Quaternion = new Quaternion();
    private var tempTrans:Transform = new Transform();
    private var physicsLocation:org.angle3d.math.Transform = new org.angle3d.math.Transform();
    private var tempVec:org.angle3d.math.Vector3f = new org.angle3d.math.Vector3f();

    /**
     * @param shape The CollisionShape (no Mesh or CompoundCollisionShapes)
     * @param stepHeight The quantization size for vertical movement
     */
    public function new(shape:CollisionShape, stepHeight:Float)
	{
		super();
        this.collisionShape = shape;
        if (!Std.is(shape.getCShape(), ConvexShape))
		{
            throw ("Kinematic character nodes cannot have mesh collision shapes");
        }
        this.stepHeight = stepHeight;
        buildObject();
    }

    private function buildObject():Void
	{
        if (gObject == null)
		{
            gObject = new PairCachingGhostObject();
        }
        gObject.setCollisionFlags(CollisionFlags.CHARACTER_OBJECT);
        gObject.setCollisionFlags(gObject.getCollisionFlags() & ~CollisionFlags.NO_CONTACT_RESPONSE);
        gObject.setCollisionShape(collisionShape.getCShape());
        gObject.setUserPointer(this);
        character = new KinematicCharacterController(gObject, cast collisionShape.getCShape(), stepHeight);
    }

    /**
     * Sets the location of this physics character
     * @param location
     */
    public function warp(location:Vector3f):Void
	{
        character.warp(Converter.a2vVector3f(location, tempVec));
    }

    /**
     * Set the walk direction, works continuously.
     * This should probably be called setPositionIncrementPerSimulatorStep.
     * This is neither a direction nor a velocity, but the amount to
     * increment the position each physics tick. So vector length = accuracy*speed in m/s
     * @param vec the walk direction to set
     */
    public function setWalkDirection(vec:Vector3f):Void
	{
        walkDirection.copyFrom(vec);
        character.setWalkDirection(Converter.a2vVector3f(walkDirection, tempVec));
    }

    /**
     * @return the currently set walkDirection
     */
    public function getWalkDirection():Vector3f
	{
        return walkDirection;
    }

    public function setUpAxis(axis:Int):Void
	{
        upAxis = axis;
        character.setUpAxis(axis);
    }

    public function getUpAxis():Int
	{
        return upAxis;
    }

    public function setFallSpeed(fallSpeed:Float):Void
	{
        this.fallSpeed = fallSpeed;
        character.setFallSpeed(fallSpeed);
    }

    public function getFallSpeed():Float
	{
        return fallSpeed;
    }

    public function setJumpSpeed(jumpSpeed:Float):Void
	{
        this.jumpSpeed = jumpSpeed;
        character.setJumpSpeed(jumpSpeed);
    }

    public function getJumpSpeed():Float 
	{
        return jumpSpeed;
    }

    //does nothing..
//    public void setMaxJumpHeight(float height) {
//        character.setMaxJumpHeight(height);
//    }
    public function setGravity(value:Float):Void 
	{
        character.setGravity(value);
    }

    public function getGravity():Float
	{
        return character.getGravity();
    }

    public function setMaxSlope(slopeRadians:Float):Void
	{
        character.setMaxSlope(slopeRadians);
    }

    public function getMaxSlope():Float 
	{
        return character.getMaxSlope();
    }

    public function onGround():Bool
	{
        return character.onGround();
    }

    public function jump():Void 
	{
        character.jump();
    }
	
	override public function setCollisionShape(collisionShape:CollisionShape):Void 
	{
		if (!Std.is(collisionShape.getCShape(), ConvexShape))
		{
            throw ("Kinematic character nodes cannot have mesh collision shapes");
        }
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
     * Set the physics location (same as warp())
     * @param location the location of the actual physics object
     */
    public function setPhysicsLocation(location:Vector3f):Void
	{
        warp(location);
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
        Converter.v2aVector3f(gObject.getWorldTransform().origin, physicsLocation.translation);
        return trans.copyFrom(physicsLocation.translation);
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

    /**
     * used internally
     */
    public function getControllerId():KinematicCharacterController 
	{
        return character;
    }

    /**
     * used internally
     */
    public function getObjectId():PairCachingGhostObject 
	{
        return gObject;
    }

    public function destroy():Void 
	{
    }
}