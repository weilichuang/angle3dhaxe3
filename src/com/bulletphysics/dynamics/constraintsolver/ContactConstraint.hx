package com.bulletphysics.dynamics.constraintsolver;
import com.bulletphysics.collision.narrowphase.ManifoldPoint;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.util.Assert;
import com.bulletphysics.util.ObjectPool;
import vecmath.Matrix3f;
import vecmath.Vector3f;

class SingleCollisionContactSolverFunc implements ContactSolverFunc
{
	public function new()
	{
		
	}
	
	public function resolveContact(body1:RigidBody, body2:RigidBody, contactPoint:ManifoldPoint, info:ContactSolverInfo):Float
	{
		return ContactConstraint.resolveSingleCollision(body1, body2, contactPoint, info);
	}
}

class SingleFrictionContactSolverFunc implements ContactSolverFunc
{
	public function new()
	{
		
	}
	
	public function resolveContact(body1:RigidBody, body2:RigidBody, contactPoint:ManifoldPoint, info:ContactSolverInfo):Float
	{
		return ContactConstraint.resolveSingleFriction(body1, body2, contactPoint, info);
	}
}

class SingleCollisionCombinedContactSolverFunc implements ContactSolverFunc
{
	public function new()
	{
		
	}
	
	public function resolveContact(body1:RigidBody, body2:RigidBody, contactPoint:ManifoldPoint, info:ContactSolverInfo):Float
	{
		return ContactConstraint.resolveSingleCollisionCombined(body1, body2, contactPoint, info);
	}
}

/**
 * Functions for resolving contacts.
 * @author weilichuang
 */
class ContactConstraint
{

	public static var _resolveSingleCollision:ContactSolverFunc = new SingleCollisionContactSolverFunc();

    public static var _resolveSingleFriction:ContactSolverFunc = new SingleFrictionContactSolverFunc();

    public static var _resolveSingleCollisionCombined:ContactSolverFunc = new SingleCollisionCombinedContactSolverFunc();

    /**
     * Bilateral constraint between two dynamic objects.
     */
    public static function resolveSingleBilateral(body1:RigidBody, pos1:Vector3f,
                                              body2:RigidBody, pos2:Vector3f,
                                              distance:Float, normal:Vector3f, impulse:Array<Float>, timeStep:Float):Void
    {
        var normalLenSqr:Float = normal.lengthSquared();
        Assert.assert (Math.abs(normalLenSqr) < 1.1);
        if (normalLenSqr > 1.1)
		{
            impulse[0] = 0;
            return;
        }

        var jacobiansPool:ObjectPool<JacobianEntry> = ObjectPool.getPool(JacobianEntry);
        var tmp:Vector3f = new Vector3f();

        var rel_pos1:Vector3f = new Vector3f();
        rel_pos1.sub2(pos1, body1.getCenterOfMassPosition(tmp));

        var rel_pos2:Vector3f = new Vector3f();
        rel_pos2.sub2(pos2, body2.getCenterOfMassPosition(tmp));

        //this jacobian entry could be re-used for all iterations

        var vel1:Vector3f = new Vector3f();
        body1.getVelocityInLocalPoint(rel_pos1, vel1);

        var vel2:Vector3f = new Vector3f();
        body2.getVelocityInLocalPoint(rel_pos2, vel2);

        var vel:Vector3f = new Vector3f();
        vel.sub2(vel1, vel2);

        var mat1:Matrix3f = body1.getCenterOfMassTransform(new Transform()).basis;
        mat1.transpose();

        var mat2:Matrix3f = body2.getCenterOfMassTransform(new Transform()).basis;
        mat2.transpose();

        var jac:JacobianEntry = jacobiansPool.get();
        jac.init(mat1, mat2,
                rel_pos1, rel_pos2, normal,
                body1.getInvInertiaDiagLocal(new Vector3f()), body1.getInvMass(),
                body2.getInvInertiaDiagLocal(new Vector3f()), body2.getInvMass());

        var jacDiagAB:Float = jac.getDiagonal();
        var jacDiagABInv:Float = 1 / jacDiagAB;

        var tmp1:Vector3f = body1.getAngularVelocity(new Vector3f());
        mat1.transform(tmp1);

        var tmp2:Vector3f = body2.getAngularVelocity(new Vector3f());
        mat2.transform(tmp2);

        var rel_vel:Float = jac.getRelativeVelocity(
                body1.getLinearVelocity(new Vector3f()),
                tmp1,
                body2.getLinearVelocity(new Vector3f()),
                tmp2);

        jacobiansPool.release(jac);

        var a:Float;
        a = jacDiagABInv;


        rel_vel = normal.dot(vel);

        // todo: move this into proper structure
        var contactDamping:Float = 0.2;

        //#ifdef ONLY_USE_LINEAR_MASS
        //	btScalar massTerm = btScalar(1.) / (body1.getInvMass() + body2.getInvMass());
        //	impulse = - contactDamping * rel_vel * massTerm;
        //#else
        var velocityImpulse:Float = -contactDamping * rel_vel * jacDiagABInv;
        impulse[0] = velocityImpulse;
        //#endif
    }

