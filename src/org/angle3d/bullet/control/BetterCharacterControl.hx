package org.angle3d.bullet.control;

import org.angle3d.bullet.collision.PhysicsRayTestResult;
import org.angle3d.bullet.collision.shapes.CapsuleCollisionShape;
import org.angle3d.bullet.collision.shapes.CollisionShape;
import org.angle3d.bullet.collision.shapes.CompoundCollisionShape;
import org.angle3d.bullet.objects.PhysicsRigidBody;
import org.angle3d.bullet.PhysicsSpace;
import org.angle3d.bullet.PhysicsTickListener;
import org.angle3d.math.FastMath;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.control.Control;
import org.angle3d.scene.Spatial;
import org.angle3d.utils.Logger;
import org.angle3d.utils.TempVars;

/**
 * This is intended to be a replacement for the internal bullet character class.
 * A RigidBody with cylinder collision shape is used and its velocity is set
 * continuously, a ray test is used to check if the character is on the ground.
 *
 * The character keeps his own local coordinate system which adapts based on the
 * gravity working on the character so the character will always stand upright.
 *
 * Forces in the local x/z plane are dampened while those in the local y
 * direction are applied fully (e.g. jumping, falling).
 *
 */
class BetterCharacterControl extends AbstractPhysicsControl implements PhysicsTickListener
{

	private var rigidBody:PhysicsRigidBody;
    private var radius:Float;
    private var height:Float;
    private var mass:Float;
    private var duckedFactor:Float = 0.6;
    /**
     * Local up direction, derived from gravity.
     */
    private var localUp:Vector3f = new Vector3f(0, 1, 0);
    /**
     * Local absolute z-forward direction, derived from gravity and UNIT_Z,
     * updated continuously when gravity changes.
     */
    private var localForward:Vector3f = new Vector3f(0, 0, 1);
    /**
     * Local left direction, derived from up and forward.
     */
    private var localLeft:Vector3f = new Vector3f(1, 0, 0);
    /**
     * Local z-forward quaternion for the "local absolute" z-forward direction.
     */
    private var localForwardRotation:Quaternion;
    /**
     * Is a z-forward vector based on the view direction and the current local
     * x/z plane.
     */
    private var viewDirection:Vector3f = new Vector3f(0, 0, 1);
    /**
     * Stores final spatial location, corresponds to RigidBody location.
     */
    private var location:Vector3f = new Vector3f();
    /**
     * Stores final spatial rotation, is a z-forward rotation based on the view
     * direction and the current local x/z plane. See also rotatedViewDirection.
     */
    private var rotation:Quaternion;
    private var rotatedViewDirection:Vector3f = new Vector3f(0, 0, 1);
    private var walkDirection:Vector3f = new Vector3f();
    private var jumpForce:Vector3f;
    private var physicsDamping:Float = 0.9;
    private var scale:Vector3f = new Vector3f(1, 1, 1);
    private var velocity:Vector3f = new Vector3f();
    private var _jump:Bool = false;
    private var onGround:Bool = false;
    private var ducked:Bool = false;
    private var wantToUnDuck:Bool = false;

    /**
     * Creates a new character with the given properties. Note that to avoid
     * issues the final height when ducking should be larger than 2x radius. The
     * jumpForce will be set to an upwards force of 5x mass.
     *
     * @param radius
     * @param height
     * @param mass
     */
    public function new(radius:Float, height:Float, mass:Float)
	{
		super();
		
        this.radius = radius;
        this.height = height;
        this.mass = mass;
        rigidBody = new PhysicsRigidBody(getShape(), mass);
        jumpForce = new Vector3f(0, mass * 5, 0);
        rigidBody.setAngularFactor(0);
		
		localForwardRotation = Quaternion.DIRECTION_Z.clone();
    }
	
	override public function update(tpf:Float):Void 
	{
		super.update(tpf);
        rigidBody.getPhysicsLocation(location);
        //rotation has been set through viewDirection
        applyPhysicsTransform(location, rotation);
	}

