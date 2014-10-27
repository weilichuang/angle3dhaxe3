package com.bulletphysics.dynamics.character;
import com.bulletphysics.collision.broadphase.BroadphasePair;
import com.bulletphysics.collision.dispatch.CollisionObject;
import com.bulletphysics.collision.dispatch.CollisionWorld;
import com.bulletphysics.collision.dispatch.CollisionWorld.ClosestConvexResultCallback;
import com.bulletphysics.collision.dispatch.CollisionWorld.ClosestRayResultCallback;
import com.bulletphysics.collision.dispatch.CollisionWorld.LocalConvexResult;
import com.bulletphysics.collision.dispatch.CollisionWorld.LocalRayResult;
import com.bulletphysics.collision.dispatch.PairCachingGhostObject;
import com.bulletphysics.collision.narrowphase.ManifoldPoint;
import com.bulletphysics.collision.narrowphase.PersistentManifold;
import com.bulletphysics.collision.shapes.ConvexShape;
import com.bulletphysics.linearmath.IDebugDraw;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.util.ObjectArrayList;
import vecmath.Vector3f;

/**
 * KinematicCharacterController is an object that supports a sliding motion in
 * a world. It uses a {@link GhostObject} and convex sweep test to test for upcoming
 * collisions. This is combined with discrete collision detection to recover
 * from penetrations.<p>
 * <p/>
 * Interaction between KinematicCharacterController and dynamic rigid bodies
 * needs to be explicity implemented by the user.
 * @author weilichuang
 */
class KinematicCharacterController implements ActionInterface
{

	private static var upAxisDirection:Array<Vector3f> = [
													new Vector3f(1.0, 0.0, 0.0),
													new Vector3f(0.0, 1.0, 0.0),
													new Vector3f(0.0, 0.0, 1.0)];

    private var halfHeight:Float;

    private var ghostObject:PairCachingGhostObject;

    // is also in ghostObject, but it needs to be convex, so we store it here
    // to avoid upcast
    private var convexShape:ConvexShape;

    private var verticalVelocity:Float;
    private var verticalOffset:Float;

    private var fallSpeed:Float;
    private var jumpSpeed:Float;
    private var maxJumpHeight:Float;

    private var maxSlopeRadians:Float; // Slope angle that is set (used for returning the exact value)
    private var maxSlopeCosine:Float; // Cosine equivalent of m_maxSlopeRadians (calculated once when set, for optimization)

    private var gravity:Float;

    private var turnAngle:Float;

    private var stepHeight:Float;

    private var addedMargin:Float; // @todo: remove this and fix the code

    // this is the desired walk direction, set by the user
    private var walkDirection:Vector3f = new Vector3f();
    private var normalizedDirection:Vector3f = new Vector3f();

    // some internal variables
    private var currentPosition:Vector3f = new Vector3f();
    private var currentStepOffset:Float;
    private var targetPosition:Vector3f = new Vector3f();

    // keep track of the contact manifolds
    private var manifoldArray:ObjectArrayList<PersistentManifold> = new ObjectArrayList<PersistentManifold>();

    private var touchingContact:Bool;
    private var touchingNormal:Vector3f = new Vector3f();

    private var wasOnGround:Bool;

    private var useGhostObjectSweepTest:Bool;
    private var useWalkDirection:Bool;
    private var velocityTimeInterval:Float;
    private var upAxis:Int;

    private var me:CollisionObject;

    public function new(ghostObject:PairCachingGhostObject, convexShape:ConvexShape, stepHeight:Float, upAxis:Int = 1)
	{
        this.upAxis = upAxis;
        this.addedMargin = 0.02;
        this.walkDirection.setTo(0, 0, 0);
        this.useGhostObjectSweepTest = true;
        this.ghostObject = ghostObject;
        this.stepHeight = stepHeight;
        this.turnAngle = 0.0;
        this.convexShape = convexShape;
        this.useWalkDirection = true;
        this.velocityTimeInterval = 0.0;
        this.verticalVelocity = 0.0;
        this.verticalOffset = 0.0;
        this.gravity = 9.8; // 1G acceleration
        this.fallSpeed = 55.0; // Terminal velocity of a sky diver in m/s.
        this.jumpSpeed = 10.0; // ?
        this.wasOnGround = false;
        setMaxSlope((50.0 / 180.0) * Math.PI);
    }