    /**
     * Response between two dynamic objects with friction.
     */
    public static function resolveSingleCollision(
             body1:RigidBody,
             body2:RigidBody,
             contactPoint:ManifoldPoint,
             solverInfo:ContactSolverInfo):Float
	{

        var tmpVec:Vector3f = new Vector3f();

        var pos1_:Vector3f = contactPoint.getPositionWorldOnA(new Vector3f());
        var pos2_:Vector3f = contactPoint.getPositionWorldOnB(new Vector3f());
        var normal:Vector3f = contactPoint.normalWorldOnB;

        // constant over all iterations
        var rel_pos1:Vector3f = new Vector3f();
        rel_pos1.sub2(pos1_, body1.getCenterOfMassPosition(tmpVec));

        var rel_pos2:Vector3f = new Vector3f();
        rel_pos2.sub2(pos2_, body2.getCenterOfMassPosition(tmpVec));

        var vel1:Vector3f = body1.getVelocityInLocalPoint(rel_pos1, new Vector3f());
        var vel2:Vector3f = body2.getVelocityInLocalPoint(rel_pos2, new Vector3f());
        var vel:Vector3f = new Vector3f();
        vel.sub2(vel1, vel2);

        var rel_vel:Float;
        rel_vel = normal.dot(vel);

        var Kfps:Float = 1 / solverInfo.timeStep;

        // btScalar damping = solverInfo.m_damping ;
        var Kerp:Float = solverInfo.erp;
        var Kcor:Float = Kerp * Kfps;

        var cpd:ConstraintPersistentData = cast contactPoint.userPersistentData;
        Assert.assert (cpd != null);
        var distance:Float = cpd.penetration;
        var positionalError:Float = Kcor * -distance;
        var velocityError:Float = cpd.restitution - rel_vel; // * damping;

        var penetrationImpulse:Float = positionalError * cpd.jacDiagABInv;

        var velocityImpulse:Float = velocityError * cpd.jacDiagABInv;

        var normalImpulse:Float = penetrationImpulse + velocityImpulse;

        // See Erin Catto's GDC 2006 paper: Clamp the accumulated impulse
        var oldNormalImpulse:Float = cpd.appliedImpulse;
        var sum:Float = oldNormalImpulse + normalImpulse;
        cpd.appliedImpulse = 0 > sum ? 0 : sum;

        normalImpulse = cpd.appliedImpulse - oldNormalImpulse;

        //#ifdef USE_INTERNAL_APPLY_IMPULSE
        var tmp:Vector3f = new Vector3f();
        if (body1.getInvMass() != 0) 
		{
            tmp.scale2(body1.getInvMass(), contactPoint.normalWorldOnB);
            body1.internalApplyImpulse(tmp, cpd.angularComponentA, normalImpulse);
        }
        if (body2.getInvMass() != 0) 
		{
            tmp.scale2(body2.getInvMass(), contactPoint.normalWorldOnB);
            body2.internalApplyImpulse(tmp, cpd.angularComponentB, -normalImpulse);
        }
        //#else //USE_INTERNAL_APPLY_IMPULSE
        //	body1.applyImpulse(normal*(normalImpulse), rel_pos1);
        //	body2.applyImpulse(-normal*(normalImpulse), rel_pos2);
        //#endif //USE_INTERNAL_APPLY_IMPULSE

        return normalImpulse;
    }