    /**
     * Used internally, don't call manually
     *
     * @param space
     * @param tpf
     */
    public function prePhysicsTick(space:PhysicsSpace, tpf:Float):Void
	{
        checkOnGround();
        if (wantToUnDuck && checkCanUnDuck())
		{
            setHeightPercent(1);
            wantToUnDuck = false;
            ducked = false;
        }
		
        var vars:TempVars = TempVars.getTempVars();

        // dampen existing x/z forces
        var existingLeftVelocity:Float = velocity.dot(localLeft);
        var existingForwardVelocity:Float = velocity.dot(localForward);
        var counter:Vector3f = vars.vect1;
        existingLeftVelocity = existingLeftVelocity * physicsDamping;
        existingForwardVelocity = existingForwardVelocity * physicsDamping;
        counter.setTo(-existingLeftVelocity, 0, -existingForwardVelocity);
        localForwardRotation.multVecLocal(counter);
        velocity.addLocal(counter);

        var designatedVelocity:Float = walkDirection.length;
        if (designatedVelocity > 0)
		{
            var localWalkDirection:Vector3f = vars.vect1;
            //normalize walkdirection
            localWalkDirection.copyFrom(walkDirection).normalizeLocal();
            //check for the existing velocity in the desired direction
            var existingVelocity:Float = velocity.dot(localWalkDirection);
            //calculate the final velocity in the desired direction
            var finalVelocity:Float = designatedVelocity - existingVelocity;
            localWalkDirection.scaleLocal(finalVelocity);
            //add resulting vector to existing velocity
            velocity.addLocal(localWalkDirection);
        }
        rigidBody.setLinearVelocity(velocity);
        if (_jump) 
		{
            //TODO: precalculate jump force
            var rotatedJumpForce:Vector3f = vars.vect1;
            rotatedJumpForce.copyFrom(jumpForce);
            rigidBody.applyImpulse(localForwardRotation.multVecLocal(rotatedJumpForce), Vector3f.ZERO);
            _jump = false;
        }
        vars.release();
    }

    /**
     * Used internally, don't call manually
     *
     * @param space
     * @param tpf
     */
    public function physicsTick(space:PhysicsSpace, tpf:Float):Void
	{
        rigidBody.getLinearVelocity(velocity);
    }

    /**
     * Move the character somewhere. Note the character also takes the location
     * of any spatial its being attached to in the moment it is attached.
     *
     * @param vec The new character location.
     */
    public function warp(vec:Vector3f):Void
	{
        setPhysicsLocation(vec);
    }

    /**
     * Makes the character jump with the set jump force.
     */
    public function jump():Void
	{
        //TODO: debounce over some frames
        if (!onGround)
		{
            return;
        }
        _jump = true;
    }

    /**
     * Set the jump force as a Vector3f. The jump force is local to the
     * characters coordinate system, which normally is always z-forward (in
     * world coordinates, parent coordinates when set to applyLocalPhysics)
     *
     * @param jumpForce The new jump force
     */
    public function setJumpForce(jumpForce:Vector3f):Void
	{
        this.jumpForce.copyFrom(jumpForce);
    }

    /**
     * Gets the current jump force. The default is 5 * character mass in y
     * direction.
     *
     * @return
     */
    public function getJumpForce():Vector3f
	{
        return jumpForce;
    }

    /**
     * Check if the character is on the ground. This is determined by a ray test
     * in the center of the character and might return false even if the
     * character is not falling yet.
     *
     * @return
     */
    public function isOnGround():Bool
	{
        return onGround;
    }

    /**
     * Toggle character ducking. When ducked the characters capsule collision
     * shape height will be multiplied by duckedFactor to make the capsule
     * smaller. When unducking, the character will check with a ray test if it
     * can in fact unduck and only do so when its possible. You can check the
     * state of the unducking by checking isDucked().
     *
     * @param enabled
     */
    public function setDucked(enabled:Bool):Void
	{
        if (enabled)
		{
            setHeightPercent(duckedFactor);
            ducked = true;
            wantToUnDuck = false;
        } 
		else
		{
            if (checkCanUnDuck()) 
			{
                setHeightPercent(1);
                ducked = false;
            } 
			else
			{
                wantToUnDuck = true;
            }
        }
    }