    private function getGhostObject():PairCachingGhostObject
	{
        return ghostObject;
    }

    // ActionInterface interface
    public function updateAction(collisionWorld:CollisionWorld, deltaTime:Float):Void
	{
        preStep(collisionWorld);
        playerStep(collisionWorld, deltaTime);
    }

    // ActionInterface interface
    public function debugDraw(debugDrawer:IDebugDraw):Void
	{
    }

    public function setUpAxis(axis:Int):Void
	{
        if (axis < 0) 
		{
            axis = 0;
        }
        if (axis > 2)
		{
            axis = 2;
        }
        upAxis = axis;
    }

    /**
     * This should probably be called setPositionIncrementPerSimulatorStep. This
     * is neither a direction nor a velocity, but the amount to increment the
     * position each simulation iteration, regardless of dt.<p>
     * <p/>
     * This call will reset any velocity set by {@link #setVelocityForTimeInterval}.
     */
    public function setWalkDirection(walkDirection:Vector3f):Void
	{
        useWalkDirection = true;
        this.walkDirection.fromVector3f(walkDirection);
        normalizedDirection.fromVector3f(getNormalizedVector(walkDirection, new Vector3f()));
    }

    /**
     * Caller provides a velocity with which the character should move for the
     * given time period. After the time period, velocity is reset to zero.
     * This call will reset any walk direction set by {@link #setWalkDirection}.
     * Negative time intervals will result in no motion.
     */
    public function setVelocityForTimeInterval(velocity:Vector3f, timeInterval:Float):Void
	{
        useWalkDirection = false;
        walkDirection.fromVector3f(velocity);
        normalizedDirection.fromVector3f(getNormalizedVector(walkDirection, new Vector3f()));
        velocityTimeInterval = timeInterval;
    }

    public function reset():Void
	{
    }

    public function warp(origin:Vector3f):Void
	{
        var xform:Transform = new Transform();
        xform.setIdentity();
        xform.origin.fromVector3f(origin);
        ghostObject.setWorldTransform(xform);
    }

    public function preStep(collisionWorld:CollisionWorld):Void
	{
        var numPenetrationLoops:Int = 0;
        touchingContact = false;
        while (recoverFromPenetration(collisionWorld))
		{
            numPenetrationLoops++;
            touchingContact = true;
            if (numPenetrationLoops > 4)
			{
                //printf("character could not recover from penetration = %d\n", numPenetrationLoops);
                break;
            }
        }

        currentPosition.fromVector3f(ghostObject.getWorldTransform().origin);
        targetPosition.fromVector3f(currentPosition);
        //printf("m_targetPosition=%f,%f,%f\n",m_targetPosition[0],m_targetPosition[1],m_targetPosition[2]);
    }

    public function playerStep(collisionWorld:CollisionWorld, dt:Float):Void
	{
        //printf("playerStep(): ");
        //printf("  dt = %f", dt);

        // quick check...
        if (!useWalkDirection && velocityTimeInterval <= 0.0)
		{
            //printf("\n");
            return; // no motion
        }

        wasOnGround = onGround();

        // Update fall velocity.
        verticalVelocity -= gravity * dt;
        if (verticalVelocity > 0.0 && verticalVelocity > jumpSpeed) 
		{
            verticalVelocity = jumpSpeed;
        }
        if (verticalVelocity < 0.0 && Math.abs(verticalVelocity) > Math.abs(fallSpeed)) 
		{
            verticalVelocity = -Math.abs(fallSpeed);
        }
        verticalOffset = verticalVelocity * dt;

        var xform:Transform = ghostObject.getWorldTransformTo(new Transform());

        //printf("walkDirection(%f,%f,%f)\n",walkDirection[0],walkDirection[1],walkDirection[2]);
        //printf("walkSpeed=%f\n",walkSpeed);

        stepUp(collisionWorld);
        if (useWalkDirection) 
		{
            //System.out.println("playerStep 3");
            stepForwardAndStrafe(collisionWorld, walkDirection);
        } 
		else
		{
            trace("playerStep 4");
            //printf("  time: %f", m_velocityTimeInterval);

            // still have some time left for moving!
            var dtMoving:Float = (dt < velocityTimeInterval) ? dt : velocityTimeInterval;
            velocityTimeInterval -= dt;

            // how far will we move while we are moving?
            var move:Vector3f = new Vector3f();
            move.scale2(dtMoving, walkDirection);

            //printf("  dtMoving: %f", dtMoving);

            // okay, step
            stepForwardAndStrafe(collisionWorld, move);
        }
        stepDown(collisionWorld, dt);

        //printf("\n");

        xform.origin.fromVector3f(currentPosition);
        ghostObject.setWorldTransform(xform);
    }