    public static function resolveSingleFriction(
								body1:RigidBody,
								 body2:RigidBody,
								 contactPoint:ManifoldPoint,
								 solverInfo:ContactSolverInfo):Float
	{

        var tmpVec:Vector3f = new Vector3f();

        var pos1:Vector3f = contactPoint.getPositionWorldOnA(new Vector3f());
        var pos2:Vector3f = contactPoint.getPositionWorldOnB(new Vector3f());

        var rel_pos1 :Vector3f= new Vector3f();
        rel_pos1.sub2(pos1, body1.getCenterOfMassPosition(tmpVec));

        var rel_pos2:Vector3f = new Vector3f();
        rel_pos2.sub2(pos2, body2.getCenterOfMassPosition(tmpVec));

        var cpd:ConstraintPersistentData = cast contactPoint.userPersistentData;
        Assert.assert (cpd != null);

        var combinedFriction:Float = cpd.friction;

        var limit:Float = cpd.appliedImpulse * combinedFriction;

        if (cpd.appliedImpulse > 0) //friction
        {
            //apply friction in the 2 tangential directions

            // 1st tangent
            var vel1:Vector3f = new Vector3f();
            body1.getVelocityInLocalPoint(rel_pos1, vel1);

            var vel2:Vector3f = new Vector3f();
            body2.getVelocityInLocalPoint(rel_pos2, vel2);

            var vel:Vector3f = new Vector3f();
            vel.sub2(vel1, vel2);

            var j1:Float, j2:Float;

            {
                var vrel:Float = cpd.frictionWorldTangential0.dot(vel);

                // calculate j that moves us to zero relative velocity
                j1 = -vrel * cpd.jacDiagABInvTangent0;
                var oldTangentImpulse:Float = cpd.accumulatedTangentImpulse0;
                cpd.accumulatedTangentImpulse0 = oldTangentImpulse + j1;

                cpd.accumulatedTangentImpulse0 = Math.min(cpd.accumulatedTangentImpulse0, limit);
                cpd.accumulatedTangentImpulse0 = Math.max(cpd.accumulatedTangentImpulse0, -limit);
                j1 = cpd.accumulatedTangentImpulse0 - oldTangentImpulse;
            }
            {
                // 2nd tangent

                var vrel:Float = cpd.frictionWorldTangential1.dot(vel);

                // calculate j that moves us to zero relative velocity
                j2 = -vrel * cpd.jacDiagABInvTangent1;
                var oldTangentImpulse:Float = cpd.accumulatedTangentImpulse1;
                cpd.accumulatedTangentImpulse1 = oldTangentImpulse + j2;

                cpd.accumulatedTangentImpulse1 = Math.min(cpd.accumulatedTangentImpulse1, limit);
                cpd.accumulatedTangentImpulse1 = Math.max(cpd.accumulatedTangentImpulse1, -limit);
                j2 = cpd.accumulatedTangentImpulse1 - oldTangentImpulse;
            }

            //#ifdef USE_INTERNAL_APPLY_IMPULSE
            var tmp:Vector3f = new Vector3f();

            if (body1.getInvMass() != 0)
			{
                tmp.scale2(body1.getInvMass(), cpd.frictionWorldTangential0);
                body1.internalApplyImpulse(tmp, cpd.frictionAngularComponent0A, j1);

                tmp.scale2(body1.getInvMass(), cpd.frictionWorldTangential1);
                body1.internalApplyImpulse(tmp, cpd.frictionAngularComponent1A, j2);
            }
            if (body2.getInvMass() != 0) 
			{
                tmp.scale2(body2.getInvMass(), cpd.frictionWorldTangential0);
                body2.internalApplyImpulse(tmp, cpd.frictionAngularComponent0B, -j1);

                tmp.scale2(body2.getInvMass(), cpd.frictionWorldTangential1);
                body2.internalApplyImpulse(tmp, cpd.frictionAngularComponent1B, -j2);
            }
            //#else //USE_INTERNAL_APPLY_IMPULSE
            //	body1.applyImpulse((j1 * cpd->m_frictionWorldTangential0)+(j2 * cpd->m_frictionWorldTangential1), rel_pos1);
            //	body2.applyImpulse((j1 * -cpd->m_frictionWorldTangential0)+(j2 * -cpd->m_frictionWorldTangential1), rel_pos2);
            //#endif //USE_INTERNAL_APPLY_IMPULSE
        }
        return cpd.appliedImpulse;
    }