    /**
     * Check if the character is ducking, either due to user input or due to
     * unducking being impossible at the moment (obstacle above).
     *
     * @return
     */
    public function isDucked():Bool
	{
        return ducked;
    }

    /**
     * Sets the height multiplication factor for ducking.
     *
     * @param factor The factor by which the height should be multiplied when
     * ducking
     */
    public function setDuckedFactor(factor:Float):Void
	{
        duckedFactor = factor;
    }

    /**
     * Gets the height multiplication factor for ducking.
     *
     * @return
     */
    public function getDuckedFactor():Float
	{
        return duckedFactor;
    }

    /**
     * Sets the walk direction of the character. This parameter is framerate
     * independent and the character will move continuously in the direction
     * given by the vector with the speed given by the vector length in m/s.
     *
     * @param vec The movement direction and speed in m/s
     */
    public function setWalkDirection(vec:Vector3f):Void
	{
        walkDirection.copyFrom(vec);
    }

    /**
     * Gets the current walk direction and speed of the character. The length of
     * the vector defines the speed.
     *
     * @return
     */
    public function getWalkDirection():Vector3f
	{
        return walkDirection;
    }

    /**
     * Sets the view direction for the character. Note this only defines the
     * rotation of the spatial in the local x/z plane of the character.
     *
     * @param vec
     */
    public function setViewDirection(vec:Vector3f):Void
	{
        viewDirection.copyFrom(vec);
        updateLocalViewDirection();
    }

    /**
     * Gets the current view direction, note this doesn't need to correspond
     * with the spatials forward direction.
     *
     * @return
     */
    public function getViewDirection():Vector3f
	{
        return viewDirection;
    }

    /**
     * Realign the local forward vector to given direction vector, if null is
     * supplied Vector3f.UNIT_Z is used. Input vector has to be perpendicular to
     * current gravity vector. This normally only needs to be called when the
     * gravity direction changed continuously and the local forward vector is
     * off due to drift. E.g. after walking around on a sphere "planet" for a
     * while and then going back to a y-up coordinate system the local z-forward
     * might not be 100% alinged with Z axis.
     *
     * @param vec The new forward vector, has to be perpendicular to the current
     * gravity vector!
     */
    public function resetForward(vec:Vector3f):Void
	{
        if (vec == null) 
		{
            vec = new Vector3f(0, 1, 0);
        }
        localForward.copyFrom(vec);
        updateLocalCoordinateSystem();
    }

    /**
     * Get the current linear velocity along the three axes of the character.
     * This is prepresented in world coordinates, parent coordinates when the
     * control is set to applyLocalPhysics.
     *
     * @return The current linear velocity of the character
     */
    public function getVelocity():Vector3f
	{
        return velocity;
    }

    /**
     * Set the gravity for this character. Note that this also realigns the
     * local coordinate system of the character so that continuous changes in
     * gravity direction are possible while maintaining a sensible control over
     * the character.
     *
     * @param gravity
     */
    public function setGravity(gravity:Vector3f):Void
	{
        rigidBody.setGravity(gravity);
        localUp.copyFrom(gravity).normalizeLocal().negateLocal();
        updateLocalCoordinateSystem();
    }

    /**
     * Get the current gravity of the character.
     *
     * @param store The vector to store the result in
     * @return
     */
    public function getGravity(store:Vector3f = null):Vector3f
	{
        return rigidBody.getGravity(store);
    }

    /**
     * Sets how much the physics forces in the local x/z plane should be
     * dampened.
     * @param physicsDamping The dampening value, 0 = no dampening, 1 = no external force, default = 0.9
     */
    public function setPhysicsDamping(physicsDamping:Float):Void
	{
        this.physicsDamping = physicsDamping;
    }