    public function setFallSpeed(fallSpeed:Float):Void
	{
        this.fallSpeed = fallSpeed;
    }

    public function setJumpSpeed(jumpSpeed:Float):Void
	{
        this.jumpSpeed = jumpSpeed;
    }

    public function setMaxJumpHeight(maxJumpHeight:Float):Void
	{
        this.maxJumpHeight = maxJumpHeight;
    }

    public function canJump():Bool
	{
        return onGround();
    }

    public function jump():Void
	{
        if (!canJump()) 
			return;

        verticalVelocity = jumpSpeed;

        //#if 0
        //currently no jumping.
        //btTransform xform;
        //m_rigidBody->getMotionState()->getWorldTransform (xform);
        //btVector3 up = xform.getBasis()[1];
        //up.normalize ();
        //btScalar magnitude = (btScalar(1.0)/m_rigidBody->getInvMass()) * btScalar(8.0);
        //m_rigidBody->applyCentralImpulse (up * magnitude);
        //#endif
    }

    public function setGravity(gravity:Float):Void
	{
        this.gravity = gravity;
    }

    public function getGravity():Float
	{
        return gravity;
    }

    public function setMaxSlope(slopeRadians:Float):Void
	{
        maxSlopeRadians = slopeRadians;
        maxSlopeCosine =  Math.cos(slopeRadians);
    }

    public function getMaxSlope():Float
	{
        return maxSlopeRadians;
    }

    public function onGround():Bool
	{
        return verticalVelocity == 0.0 && verticalOffset == 0.0;
    }

    // static helper method
    private static function getNormalizedVector(v:Vector3f, out:Vector3f):Vector3f
	{
        out.fromVector3f(v);
        out.normalize();
        if (out.length() < BulletGlobals.SIMD_EPSILON)
		{
            out.setTo(0, 0, 0);
        }
        return out;
    }

    /**
     * Returns the reflection direction of a ray going 'direction' hitting a surface
     * with normal 'normal'.<p>
     * <p/>
     * From: http://www-cs-students.stanford.edu/~adityagp/final/node3.html
     */
    private function computeReflectionDirection(direction:Vector3f, normal:Vector3f, out:Vector3f):Vector3f
	{
        // return direction - (btScalar(2.0) * direction.dot(normal)) * normal;
        out.fromVector3f(normal);
        out.scale(-2.0 * direction.dot(normal));
        out.add(direction);
        return out;
    }

    /**
     * Returns the portion of 'direction' that is parallel to 'normal'
     */
    private function parallelComponent(direction:Vector3f, normal:Vector3f, out:Vector3f):Vector3f
	{
        //btScalar magnitude = direction.dot(normal);
        //return normal * magnitude;
        out.fromVector3f(normal);
        out.scale(direction.dot(normal));
        return out;
    }

    /**
     * Returns the portion of 'direction' that is perpindicular to 'normal'
     */
    private function perpindicularComponent(direction:Vector3f, normal:Vector3f, out:Vector3f):Vector3f
	{
        //return direction - parallelComponent(direction, normal);
        var perpendicular:Vector3f = parallelComponent(direction, normal, out);
        perpendicular.scale(-1);
        perpendicular.add(direction);
        return perpendicular;
    }