    /**
     * velocity + friction<br>
     * response between two dynamic objects with friction
     */
    public static function resolveSingleCollisionCombined(
								body1:RigidBody,
								 body2:RigidBody,
								 contactPoint:ManifoldPoint,
								 solverInfo:ContactSolverInfo):Float
	{

        var tmpVec:Vector3f = new Vector3f();

        var pos1:Vector3f = contactPoint.getPositionWorldOnA(new Vector3f());
        var pos2:Vector3f = contactPoint.getPositionWorldOnB(new Vector3f());
        var normal:Vector3f = contactPoint.normalWorldOnB;

        var rel_pos1:Vector3f = new Vector3f();
        rel_pos1.sub2(pos1, body1.getCenterOfMassPosition(tmpVec));

        var rel_pos2:Vector3f = new Vector3f();
        rel_pos2.sub2(pos2, body2.getCenterOfMassPosition(tmpVec));

        var vel1:Vector3f = body1.getVelocityInLocalPoint(rel_pos1, new Vector3f());
        var vel2:Vector3f = body2.getVelocityInLocalPoint(rel_pos2, new Vector3f());
        var vel:Vector3f = new Vector3f();
        vel.sub2(vel1, vel2);

        var rel_vel:Float;
        rel_vel = normal.dot(vel);

        var Kfps:Float = 1 / solverInfo.timeStep;

        //btScalar damping = solverInfo.m_damping ;
        var Kerp:Float = solverInfo.erp;
        var Kcor:Float = Kerp * Kfps;

        var cpd:ConstraintPersistentData = cast contactPoint.userPersistentData;
        Assert.assert (cpd != null);
        var distance:Float = cpd.penetration;
        var positionalError:Float = Kcor * -distance;
        var velocityError:Float = cpd.restitution - rel_vel;// * damping;

        var penetrationImpulse:Float = positionalError * cpd.jacDiagABInv;

        var velocityImpulse:Float = velocityError * cpd.jacDiagABInv;

        var normalImpulse:Float = penetrationImpulse + velocityImpulse;

        // See Erin Catto's GDC 2006 paper: Clamp the accumulated impulse
        var oldNormalImpulse:Float = cpd.appliedImpulse;
        var sum:Float = oldNormalImpulse + normalImpulse;
        cpd.appliedImpulse = 0 > sum ? 0 : sum;

        normalImpulse = cpd.appliedImpulse - oldNormalImpulse;


        //#ifdef USE_INTERNAL_APPLY_IMPULSE
        var tmp:Vector3f = new Vector3f();
        if (body1.getInvMass() != 0) 
		{
            tmp.scale2(body1.getInvMass(), contactPoint.normalWorldOnB);
            body1.internalApplyImpulse(tmp, cpd.angularComponentA, normalImpulse);
        }
        if (body2.getInvMass() != 0) 
		{
            tmp.scale2(body2.getInvMass(), contactPoint.normalWorldOnB);
            body2.internalApplyImpulse(tmp, cpd.angularComponentB, -normalImpulse);
        }
        //#else //USE_INTERNAL_APPLY_IMPULSE
        //	body1.applyImpulse(normal*(normalImpulse), rel_pos1);
        //	body2.applyImpulse(-normal*(normalImpulse), rel_pos2);
        //#endif //USE_INTERNAL_APPLY_IMPULSE

        {
            //friction
            body1.getVelocityInLocalPoint(rel_pos1, vel1);
            body2.getVelocityInLocalPoint(rel_pos2, vel2);
            vel.sub2(vel1, vel2);

            rel_vel = normal.dot(vel);

            tmp.scale2(rel_vel, normal);
            var lat_vel:Vector3f = new Vector3f();
            lat_vel.sub2(vel, tmp);
            var lat_rel_vel:Float = lat_vel.length();

            var combinedFriction:Float = cpd.friction;

            if (cpd.appliedImpulse > 0) {
                if (lat_rel_vel > BulletGlobals.FLT_EPSILON) {
                    lat_vel.scale(1 / lat_rel_vel);

                    var temp1:Vector3f = new Vector3f();
                    temp1.cross(rel_pos1, lat_vel);
                    body1.getInvInertiaTensorWorld(new Matrix3f()).transform(temp1);

                    var temp2:Vector3f = new Vector3f();
                    temp2.cross(rel_pos2, lat_vel);
                    body2.getInvInertiaTensorWorld(new Matrix3f()).transform(temp2);

                    var java_tmp1:Vector3f = new Vector3f();
                    java_tmp1.cross(temp1, rel_pos1);

                    var java_tmp2:Vector3f = new Vector3f();
                    java_tmp2.cross(temp2, rel_pos2);

                    tmp.add2(java_tmp1, java_tmp2);

                    var friction_impulse:Float = lat_rel_vel /
                            (body1.getInvMass() + body2.getInvMass() + lat_vel.dot(tmp));
                    var normal_impulse:Float = cpd.appliedImpulse * combinedFriction;

                    friction_impulse = Math.min(friction_impulse, normal_impulse);
                    friction_impulse = Math.max(friction_impulse, -normal_impulse);

                    tmp.scale2(-friction_impulse, lat_vel);
                    body1.applyImpulse(tmp, rel_pos1);

                    tmp.scale2(friction_impulse, lat_vel);
                    body2.applyImpulse(tmp, rel_pos2);
                }
            }
        }

        return normalImpulse;
    }

    public static function resolveSingleFrictionEmpty(
								body1:RigidBody,
								 body2:RigidBody,
								 contactPoint:ManifoldPoint,
								 solverInfo:ContactSolverInfo):Float
	{
        return 0;
    }
	
}