    /**
     * Gets how much the physics forces in the local x/z plane should be
     * dampened.
     */
    public function getPhysicsDamping():Float
	{
        return physicsDamping;
    }

    /**
     * This actually sets a new collision shape to the character to change the
     * height of the capsule.
     *
     * @param percent
     */
    private function setHeightPercent(percent:Float):Void
	{
        scale.y = percent;
        rigidBody.setCollisionShape(getShape());
    }

    /**
     * This checks if the character is on the ground by doing a ray test.
     */
    private function checkOnGround():Void
	{
        var vars:TempVars = TempVars.getTempVars();
        var location:Vector3f = vars.vect1;
        var rayVector:Vector3f = vars.vect2;
        var height:Float = getFinalHeight();
        location.copyFrom(localUp).scaleLocal(height).addLocal(this.location);
        rayVector.copyFrom(localUp).scaleLocal( -height - 0.1).addLocal(location);
		
        var results:Array<PhysicsRayTestResult> = space.rayTest(location, rayVector);
		
        vars.release();
		
		for (i in 0...results.length)
		{
			if (results[i].getCollisionObject() != rigidBody)
			{
                onGround = true;
                return;
            }
		}
        onGround = false;
    }

    /**
     * This checks if the character can go from ducked to unducked state by
     * doing a ray test.
     */
    private function checkCanUnDuck():Bool
	{
        var vars:TempVars = TempVars.getTempVars();
        var location:Vector3f = vars.vect1;
        var rayVector:Vector3f = vars.vect2;
        location.copyFrom(localUp).scaleLocal(FastMath.ZERO_TOLERANCE).addLocal(this.location);
        rayVector.copyFrom(localUp).scaleLocal(height + FastMath.ZERO_TOLERANCE).addLocal(location);
		
        var results:Array<PhysicsRayTestResult> = space.rayTest(location, rayVector);
		
        vars.release();
        
		for (i in 0...results.length)
		{
            if (results[i].getCollisionObject() != rigidBody)
			{
                return false;
            }
        }
        return true;
    }

    /**
     * Gets a new collision shape based on the current scale parameter. The
     * created collisionshape is a capsule collision shape that is attached to a
     * compound collision shape with an offset to set the object center at the
     * bottom of the capsule.
     *
     * @return
     */
    private function getShape():CollisionShape
	{
        //TODO: cleanup size mess..
        var capsuleCollisionShape:CapsuleCollisionShape = new CapsuleCollisionShape(getFinalRadius(), (getFinalHeight() - (2 * getFinalRadius())));
        var compoundCollisionShape:CompoundCollisionShape = new CompoundCollisionShape();
        var addLocation:Vector3f = new Vector3f(0, (getFinalHeight() / 2.0), 0);
        compoundCollisionShape.addChildShape(capsuleCollisionShape, addLocation);
        return compoundCollisionShape;
    }

    /**
     * Gets the scaled height.
     *
     * @return
     */
    private function getFinalHeight():Float
	{
        return height * scale.y;
    }

    /**
     * Gets the scaled radius.
     *
     * @return
     */
    private function getFinalRadius():Float
	{
        return radius * scale.z;
    }

    /**
     * Updates the local coordinate system from the localForward and localUp
     * vectors, adapts localForward, sets localForwardRotation quaternion to
     * local z-forward rotation.
     */
    private function updateLocalCoordinateSystem():Void
	{
        //gravity vector has possibly changed, calculate new world forward (UNIT_Z)
        calculateNewForward(localForwardRotation, localForward, localUp);
        localLeft.copyFrom(localUp).crossLocal(localForward);
        rigidBody.setPhysicsRotationWithQuaternion(localForwardRotation);
        updateLocalViewDirection();
    }

    /**
     * Updates the local x/z-flattened view direction and the corresponding
     * rotation quaternion for the spatial.
     */
    private function updateLocalViewDirection():Void
	{
        //update local rotation quaternion to use for view rotation
        localForwardRotation.multVecLocal(rotatedViewDirection.copyFrom(viewDirection));
        calculateNewForward(rotation, rotatedViewDirection, localUp);
    }