    private function recoverFromPenetration(collisionWorld:CollisionWorld):Bool
	{
        var penetration:Bool = false;

        collisionWorld.getDispatcher().dispatchAllCollisionPairs(
                ghostObject.getOverlappingPairCache(), collisionWorld.getDispatchInfo(), collisionWorld.getDispatcher());

        currentPosition.fromVector3f(ghostObject.getWorldTransform().origin);

        var maxPen:Float = 0.0;
        for (i in 0...ghostObject.getOverlappingPairCache().getNumOverlappingPairs())
		{
            manifoldArray.clear();

            var collisionPair:BroadphasePair = ghostObject.getOverlappingPairCache().getOverlappingPairArray().getQuick(i);

            if (collisionPair.algorithm != null)
			{
                collisionPair.algorithm.getAllContactManifolds(manifoldArray);
            }

            for (j in 0...manifoldArray.size())
			{
                var manifold:PersistentManifold = manifoldArray.getQuick(j);
                var directionSign:Float = manifold.getBody0() == ghostObject ? -1.0 : 1.0;
                for (p in 0...manifold.getNumContacts())
				{
                    var pt:ManifoldPoint = manifold.getContactPoint(p);

                    var dist:Float = pt.getDistance();
                    if (dist < 0.0)
					{
                        if (dist < maxPen)
						{
                            maxPen = dist;
                            touchingNormal.fromVector3f(pt.normalWorldOnB);//??
                            touchingNormal.scale(directionSign);
                        }

                        currentPosition.scaleAdd(directionSign * dist * 0.2, pt.normalWorldOnB, currentPosition);

                        penetration = true;
                    } 
					else
					{
                        //printf("touching %f\n", dist);
                    }
                }

                //manifold->clearManifold();
            }
        }

        var newTrans:Transform = ghostObject.getWorldTransformTo(new Transform());
        newTrans.origin.fromVector3f(currentPosition);
        ghostObject.setWorldTransform(newTrans);
        //printf("m_touchingNormal = %f,%f,%f\n",m_touchingNormal[0],m_touchingNormal[1],m_touchingNormal[2]);

        //System.out.println("recoverFromPenetration "+penetration+" "+touchingNormal);

        return penetration;
    }

    private function stepUp(world:CollisionWorld):Void
	{
        // phase 1: up
        var start:Transform = new Transform();
        var end:Transform = new Transform();
        targetPosition.scaleAdd(stepHeight + (verticalOffset > 0.0 ? verticalOffset : 0.0), upAxisDirection[upAxis], currentPosition);

        start.setIdentity();
        end.setIdentity();

		/* FIXME: Handle penetration properly */
        start.origin.scaleAdd(convexShape.getMargin() + addedMargin, upAxisDirection[upAxis], currentPosition);
        end.origin.fromVector3f(targetPosition);

        // Find only sloped/flat surface hits, avoid wall and ceiling hits...
        var up:Vector3f = new Vector3f();
        up.scale2(-1, upAxisDirection[upAxis]);
        var callback:KinematicClosestNotMeConvexResultCallback = new KinematicClosestNotMeConvexResultCallback(ghostObject, up, 0.0);
        callback.collisionFilterGroup = getGhostObject().getBroadphaseHandle().collisionFilterGroup;
        callback.collisionFilterMask = getGhostObject().getBroadphaseHandle().collisionFilterMask;

        if (useGhostObjectSweepTest)
		{
            ghostObject.convexSweepTest(convexShape, start, end, callback, world.getDispatchInfo().allowedCcdPenetration);
        } 
		else 
		{
            world.convexSweepTest(convexShape, start, end, callback);
        }

        if (callback.hasHit())
		{
            // we moved up only a fraction of the step height
            currentStepOffset = stepHeight * callback.closestHitFraction;
            currentPosition.interpolate(currentPosition, targetPosition, callback.closestHitFraction);
            verticalVelocity = 0.0;
            verticalOffset = 0.0;
        } 
		else
		{
            currentStepOffset = stepHeight;
            currentPosition.fromVector3f(targetPosition);
        }
    }

    private function updateTargetPositionBasedOnCollision(hitNormal:Vector3f, ?tangentMag:Float = 0, ?normalMag:Float = 1):Void
	{
        var movementDirection:Vector3f = new Vector3f();
        movementDirection.sub2(targetPosition, currentPosition);
        var movementLength:Float = movementDirection.length();
        if (movementLength > BulletGlobals.SIMD_EPSILON) 
		{
            movementDirection.normalize();

            var reflectDir:Vector3f = computeReflectionDirection(movementDirection, hitNormal, new Vector3f());
            reflectDir.normalize();

            var parallelDir:Vector3f = parallelComponent(reflectDir, hitNormal, new Vector3f());
            var perpindicularDir = perpindicularComponent(reflectDir, hitNormal, new Vector3f());

            targetPosition.fromVector3f(currentPosition);
            if (false) //tangentMag != 0.0)
            {
                var parComponent:Vector3f = new Vector3f();
                parComponent.scale2(tangentMag * movementLength, parallelDir);
                //printf("parComponent=%f,%f,%f\n",parComponent[0],parComponent[1],parComponent[2]);
                targetPosition.add(parComponent);
            }

            if (normalMag != 0.0)
			{
                var perpComponent:Vector3f = new Vector3f();
                perpComponent.scale2(normalMag * movementLength, perpindicularDir);
                //printf("perpComponent=%f,%f,%f\n",perpComponent[0],perpComponent[1],perpComponent[2]);
                targetPosition.add(perpComponent);
            }
        }
		else
		{
            //printf("movementLength don't normalize a zero vector\n");
        }
    }

    private function stepForwardAndStrafe(collisionWorld:CollisionWorld, walkMove:Vector3f):Void
	{
        // printf("m_normalizedDirection=%f,%f,%f\n",
        // 	m_normalizedDirection[0],m_normalizedDirection[1],m_normalizedDirection[2]);
        // phase 2: forward and strafe
        var start:Transform = new Transform();
        var end:Transform = new Transform();
        targetPosition.add2(currentPosition, walkMove);
        start.setIdentity();
        end.setIdentity();

        var fraction:Float = 1.0;
        var distance2Vec:Vector3f = new Vector3f();
        distance2Vec.sub2(currentPosition, targetPosition);
        var distance2:Float = distance2Vec.lengthSquared();
        //printf("distance2=%f\n",distance2);

		/*if (touchingContact) {
            if (normalizedDirection.dot(touchingNormal) > 0.0f) {
				updateTargetPositionBasedOnCollision(touchingNormal);
			}
		}*/

        var maxIter:Int = 10;

        while (fraction > 0.01 && maxIter-- > 0) 
		{
            start.origin.fromVector3f(currentPosition);
            end.origin.fromVector3f(targetPosition);

            var callback:KinematicClosestNotMeConvexResultCallback = new KinematicClosestNotMeConvexResultCallback(ghostObject, upAxisDirection[upAxis], -1.0);
            callback.collisionFilterGroup = getGhostObject().getBroadphaseHandle().collisionFilterGroup;
            callback.collisionFilterMask = getGhostObject().getBroadphaseHandle().collisionFilterMask;

            var margin:Float = convexShape.getMargin();
            convexShape.setMargin(margin + addedMargin);

            if (useGhostObjectSweepTest) 
			{
                ghostObject.convexSweepTest(convexShape, start, end, callback, collisionWorld.getDispatchInfo().allowedCcdPenetration);
            }
			else
			{
                collisionWorld.convexSweepTest(convexShape, start, end, callback);
            }

            convexShape.setMargin(margin);

            fraction -= callback.closestHitFraction;

            if (callback.hasHit())
			{
                // we moved only a fraction
                var hitDistanceVec:Vector3f = new Vector3f();
                hitDistanceVec.sub2(callback.hitPointWorld, currentPosition);
                //float hitDistance = hitDistanceVec.length();

                // if the distance is farther than the collision margin, move
                //if (hitDistance > addedMargin) {
                //	//printf("callback.m_closestHitFraction=%f\n",callback.m_closestHitFraction);
                //	currentPosition.interpolate(currentPosition, targetPosition, callback.closestHitFraction);
                //}

                updateTargetPositionBasedOnCollision(callback.hitNormalWorld);

                var currentDir:Vector3f = new Vector3f();
                currentDir.sub2(targetPosition, currentPosition);
                distance2 = currentDir.lengthSquared();
                if (distance2 > BulletGlobals.SIMD_EPSILON) 
				{
                    currentDir.normalize();
                    // see Quake2: "If velocity is against original velocity, stop ead to avoid tiny oscilations in sloping corners."
                    if (currentDir.dot(normalizedDirection) <= 0.0)
					{
                        break;
                    }
                }
				else 
				{
                    //printf("currentDir: don't normalize a zero vector\n");
                    break;
                }
            } 
			else
			{
                // we moved whole way
                currentPosition.fromVector3f(targetPosition);
            }

            //if (callback.m_closestHitFraction == 0.f)
            //    break;
        }
    }