    /**
     * This method works similar to Camera.lookAt but where lookAt sets the
     * priority on the direction, this method sets the priority on the up vector
     * so that the result direction vector and rotation is guaranteed to be
     * perpendicular to the up vector.
     *
     * @param rotation The rotation to set the result on or null to create a new
     * Quaternion, this will be set to the new "z-forward" rotation if not null
     * @param direction The direction to base the new look direction on, will be
     * set to the new direction
     * @param worldUpVector The up vector to use, the result direction will be
     * perpendicular to this
     * @return
     */
    private function calculateNewForward(rotation:Quaternion, direction:Vector3f, worldUpVector:Vector3f):Void
	{
        if (direction == null)
		{
            return;
        }
        var vars:TempVars = TempVars.getTempVars();
        var newLeft:Vector3f = vars.vect1;
        var newLeftNegate:Vector3f = vars.vect2;

        newLeft.copyFrom(worldUpVector).crossLocal(direction).normalizeLocal();
        if (newLeft.equals(Vector3f.ZERO))
		{
            if (direction.x != 0)
			{
                newLeft.setTo(direction.y, -direction.x, 0).normalizeLocal();
            } 
			else
			{
                newLeft.setTo(0, direction.z, -direction.y).normalizeLocal();
            }
            Logger.log('Zero left for direction ${direction.toString()}, up ${worldUpVector.toString()}');
        }
        newLeftNegate.copyFrom(newLeft).negateLocal();
        direction.copyFrom(worldUpVector).crossLocal(newLeftNegate).normalizeLocal();
        if (direction.equals(Vector3f.ZERO))
		{
            direction.copyFrom(Vector3f.UNIT_Z);
            Logger.log('Zero left for left ${newLeft.toString()}, up ${worldUpVector.toString()}');
        }
        if (rotation != null) 
		{
            rotation.fromAxes(newLeft, worldUpVector, direction);
        }
        vars.release();
    }

    /**
     * This is implemented from AbstractPhysicsControl and called when the
     * spatial is attached for example.
     *
     * @param vec
     */
	override function setPhysicsLocation(vec:Vector3f):Void 
	{
		rigidBody.setPhysicsLocation(vec);
        location.copyFrom(vec);
	}

    /**
     * This is implemented from AbstractPhysicsControl and called when the
     * spatial is attached for example. We don't set the actual physics rotation
     * but the view rotation here. It might actually be altered by the
     * calculateNewForward method.
     *
     * @param quat
     */
	override function setPhysicsRotation(quat:Quaternion):Void 
	{
		rotation.copyFrom(quat);
        rotation.multVecLocal(rotatedViewDirection.copyFrom(viewDirection));
        updateLocalViewDirection();
	}

    /**
     * This is implemented from AbstractPhysicsControl and called when the
     * control is supposed to add all objects to the physics space.
     *
     * @param space
     */
	override function addPhysics(space:PhysicsSpace):Void 
	{
		space.getGravity(localUp).normalizeLocal().negateLocal();
        updateLocalCoordinateSystem();

        space.addCollisionObject(rigidBody);
        space.addTickListener(this);
	}
	
	override function removePhysics(space:PhysicsSpace):Void 
	{
		space.removeCollisionObject(rigidBody);
        space.removeTickListener(this);
	}
	
	override function createSpatialData(spat:Spatial):Void 
	{
		rigidBody.setUserObject(spat);
	}
	
	override function removeSpatialData(spat:Spatial):Void 
	{
		rigidBody.setUserObject(null);
	}

    override public function cloneForSpatial(spatial:Spatial):Control
	{
        var control:BetterCharacterControl = new BetterCharacterControl(radius, height, mass);
        control.setJumpForce(jumpForce);
		control.setEnabled(isEnabled());
		control.setSpatial(spatial);
        return control;
    }
}