    private function stepDown(collisionWorld:CollisionWorld, dt:Float):Void
	{
        var start:Transform = new Transform();
        var end:Transform = new Transform();

        // phase 3: down
        var additionalDownStep:Float = (wasOnGround /*&& !onGround()*/) ? stepHeight : 0.0;
        var step_drop:Vector3f = new Vector3f();
        step_drop.scale2(currentStepOffset + additionalDownStep, upAxisDirection[upAxis]);
        var downVelocity:Float = (additionalDownStep == 0.0 && verticalVelocity < 0.0 ? -verticalVelocity : 0.0) * dt;
        var gravity_drop:Vector3f = new Vector3f();
        gravity_drop.scale2(downVelocity, upAxisDirection[upAxis]);
        targetPosition.sub(step_drop);
        targetPosition.sub(gravity_drop);

        start.setIdentity();
        end.setIdentity();

        start.origin.fromVector3f(currentPosition);
        end.origin.fromVector3f(targetPosition);

        var callback:KinematicClosestNotMeConvexResultCallback = new KinematicClosestNotMeConvexResultCallback(ghostObject, upAxisDirection[upAxis], maxSlopeCosine);
        callback.collisionFilterGroup = getGhostObject().getBroadphaseHandle().collisionFilterGroup;
        callback.collisionFilterMask = getGhostObject().getBroadphaseHandle().collisionFilterMask;

        if (useGhostObjectSweepTest) 
		{
            ghostObject.convexSweepTest(convexShape, start, end, callback, collisionWorld.getDispatchInfo().allowedCcdPenetration);
        } 
		else 
		{
            collisionWorld.convexSweepTest(convexShape, start, end, callback);
        }

        if (callback.hasHit()) 
		{
            // we dropped a fraction of the height -> hit floor
            currentPosition.interpolate(currentPosition, targetPosition, callback.closestHitFraction);
            verticalVelocity = 0.0;
            verticalOffset = 0.0;
        } 
		else 
		{
            // we dropped the full height
            currentPosition.fromVector3f(targetPosition);
        }
    }
}


class KinematicClosestNotMeRayResultCallback extends ClosestRayResultCallback
{
	private var me:CollisionObject;

	public function new( me:CollisionObject)
	{
		super(new Vector3f(), new Vector3f());
		this.me = me;
	}
	
	override public function addSingleResult(rayResult:LocalRayResult, normalInWorldSpace:Bool):Float 
	{
		if (rayResult.collisionObject == me)
		{
			return 1.0;
		}
		return super.addSingleResult(rayResult, normalInWorldSpace);
	}
}

class KinematicClosestNotMeConvexResultCallback extends ClosestConvexResultCallback 
{
	private var me:CollisionObject;
	private var up:Vector3f;
	private var minSlopeDot:Float;

	public function new( me:CollisionObject,  up:Vector3f, minSlopeDot:Float)
	{
		super(new Vector3f(), new Vector3f());
		this.me = me;
		this.up = up;
		this.minSlopeDot = minSlopeDot;
	}
	
	override public function addSingleResult(convexResult:LocalConvexResult, normalInWorldSpace:Bool):Float 
	{
		if (convexResult.hitCollisionObject == me)
		{
			return 1.0;
		}

		var hitNormalWorld:Vector3f;
		if (normalInWorldSpace)
		{
			hitNormalWorld = convexResult.hitNormalLocal;
		}
		else
		{
			//need to transform normal into worldspace
			hitNormalWorld = new Vector3f();
			hitCollisionObject.getWorldTransform().basis.transform(convexResult.hitNormalLocal, hitNormalWorld);
		}

		var dotUp:Float = up.dot(hitNormalWorld);
		if (dotUp < minSlopeDot)
		{
			return 1.0;
		}

		return super.addSingleResult(convexResult, normalInWorldSpace);
	}
}