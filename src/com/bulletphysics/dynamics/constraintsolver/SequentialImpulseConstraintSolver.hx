package com.bulletphysics.dynamics.constraintsolver;
import com.bulletphysics.collision.broadphase.Dispatcher;
import com.bulletphysics.collision.dispatch.CollisionObject;
import com.bulletphysics.collision.narrowphase.ManifoldPoint;
import com.bulletphysics.collision.narrowphase.PersistentManifold;
import com.bulletphysics.dynamics.constraintsolver.ContactSolverInfo;
import com.bulletphysics.dynamics.constraintsolver.TypedConstraint;
import com.bulletphysics.dynamics.RigidBody;
import com.bulletphysics.linearmath.IDebugDraw;
import com.bulletphysics.linearmath.MiscUtil;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.linearmath.TransformUtil;
import com.bulletphysics.util.IntArrayList;
import com.bulletphysics.util.ObjectArrayList;
import com.bulletphysics.util.ObjectPool;
import de.polygonal.ds.error.Assert;
import flash.Vector;
import org.angle3d.math.FastMath;
import com.vecmath.Matrix3f;
import org.angle3d.math.Vector3f;

/**
 * SequentialImpulseConstraintSolver uses a Propagation Method and Sequentially applies impulses.
 * The approach is the 3D version of Erin Catto's GDC 2006 tutorial. See http://www.gphysics.com<p>
 * <p/>
 * Although Sequential Impulse is more intuitive, it is mathematically equivalent to Projected
 * Successive Overrelaxation (iterative LCP).<p>
 * <p/>
 * Applies impulses for combined restitution and penetration recovery and to simulate friction.
 * @author weilichuang
 */
class SequentialImpulseConstraintSolver implements ConstraintSolver
{

	private static var MAX_CONTACT_SOLVER_TYPES = Type.enumIndex(ContactConstraintEnum.MAX_CONTACT_SOLVER_TYPES);

    private static inline var SEQUENTIAL_IMPULSE_MAX_SOLVER_POINTS:Int = 16384;

    private var gOrder:Vector<OrderIndex> = new Vector<OrderIndex>(SEQUENTIAL_IMPULSE_MAX_SOLVER_POINTS);

    ////////////////////////////////////////////////////////////////////////////

    private var bodiesPool:ObjectPool<SolverBody> = ObjectPool.getPool(SolverBody);
    private var constraintsPool:ObjectPool<SolverConstraint> = ObjectPool.getPool(SolverConstraint);
    private var jacobiansPool:ObjectPool<JacobianEntry> = ObjectPool.getPool(JacobianEntry);

    private var tmpSolverBodyPool:ObjectArrayList<SolverBody> = new ObjectArrayList<SolverBody>();
    private var tmpSolverConstraintPool:ObjectArrayList<SolverConstraint> = new ObjectArrayList<SolverConstraint>();
    private var tmpSolverFrictionConstraintPool:ObjectArrayList<SolverConstraint> = new ObjectArrayList<SolverConstraint>();
    private var orderTmpConstraintPool:IntArrayList = new IntArrayList();
    private var orderFrictionConstraintPool:IntArrayList = new IntArrayList();

    private var contactDispatch:Array<Array<ContactSolverFunc>> = new Array<Array<ContactSolverFunc>>();
    private var frictionDispatch:Array<Array<ContactSolverFunc>> = new Array<Array<ContactSolverFunc>>();

    // btSeed2 is used for re-arranging the constraint rows. improves convergence/quality of friction
    private var btSeed2:Int = 0;

    public function new()
	{
		for (i in 0...gOrder.length)
		{
            gOrder[i] = new OrderIndex();
        }
		
        //BulletGlobals.setContactDestroyedCallback(new CustomContactDestroyedCallback(this));

        // initialize default friction/contact funcs
        for (i in 0...MAX_CONTACT_SOLVER_TYPES) 
		{
			contactDispatch[i] = new Array<ContactSolverFunc>();
			frictionDispatch[i] = new Array<ContactSolverFunc>();
            for (j in 0...MAX_CONTACT_SOLVER_TYPES) 
			{
                contactDispatch[i][j] = ContactConstraint._resolveSingleCollision;
                frictionDispatch[i][j] = ContactConstraint._resolveSingleFriction;
            }
        }
    }
	
	public function prepareSolve(numBodies:Int, numManifolds:Int):Void
	{
		
	}
	
	public function allSolved(info:ContactSolverInfo, debugDrawer:IDebugDraw):Void
	{
		
	}

    public inline function rand2():Int
	{
        btSeed2 = (1664525 * btSeed2 + 1013904223) & 0xffffffff;
        return btSeed2;
    }

    // See ODE: adam's all-int straightforward(?) dRandInt (0..n-1)
    public inline function randInt2(n:Int):Int
	{
        // seems good; xor-fold and modulus
        var r:Int = rand2();

        // note: probably more aggressive than it needs to be -- might be
        //       able to get away without one or two of the innermost branches.
        if (n <= 0x00010000)
		{
            r ^= (r >>> 16);
            if (n <= 0x00000100)
			{
                r ^= (r >>> 8);
                if (n <= 0x00000010)
				{
                    r ^= (r >>> 4);
                    if (n <= 0x00000004)
					{
                        r ^= (r >>> 2);
                        if (n <= 0x00000002)
						{
                            r ^= (r >>> 1);
                        }
                    }
                }
            }
        }

        // TODO: check modulo C vs Java mismatch
        return FastMath.absInt(r % n);
    }

    private inline function initSolverBody(solverBody:SolverBody, collisionObject:CollisionObject):Void
	{
        var rb:RigidBody = RigidBody.upcast(collisionObject);
        if (rb != null) 
		{
            rb.getAngularVelocityTo(solverBody.angularVelocity);
            solverBody.centerOfMassPosition.copyFrom(collisionObject.getWorldTransform().origin);
            solverBody.friction = collisionObject.getFriction();
            solverBody.invMass = rb.getInvMass();
            rb.getLinearVelocity(solverBody.linearVelocity);
            solverBody.originalBody = rb;
            solverBody.angularFactor = rb.getAngularFactor();
        } 
		else
		{
            solverBody.angularVelocity.setTo(0, 0, 0);
            solverBody.centerOfMassPosition.copyFrom(collisionObject.getWorldTransform().origin);
            solverBody.friction = collisionObject.getFriction();
            solverBody.invMass = 0;
            solverBody.linearVelocity.setTo(0, 0, 0);
            solverBody.originalBody = null;
            solverBody.angularFactor = 1;
        }

        solverBody.pushVelocity.setTo(0, 0, 0);
        solverBody.turnVelocity.setTo(0, 0, 0);
    }

    private inline function restitutionCurve(rel_vel:Float, restitution:Float):Float
	{
        return restitution * -rel_vel;
    }

    private function resolveSplitPenetrationImpulseCacheFriendly(
            body1:SolverBody,
            body2:SolverBody,
            contactConstraint:SolverConstraint,
            solverInfo:ContactSolverInfo):Void
	{

        if (contactConstraint.penetration < solverInfo.splitImpulsePenetrationThreshold)
		{
            BulletStats.gNumSplitImpulseRecoveries++;
            var normalImpulse:Float;

            //  Optimized version of projected relative velocity, use precomputed cross products with normal
            //      body1.getVelocityInLocalPoint(contactConstraint.m_rel_posA,vel1);
            //      body2.getVelocityInLocalPoint(contactConstraint.m_rel_posB,vel2);
            //      btVector3 vel = vel1 - vel2;
            //      btScalar  rel_vel = contactConstraint.m_contactNormal.dot(vel);

            var rel_vel:Float;
            var vel1Dotn:Float = contactConstraint.contactNormal.dot(body1.pushVelocity) + contactConstraint.relpos1CrossNormal.dot(body1.turnVelocity);
            var vel2Dotn:Float = contactConstraint.contactNormal.dot(body2.pushVelocity) + contactConstraint.relpos2CrossNormal.dot(body2.turnVelocity);

            rel_vel = vel1Dotn - vel2Dotn;

            var positionalError:Float = -contactConstraint.penetration * solverInfo.erp2 / solverInfo.timeStep;
            //      btScalar positionalError = contactConstraint.m_penetration;

            var velocityError:Float = contactConstraint.restitution - rel_vel;// * damping;

            var penetrationImpulse:Float = positionalError * contactConstraint.jacDiagABInv;
            var velocityImpulse:Float = velocityError * contactConstraint.jacDiagABInv;
            normalImpulse = penetrationImpulse + velocityImpulse;

            // See Erin Catto's GDC 2006 paper: Clamp the accumulated impulse
            var oldNormalImpulse:Float = contactConstraint.appliedPushImpulse;
            var sum:Float = oldNormalImpulse + normalImpulse;
            contactConstraint.appliedPushImpulse = 0 > sum ? 0 : sum;

            normalImpulse = contactConstraint.appliedPushImpulse - oldNormalImpulse;

            var tmp:Vector3f = new Vector3f();

            tmp.scaleBy(body1.invMass, contactConstraint.contactNormal);
            body1.internalApplyPushImpulse(tmp, contactConstraint.angularComponentA, normalImpulse);

            tmp.scaleBy(body2.invMass, contactConstraint.contactNormal);
            body2.internalApplyPushImpulse(tmp, contactConstraint.angularComponentB, -normalImpulse);
        }
    }

    /**
     * velocity + friction
     * response  between two dynamic objects with friction
     */
    private inline function resolveSingleCollisionCombinedCacheFriendly(
																body1:SolverBody,
																body2:SolverBody,
																contactConstraint:SolverConstraint,
																solverInfo:ContactSolverInfo):Float
	{
        var normalImpulse:Float;

		//  Optimized version of projected relative velocity, use precomputed cross products with normal
		//	body1.getVelocityInLocalPoint(contactConstraint.m_rel_posA,vel1);
		//	body2.getVelocityInLocalPoint(contactConstraint.m_rel_posB,vel2);
		//	btVector3 vel = vel1 - vel2;
		//	btScalar  rel_vel = contactConstraint.m_contactNormal.dot(vel);

		var vel1Dotn:Float = contactConstraint.contactNormal.dot(body1.linearVelocity) + contactConstraint.relpos1CrossNormal.dot(body1.angularVelocity);
		var vel2Dotn:Float = contactConstraint.contactNormal.dot(body2.linearVelocity) + contactConstraint.relpos2CrossNormal.dot(body2.angularVelocity);

		var rel_vel:Float = vel1Dotn - vel2Dotn;

		var positionalError:Float = 0.;
		if (!solverInfo.splitImpulse || (contactConstraint.penetration > solverInfo.splitImpulsePenetrationThreshold)) 
		{
			positionalError = -contactConstraint.penetration * solverInfo.erp / solverInfo.timeStep;
		}

		var velocityError:Float = contactConstraint.restitution - rel_vel;// * damping;

		var penetrationImpulse:Float = positionalError * contactConstraint.jacDiagABInv;
		var velocityImpulse:Float = velocityError * contactConstraint.jacDiagABInv;
		
		normalImpulse = penetrationImpulse + velocityImpulse;


		// See Erin Catto's GDC 2006 paper: Clamp the accumulated impulse
		var oldNormalImpulse:Float = contactConstraint.appliedImpulse;
		var sum:Float = oldNormalImpulse + normalImpulse;
		contactConstraint.appliedImpulse = 0 > sum ? 0 : sum;

		normalImpulse = contactConstraint.appliedImpulse - oldNormalImpulse;

		tmp.scaleBy(body1.invMass, contactConstraint.contactNormal);
		body1.internalApplyImpulse(tmp, contactConstraint.angularComponentA, normalImpulse);

		tmp.scaleBy(body2.invMass, contactConstraint.contactNormal);
		body2.internalApplyImpulse(tmp, contactConstraint.angularComponentB, -normalImpulse);

        return normalImpulse;
    }

    private inline function resolveSingleFrictionCacheFriendly(
														body1:SolverBody,
														body2:SolverBody,
														contactConstraint:SolverConstraint,
														solverInfo:ContactSolverInfo,
														appliedNormalImpulse:Float):Void
    {
		var combinedFriction:Float = contactConstraint.friction;

        var limit:Float = appliedNormalImpulse * combinedFriction;

        if (appliedNormalImpulse > 0) //friction
        {
			var ccNormal:Vector3f = contactConstraint.contactNormal;

            var j1:Float;
            {
                var vel1Dotn:Float = ccNormal.dot(body1.linearVelocity) + 
									contactConstraint.relpos1CrossNormal.dot(body1.angularVelocity);
									
                var vel2Dotn:Float = ccNormal.dot(body2.linearVelocity) + 
									contactConstraint.relpos2CrossNormal.dot(body2.angularVelocity);
									
                var rel_vel:Float = vel1Dotn - vel2Dotn;

                // calculate j that moves us to zero relative velocity
                j1 = -rel_vel * contactConstraint.jacDiagABInv;
                //#define CLAMP_ACCUMULATED_FRICTION_IMPULSE 1
                //#ifdef CLAMP_ACCUMULATED_FRICTION_IMPULSE
                var oldTangentImpulse:Float = contactConstraint.appliedImpulse;
                contactConstraint.appliedImpulse = oldTangentImpulse + j1;

                if (limit < contactConstraint.appliedImpulse)
				{
                    contactConstraint.appliedImpulse = limit;
                } 
				else
				{
                    if (contactConstraint.appliedImpulse < -limit) 
					{
                        contactConstraint.appliedImpulse = -limit;
                    }
                }
                j1 = contactConstraint.appliedImpulse - oldTangentImpulse;
                //	#else
                //	if (limit < j1)
                //	{
                //		j1 = limit;
                //	} else
                //	{
                //		if (j1 < -limit)
                //			j1 = -limit;
                //	}
                //	#endif

                //GEN_set_min(contactConstraint.m_appliedImpulse, limit);
                //GEN_set_max(contactConstraint.m_appliedImpulse, -limit);
            }

            tmp.scaleBy(body1.invMass, ccNormal);
            body1.internalApplyImpulse(tmp, contactConstraint.angularComponentA, j1);

            tmp.scaleBy(body2.invMass, ccNormal);
            body2.internalApplyImpulse(tmp, contactConstraint.angularComponentB, -j1);
        }
    }

	//private var tmpTransform:Transform = new Transform();
	private var tmp:Vector3f = new Vector3f();
	private var tmpFtorqueAxis1:Vector3f = new Vector3f();
	//private var tmpMat:Matrix3f = new Matrix3f();
	private var tmpVec:Vector3f = new Vector3f();
    private inline function addFrictionConstraint(normalAxis:Vector3f, 
												solverBodyIdA:Int, solverBodyIdB:Int, 
												frictionIndex:Int, cp:ManifoldPoint,  
												rel_pos1:Vector3f, rel_pos2:Vector3f, 
												colObj0:CollisionObject, colObj1:CollisionObject, 
												relaxation:Float):Void
	{
        var body0:RigidBody = RigidBody.upcast(colObj0);
        var body1:RigidBody = RigidBody.upcast(colObj1);

        var solverConstraint:SolverConstraint = constraintsPool.get();
        tmpSolverFrictionConstraintPool.add(solverConstraint);

        solverConstraint.contactNormal.copyFrom(normalAxis);

        solverConstraint.solverBodyIdA = solverBodyIdA;
        solverConstraint.solverBodyIdB = solverBodyIdB;
        solverConstraint.constraintType = SolverConstraintType.SOLVER_FRICTION_1D;
        solverConstraint.frictionIndex = frictionIndex;

        solverConstraint.friction = cp.combinedFriction;
        solverConstraint.originalContactPoint = null;

        solverConstraint.appliedImpulse = 0;
        solverConstraint.appliedPushImpulse = 0;
        solverConstraint.penetration = 0;
		
		//a
        {
            tmpFtorqueAxis1.crossBy(rel_pos1, solverConstraint.contactNormal);
            solverConstraint.relpos1CrossNormal.copyFrom(tmpFtorqueAxis1);
            if (body0 != null)
			{
                solverConstraint.angularComponentA.copyFrom(tmpFtorqueAxis1);
                body0.getInvInertiaTensorWorld().transform(solverConstraint.angularComponentA);
            } 
			else
			{
                solverConstraint.angularComponentA.setTo(0, 0, 0);
            }
        }
		
		//b
        {
            tmpFtorqueAxis1.crossBy(rel_pos2, solverConstraint.contactNormal);
            solverConstraint.relpos2CrossNormal.copyFrom(tmpFtorqueAxis1);
            if (body1 != null) 
			{
                solverConstraint.angularComponentB.copyFrom(tmpFtorqueAxis1);
                body1.getInvInertiaTensorWorld().transform(solverConstraint.angularComponentB);
            }
			else 
			{
                solverConstraint.angularComponentB.setTo(0, 0, 0);
            }
        }

        //#ifdef COMPUTE_IMPULSE_DENOM
        //	btScalar denom0 = rb0->computeImpulseDenominator(pos1,solverConstraint.m_contactNormal);
        //	btScalar denom1 = rb1->computeImpulseDenominator(pos2,solverConstraint.m_contactNormal);
        //#else
        var denom0:Float = 0;
        var denom1:Float = 0;
        if (body0 != null)
		{
            tmpVec.crossBy(solverConstraint.angularComponentA, rel_pos1);
            denom0 = body0.getInvMass() + normalAxis.dot(tmpVec);
        }
        if (body1 != null)
		{
            tmpVec.crossBy(solverConstraint.angularComponentB, rel_pos2);
            denom1 = body1.getInvMass() + normalAxis.dot(tmpVec);
        }
        //#endif //COMPUTE_IMPULSE_DENOM

        var denom:Float = relaxation / (denom0 + denom1);
        solverConstraint.jacDiagABInv = denom;
    }

	var tmpTrans:Transform = new Transform();
	var rel_pos1:Vector3f = new Vector3f();
	var rel_pos2:Vector3f = new Vector3f();
	var vel:Vector3f = new Vector3f();
	var torqueAxis0:Vector3f = new Vector3f();
	var torqueAxis1:Vector3f = new Vector3f();
	var vel1:Vector3f = new Vector3f();
	var vel2:Vector3f = new Vector3f();
	//var frictionDir1:Vector3f = new Vector3f();
	//var frictionDir2:Vector3f = new Vector3f();
	var vec:Vector3f = new Vector3f();
    public function solveGroupCacheFriendlySetup(bodies:ObjectArrayList<CollisionObject>, numBodies:Int,
									manifoldPtr:ObjectArrayList<PersistentManifold>, manifold_offset:Int, numManifolds:Int,  				  
									constraints:ObjectArrayList<TypedConstraint>, constraints_offset:Int, numConstraints:Int,
									infoGlobal:ContactSolverInfo,  debugDrawer:IDebugDraw):Float
	{
        BulletStats.pushProfile("solveGroupCacheFriendlySetup");

		if ((numConstraints + numManifolds) == 0)
		{
			BulletStats.popProfile();
			return 0;
		}
		
		var manifold:PersistentManifold = null;
		var colObj0:CollisionObject = null;
		var colObj1:CollisionObject = null;
		
		var useWarmStarting:Bool = (infoGlobal.solverMode & SolverMode.SOLVER_USE_WARMSTARTING) != 0;

		//btRigidBody* rb0=0,*rb1=0;

		//	//#ifdef FORCE_REFESH_CONTACT_MANIFOLDS
		//
		//		BEGIN_PROFILE("refreshManifolds");
		//
		//		int i;
		//
		//
		//
		//		for (i=0;i<numManifolds;i++)
		//		{
		//			manifold = manifoldPtr[i];
		//			rb1 = (btRigidBody*)manifold->getBody1();
		//			rb0 = (btRigidBody*)manifold->getBody0();
		//
		//			manifold->refreshContactPoints(rb0->getCenterOfMassTransform(),rb1->getCenterOfMassTransform());
		//
		//		}
		//
		//		END_PROFILE("refreshManifolds");
		//	//#endif //FORCE_REFESH_CONTACT_MANIFOLDS
		

		//int sizeofSB = sizeof(btSolverBody);
		//int sizeofSC = sizeof(btSolverConstraint);

		//if (1)
		{
			//if m_stackAlloc, try to pack bodies/constraints to speed up solving
			//		btBlock*					sablock;
			//		sablock = stackAlloc->beginBlock();

			//	int memsize = 16;
			//		unsigned char* stackMemory = stackAlloc->allocate(memsize);


			// todo: use stack allocator for this temp memory
			//int minReservation = numManifolds * 2;

			//m_tmpSolverBodyPool.reserve(minReservation);

			//don't convert all bodies, only the one we need so solver the constraints
			/*
			{
			for (int i=0;i<numBodies;i++)
			{
			btRigidBody* rb = btRigidBody::upcast(bodies[i]);
			if (rb && 	(rb->getIslandTag() >= 0))
			{
			btAssert(rb->getCompanionId() < 0);
			int solverBodyId = m_tmpSolverBodyPool.size();
			btSolverBody& solverBody = m_tmpSolverBodyPool.expand();
			initSolverBody(&solverBody,rb);
			rb->setCompanionId(solverBodyId);
			} 
			}
			}
			*/

			//m_tmpSolverConstraintPool.reserve(minReservation);
			//m_tmpSolverFrictionConstraintPool.reserve(minReservation);

			{
				for (i in 0...numManifolds)
				{
					manifold = manifoldPtr.getQuick(manifold_offset + i);
					colObj0 = cast manifold.getBody0();
					colObj1 = cast manifold.getBody1();

					var solverBodyIdA:Int = -1;
					var solverBodyIdB:Int = -1;

					if (manifold.getNumContacts() != 0)
					{
						if (colObj0.getIslandTag() >= 0)
						{
							if (colObj0.getCompanionId() >= 0)
							{
								// body has already been converted
								solverBodyIdA = colObj0.getCompanionId();
							} 
							else 
							{
								solverBodyIdA = tmpSolverBodyPool.size();
								var solverBody:SolverBody = bodiesPool.get();
								tmpSolverBodyPool.add(solverBody);
								initSolverBody(solverBody, colObj0);
								colObj0.setCompanionId(solverBodyIdA);
							}
						} 
						else
						{
							// create a static body
							solverBodyIdA = tmpSolverBodyPool.size();
							var solverBody:SolverBody = bodiesPool.get();
							tmpSolverBodyPool.add(solverBody);
							initSolverBody(solverBody, colObj0);
						}

						if (colObj1.getIslandTag() >= 0) 
						{
							if (colObj1.getCompanionId() >= 0)
							{
								solverBodyIdB = colObj1.getCompanionId();
							} 
							else
							{
								solverBodyIdB = tmpSolverBodyPool.size();
								var solverBody:SolverBody = bodiesPool.get();
								tmpSolverBodyPool.add(solverBody);
								initSolverBody(solverBody, colObj1);
								colObj1.setCompanionId(solverBodyIdB);
							}
						} 
						else 
						{
							// create a static body
							solverBodyIdB = tmpSolverBodyPool.size();
							var solverBody:SolverBody = bodiesPool.get();
							tmpSolverBodyPool.add(solverBody);
							initSolverBody(solverBody, colObj1);
						}
					}
					
					var rb0:RigidBody = RigidBody.upcast(colObj0);
					var rb1:RigidBody = RigidBody.upcast(colObj1);

					var relaxation:Float;

					for (j in 0...manifold.getNumContacts())
					{
						var cp:ManifoldPoint = manifold.getContactPoint(j);

						if (cp.getDistance() <= 0)
						{
							rel_pos1.subtractBy(cp.positionWorldOnA, colObj0.getWorldTransform().origin);
							rel_pos2.subtractBy(cp.positionWorldOnB, colObj1.getWorldTransform().origin);

							relaxation = 1;
							var rel_vel:Float;

							var frictionIndex:Int = tmpSolverConstraintPool.size();

							{
								var solverConstraint:SolverConstraint = constraintsPool.get();
								tmpSolverConstraintPool.add(solverConstraint);
								
								solverConstraint.solverBodyIdA = solverBodyIdA;
								solverConstraint.solverBodyIdB = solverBodyIdB;
								solverConstraint.constraintType = SolverConstraintType.SOLVER_CONTACT_1D;

								solverConstraint.originalContactPoint = cp;

								torqueAxis0.crossBy(rel_pos1, cp.normalWorldOnB);
								if (rb0 != null) 
								{
									solverConstraint.angularComponentA.copyFrom(torqueAxis0);
									rb0.getInvInertiaTensorWorld().transform(solverConstraint.angularComponentA);
								} 
								else
								{
									solverConstraint.angularComponentA.setTo(0, 0, 0);
								}
								

								torqueAxis1.crossBy(rel_pos2, cp.normalWorldOnB);
								if (rb1 != null) 
								{
									solverConstraint.angularComponentB.copyFrom(torqueAxis1);
									rb1.getInvInertiaTensorWorld().transform(solverConstraint.angularComponentB);
								} 
								else 
								{
									solverConstraint.angularComponentB.setTo(0, 0, 0);
								}

								{
									//#ifdef COMPUTE_IMPULSE_DENOM
									//btScalar denom0 = rb0->computeImpulseDenominator(pos1,cp.m_normalWorldOnB);
									//btScalar denom1 = rb1->computeImpulseDenominator(pos2,cp.m_normalWorldOnB);
									//#else
									var denom0:Float = 0;
									var denom1:Float = 0;
									if (rb0 != null)
									{
										vec.crossBy(solverConstraint.angularComponentA, rel_pos1);
										denom0 = rb0.getInvMass() + cp.normalWorldOnB.dot(vec);
									}
									if (rb1 != null)
									{
										vec.crossBy(solverConstraint.angularComponentB, rel_pos2);
										denom1 = rb1.getInvMass() + cp.normalWorldOnB.dot(vec);
									}
									//#endif //COMPUTE_IMPULSE_DENOM

									var denom:Float = relaxation / (denom0 + denom1);
									solverConstraint.jacDiagABInv = denom;
								}

								solverConstraint.contactNormal.copyFrom(cp.normalWorldOnB);
								solverConstraint.relpos1CrossNormal.crossBy(rel_pos1, cp.normalWorldOnB);
								solverConstraint.relpos2CrossNormal.crossBy(rel_pos2, cp.normalWorldOnB);

								if (rb0 != null)
								{
									rb0.getVelocityInLocalPoint(rel_pos1, vel1);
								} 
								else 
								{
									vel1.setTo(0, 0, 0);
								}

								if (rb1 != null)
								{
									rb1.getVelocityInLocalPoint(rel_pos2, vel2);
								}
								else
								{
									vel2.setTo(0, 0, 0);
								}

								vel.subtractBy(vel1, vel2);

								rel_vel = cp.normalWorldOnB.dot(vel);

								solverConstraint.penetration = FastMath.min(cp.getDistance() + infoGlobal.linearSlop, 0);
								//solverConstraint.m_penetration = cp.getDistance();

								solverConstraint.friction = cp.combinedFriction;
								solverConstraint.restitution = restitutionCurve(rel_vel, cp.combinedRestitution);
								if (solverConstraint.restitution <= 0)
								{
									solverConstraint.restitution = 0;
								}

								var penVel:Float = -solverConstraint.penetration / infoGlobal.timeStep;

								if (solverConstraint.restitution > penVel)
								{
									solverConstraint.penetration = 0;
								}

								// warm starting (or zero if disabled)
								if (useWarmStarting) 
								{
									solverConstraint.appliedImpulse = cp.appliedImpulse * infoGlobal.warmstartingFactor;
									if (rb0 != null)
									{
										tmpVec.scaleBy(rb0.getInvMass(), solverConstraint.contactNormal);
										tmpSolverBodyPool.getQuick(solverConstraint.solverBodyIdA).internalApplyImpulse(tmpVec, solverConstraint.angularComponentA, solverConstraint.appliedImpulse);
									}
									
									if (rb1 != null)
									{
										tmpVec.scaleBy(rb1.getInvMass(), solverConstraint.contactNormal);
										tmpSolverBodyPool.getQuick(solverConstraint.solverBodyIdB).internalApplyImpulse(tmpVec, solverConstraint.angularComponentB, -solverConstraint.appliedImpulse);
									}
								} 
								else 
								{
									solverConstraint.appliedImpulse = 0;
								}

								solverConstraint.appliedPushImpulse = 0;

								solverConstraint.frictionIndex = tmpSolverFrictionConstraintPool.size();
								if (!cp.lateralFrictionInitialized)
								{
									cp.lateralFrictionDir1.scaleBy(rel_vel, cp.normalWorldOnB);
									cp.lateralFrictionDir1.subtractBy(vel, cp.lateralFrictionDir1);

									var lat_rel_vel:Float = cp.lateralFrictionDir1.lengthSquared;
									if (lat_rel_vel > BulletGlobals.FLT_EPSILON)//0.0f)
									{
										cp.lateralFrictionDir1.scaleLocal(1 / Math.sqrt(lat_rel_vel));
										addFrictionConstraint(cp.lateralFrictionDir1, solverBodyIdA, solverBodyIdB, frictionIndex, cp, rel_pos1, rel_pos2, colObj0, colObj1, relaxation);
										cp.lateralFrictionDir2.crossBy(cp.lateralFrictionDir1, cp.normalWorldOnB);
										cp.lateralFrictionDir2.normalizeLocal(); //??
										addFrictionConstraint(cp.lateralFrictionDir2, solverBodyIdA, solverBodyIdB, frictionIndex, cp, rel_pos1, rel_pos2, colObj0, colObj1, relaxation);
									} 
									else
									{
										// re-calculate friction direction every frame, todo: check if this is really needed

										TransformUtil.planeSpace1(cp.normalWorldOnB, cp.lateralFrictionDir1, cp.lateralFrictionDir2);
										addFrictionConstraint(cp.lateralFrictionDir1, solverBodyIdA, solverBodyIdB, frictionIndex, cp, rel_pos1, rel_pos2, colObj0, colObj1, relaxation);
										addFrictionConstraint(cp.lateralFrictionDir2, solverBodyIdA, solverBodyIdB, frictionIndex, cp, rel_pos1, rel_pos2, colObj0, colObj1, relaxation);
									}
									cp.lateralFrictionInitialized = true;

								} 
								else 
								{
									addFrictionConstraint(cp.lateralFrictionDir1, solverBodyIdA, solverBodyIdB, frictionIndex, cp, rel_pos1, rel_pos2, colObj0, colObj1, relaxation);
									addFrictionConstraint(cp.lateralFrictionDir2, solverBodyIdA, solverBodyIdB, frictionIndex, cp, rel_pos1, rel_pos2, colObj0, colObj1, relaxation);
								}

								{
									var frictionConstraint1:SolverConstraint = tmpSolverFrictionConstraintPool.getQuick(solverConstraint.frictionIndex);
									if (useWarmStarting)
									{
										frictionConstraint1.appliedImpulse = cp.appliedImpulseLateral1 * infoGlobal.warmstartingFactor;
										if (rb0 != null)
										{
											tmpVec.scaleBy(rb0.getInvMass(), frictionConstraint1.contactNormal);
											tmpSolverBodyPool.getQuick(solverConstraint.solverBodyIdA).internalApplyImpulse(tmpVec, frictionConstraint1.angularComponentA, frictionConstraint1.appliedImpulse);
										}
										if (rb1 != null)
										{
											tmpVec.scaleBy(rb1.getInvMass(), frictionConstraint1.contactNormal);
											tmpSolverBodyPool.getQuick(solverConstraint.solverBodyIdB).internalApplyImpulse(tmpVec, frictionConstraint1.angularComponentB, -frictionConstraint1.appliedImpulse);
										}
									}
									else
									{
										frictionConstraint1.appliedImpulse = 0;
									}
								}
								{
									var frictionConstraint2:SolverConstraint = tmpSolverFrictionConstraintPool.getQuick(solverConstraint.frictionIndex + 1);
									if (useWarmStarting)
									{
										frictionConstraint2.appliedImpulse = cp.appliedImpulseLateral2 * infoGlobal.warmstartingFactor;
										if (rb0 != null)
										{
											tmpVec.scaleBy(rb0.getInvMass(), frictionConstraint2.contactNormal);
											tmpSolverBodyPool.getQuick(solverConstraint.solverBodyIdA).internalApplyImpulse(tmpVec, frictionConstraint2.angularComponentA, frictionConstraint2.appliedImpulse);
										}
										if (rb1 != null)
										{
											tmpVec.scaleBy(rb1.getInvMass(), frictionConstraint2.contactNormal);
											tmpSolverBodyPool.getQuick(solverConstraint.solverBodyIdB).internalApplyImpulse(tmpVec, frictionConstraint2.angularComponentB, -frictionConstraint2.appliedImpulse);
										}
									} 
									else
									{
										frictionConstraint2.appliedImpulse = 0;
									}
								}
							}
						}
					}
				}
			}
		}

		// TODO: btContactSolverInfo info = infoGlobal;

		{
			for (j in 0...numConstraints)
			{
				var constraint:TypedConstraint = constraints.getQuick(constraints_offset + j);
				constraint.buildJacobian();
			}
		}
		
		{
			for (j in 0...numConstraints)
			{
				var constraint:TypedConstraint = constraints.getQuick(constraints_offset + j);
				constraint.getInfo2(infoGlobal);
			}
		}


		var numConstraintPool:Int = tmpSolverConstraintPool.size();
		var numFrictionPool:Int = tmpSolverFrictionConstraintPool.size();

		// todo: use stack allocator for such temporarily memory, same for solver bodies/constraints
		MiscUtil.resizeIntArrayList(orderTmpConstraintPool, numConstraintPool, 0);
		MiscUtil.resizeIntArrayList(orderFrictionConstraintPool, numFrictionPool, 0);
		{
			for (i in 0...numConstraintPool)
			{
				orderTmpConstraintPool.set(i, i);
			}
			for (i in 0...numFrictionPool) 
			{
				orderFrictionConstraintPool.set(i, i);
			}
		}

		BulletStats.popProfile();
		return 0;
    }

    public function solveGroupCacheFriendlyIterations(bodies:ObjectArrayList<CollisionObject>, numBodies:Int, 
													manifoldPtr:ObjectArrayList<PersistentManifold>, manifold_offset:Int, numManifolds:Int,  												constraints:ObjectArrayList<TypedConstraint>, constraints_offset:Int, numConstraints:Int, 
													 infoGlobal:ContactSolverInfo, debugDrawer:IDebugDraw):Float
	{
        BulletStats.pushProfile("solveGroupCacheFriendlyIterations");

		var numConstraintPool:Int = tmpSolverConstraintPool.size();
		var numFrictionPool:Int = tmpSolverFrictionConstraintPool.size();
		
		var useRandmizeOrder:Bool = (infoGlobal.solverMode & SolverMode.SOLVER_RANDMIZE_ORDER) != 0;

		// should traverse the contacts random order...
		for (iteration in 0...infoGlobal.numIterations)
		{
			if (useRandmizeOrder)
			{
				if ((iteration & 7) == 0)
				{
					for (j in 0...numConstraintPool) 
					{
						var tmp:Int = orderTmpConstraintPool.get(j);
						var swapi:Int = randInt2(j + 1);
						orderTmpConstraintPool.set(j, orderTmpConstraintPool.get(swapi));
						orderTmpConstraintPool.set(swapi, tmp);
					}

					for (j in 0...numFrictionPool)
					{
						var tmp:Int = orderFrictionConstraintPool.get(j);
						var swapi:Int = randInt2(j + 1);
						orderFrictionConstraintPool.set(j, orderFrictionConstraintPool.get(swapi));
						orderFrictionConstraintPool.set(swapi, tmp);
					}
				}
			}

			for (j in 0...numConstraints)
			{
				var constraint:TypedConstraint = constraints.getQuick(constraints_offset + j);
				// todo: use solver bodies, so we don't need to copy from/to btRigidBody
				
				var bodyA:RigidBody = constraint.getRigidBodyA();
				var bodyB:RigidBody = constraint.getRigidBodyB();
				var bodyAIslandTag:Int = bodyA.getIslandTag();
				var bodyBIslandTag:Int = bodyB.getIslandTag();
				var bodyACompanionId:Int = bodyA.getCompanionId();
				var bodyBCompanionId:Int = bodyB.getCompanionId();

				if ((bodyAIslandTag >= 0) && (bodyACompanionId >= 0))
				{
					tmpSolverBodyPool.getQuick(bodyACompanionId).writebackVelocity();
				}
				
				if ((bodyBIslandTag >= 0) && (bodyBCompanionId >= 0))
				{
					tmpSolverBodyPool.getQuick(bodyBCompanionId).writebackVelocity();
				}

				constraint.solveConstraint(infoGlobal.timeStep);

				if ((bodyAIslandTag >= 0) && (bodyACompanionId >= 0))
				{
					tmpSolverBodyPool.getQuick(bodyACompanionId).readVelocity();
				}
				
				if ((bodyBIslandTag >= 0) && (bodyBCompanionId >= 0)) 
				{
					tmpSolverBodyPool.getQuick(bodyBCompanionId).readVelocity();
				}
			}

			{
				var numPoolConstraints:Int = tmpSolverConstraintPool.size();
				for (j in 0...numPoolConstraints)
				{
					var solveManifold:SolverConstraint = tmpSolverConstraintPool.getQuick(orderTmpConstraintPool.get(j));
					resolveSingleCollisionCombinedCacheFriendly(tmpSolverBodyPool.getQuick(solveManifold.solverBodyIdA),
							tmpSolverBodyPool.getQuick(solveManifold.solverBodyIdB), solveManifold, infoGlobal);
				}
			}

			{
				var numFrictionPoolConstraints:Int = tmpSolverFrictionConstraintPool.size();

				for (j in 0...numFrictionPoolConstraints) 
				{
					var solveManifold:SolverConstraint = tmpSolverFrictionConstraintPool.getQuick(orderFrictionConstraintPool.get(j));

					var totalImpulse:Float = tmpSolverConstraintPool.getQuick(solveManifold.frictionIndex).appliedImpulse +
							tmpSolverConstraintPool.getQuick(solveManifold.frictionIndex).appliedPushImpulse;

					resolveSingleFrictionCacheFriendly(tmpSolverBodyPool.getQuick(solveManifold.solverBodyIdA),
							tmpSolverBodyPool.getQuick(solveManifold.solverBodyIdB), solveManifold, infoGlobal,
							totalImpulse);
				}
			}
		}

		if (infoGlobal.splitImpulse)
		{
			for (iteration  in 0...infoGlobal.numIterations)
			{
				var numPoolConstraints:Int = tmpSolverConstraintPool.size();
				for (j in 0...numPoolConstraints) 
				{
					var solveManifold:SolverConstraint = tmpSolverConstraintPool.getQuick(orderTmpConstraintPool.get(j));

					resolveSplitPenetrationImpulseCacheFriendly(tmpSolverBodyPool.getQuick(solveManifold.solverBodyIdA),
							tmpSolverBodyPool.getQuick(solveManifold.solverBodyIdB), solveManifold, infoGlobal);
				}
			}
		}
			
		BulletStats.popProfile();
		
		return 0;
    }

    public function solveGroupCacheFriendly(bodies:ObjectArrayList<CollisionObject>, numBodies:Int, 
											manifoldPtr:ObjectArrayList<PersistentManifold>, manifold_offset:Int, numManifolds:Int, 
											constraints:ObjectArrayList<TypedConstraint>, constraints_offset:Int, numConstraints:Int, 
											infoGlobal:ContactSolverInfo, debugDrawer:IDebugDraw):Float
	{
        solveGroupCacheFriendlySetup(bodies, numBodies, manifoldPtr, manifold_offset, numManifolds, constraints, constraints_offset, numConstraints, infoGlobal, debugDrawer);
		
        solveGroupCacheFriendlyIterations(bodies, numBodies, manifoldPtr, manifold_offset, numManifolds, constraints, constraints_offset, numConstraints, infoGlobal, debugDrawer);

        var numPoolConstraints:Int = tmpSolverConstraintPool.size();
        for (j in 0...numPoolConstraints)
		{
            var solveManifold:SolverConstraint = tmpSolverConstraintPool.getQuick(j);
            var pt:ManifoldPoint = cast solveManifold.originalContactPoint;
			
			#if debug
            Assert.assert (pt != null);
			#end
			
            pt.appliedImpulse = solveManifold.appliedImpulse;
            pt.appliedImpulseLateral1 = tmpSolverFrictionConstraintPool.getQuick(solveManifold.frictionIndex).appliedImpulse;
            pt.appliedImpulseLateral2 = tmpSolverFrictionConstraintPool.getQuick(solveManifold.frictionIndex + 1).appliedImpulse;

            // do a callback here?
        }

        if (infoGlobal.splitImpulse)
		{
            for (i in 0...tmpSolverBodyPool.size()) 
			{
                tmpSolverBodyPool.getQuick(i).writebackVelocity2(infoGlobal.timeStep);
                bodiesPool.release(tmpSolverBodyPool.getQuick(i));
            }
        } 
		else 
		{
            for (i in 0...tmpSolverBodyPool.size())
			{
                tmpSolverBodyPool.getQuick(i).writebackVelocity();
                bodiesPool.release(tmpSolverBodyPool.getQuick(i));
            }
        }

        //	printf("m_tmpSolverConstraintPool.size() = %i\n",m_tmpSolverConstraintPool.size());

		/*
		printf("m_tmpSolverBodyPool.size() = %i\n",m_tmpSolverBodyPool.size());
		printf("m_tmpSolverConstraintPool.size() = %i\n",m_tmpSolverConstraintPool.size());
		printf("m_tmpSolverFrictionConstraintPool.size() = %i\n",m_tmpSolverFrictionConstraintPool.size());
		printf("m_tmpSolverBodyPool.capacity() = %i\n",m_tmpSolverBodyPool.capacity());
		printf("m_tmpSolverConstraintPool.capacity() = %i\n",m_tmpSolverConstraintPool.capacity());
		printf("m_tmpSolverFrictionConstraintPool.capacity() = %i\n",m_tmpSolverFrictionConstraintPool.capacity());
		*/

        tmpSolverBodyPool.clear();

        for (i in 0...tmpSolverConstraintPool.size()) 
		{
            constraintsPool.release(tmpSolverConstraintPool.getQuick(i));
        }
        tmpSolverConstraintPool.clear();

        for (i in 0...tmpSolverFrictionConstraintPool.size()) 
		{
            constraintsPool.release(tmpSolverFrictionConstraintPool.getQuick(i));
        }
        tmpSolverFrictionConstraintPool.clear();

        return 0;
    }

    /**
     * Sequentially applies impulses.
     */
	public function solveGroup(bodies:ObjectArrayList<CollisionObject>, numBodies:Int, 
						manifoldPtr:ObjectArrayList<PersistentManifold>, manifold_offset:Int, numManifolds:Int, 
						constraints:ObjectArrayList<TypedConstraint>, constraints_offset:Int, numConstraints:Int, 
						infoGlobal:ContactSolverInfo, debugDrawer:IDebugDraw, dispatcher:Dispatcher):Float 
	{
		BulletStats.pushProfile("solveGroup");

		// TODO: solver cache friendly
		if ((infoGlobal.solverMode & SolverMode.SOLVER_CACHE_FRIENDLY) != 0) 
		{
			// you need to provide at least some bodies
			// SimpleDynamicsWorld needs to switch off SOLVER_CACHE_FRIENDLY
			#if debug
			Assert.assert (bodies != null);
			Assert.assert (numBodies != 0);
			#end
			
			var value:Float = solveGroupCacheFriendly(bodies, numBodies, manifoldPtr, manifold_offset, numManifolds, constraints, constraints_offset, numConstraints, infoGlobal, debugDrawer);
			
			BulletStats.popProfile();
			return value;
		}

		var info:ContactSolverInfo = new ContactSolverInfo();
		if (infoGlobal != null)
			info.copyFrom(infoGlobal);

		var numiter:Int = infoGlobal.numIterations;

		var totalPoints:Int = 0;
		{
			for (j in 0...numManifolds)
			{
				var manifold:PersistentManifold = manifoldPtr.getQuick(manifold_offset + j);
				prepareConstraints(manifold, info, debugDrawer);

				for (p in 0...manifoldPtr.getQuick(manifold_offset + j).getNumContacts())
				{
					gOrder[totalPoints].manifoldIndex = j;
					gOrder[totalPoints].pointIndex = p;
					totalPoints++;
				}
			}
		}

		{
			for (j in 0...numConstraints)
			{
				var constraint:TypedConstraint = constraints.getQuick(constraints_offset + j);
				constraint.buildJacobian();
			}
		}

		// should traverse the contacts random order...
		{
			for (iteration in 0...numiter) 
			{
				if ((infoGlobal.solverMode & SolverMode.SOLVER_RANDMIZE_ORDER) != 0)
				{
					if ((iteration & 7) == 0)
					{
						for (j in 0...totalPoints)
						{
							// JAVA NOTE: swaps references instead of copying values (but that's fine in this context)
							var tmp:OrderIndex = gOrder[j];
							var swapi:Int = randInt2(j + 1);
							gOrder[j] = gOrder[swapi];
							gOrder[swapi] = tmp;
						}
					}
				}

				for (j in 0...numConstraints)
				{
					var constraint:TypedConstraint = constraints.getQuick(constraints_offset + j);
					constraint.solveConstraint(info.timeStep);
				}

				for (j in 0...totalPoints)
				{
					var manifold:PersistentManifold = manifoldPtr.getQuick(manifold_offset + gOrder[j].manifoldIndex);
					solve(cast manifold.getBody0(),
							cast manifold.getBody1(), manifold.getContactPoint(gOrder[j].pointIndex), info, iteration, debugDrawer);
				}

				for (j in 0...totalPoints) 
				{
					var manifold:PersistentManifold = manifoldPtr.getQuick(manifold_offset + gOrder[j].manifoldIndex);
					solveFriction(cast manifold.getBody0(),
								cast manifold.getBody1(), manifold.getContactPoint(gOrder[j].pointIndex), info, iteration, debugDrawer);
				}

			}
		}

		BulletStats.popProfile();
		
		return 0;
	}

    private function prepareConstraints(manifoldPtr:PersistentManifold, info:ContactSolverInfo, debugDrawer:IDebugDraw):Void
	{
        var body0:RigidBody = cast manifoldPtr.getBody0();
        var body1:RigidBody = cast manifoldPtr.getBody1();

        // only necessary to refresh the manifold once (first iteration). The integration is done outside the loop
        {
            //#ifdef FORCE_REFESH_CONTACT_MANIFOLDS
            //manifoldPtr->refreshContactPoints(body0->getCenterOfMassTransform(),body1->getCenterOfMassTransform());
            //#endif //FORCE_REFESH_CONTACT_MANIFOLDS
            var numpoints:Int = manifoldPtr.getNumContacts();

            BulletStats.gTotalContactPoints += numpoints;

            var tmpVec:Vector3f = new Vector3f();
            var tmpMat3:Matrix3f = new Matrix3f();

            var pos1:Vector3f = new Vector3f();
            var pos2:Vector3f = new Vector3f();
            var rel_pos1:Vector3f = new Vector3f();
            var rel_pos2:Vector3f = new Vector3f();
            var vel1:Vector3f = new Vector3f();
            var vel2:Vector3f = new Vector3f();
            var vel:Vector3f = new Vector3f();
            var totalImpulse:Vector3f = new Vector3f();
            var torqueAxis0:Vector3f = new Vector3f();
            var torqueAxis1:Vector3f = new Vector3f();
            var ftorqueAxis0:Vector3f = new Vector3f();
            var ftorqueAxis1:Vector3f = new Vector3f();

            for (i in 0...numpoints) 
			{
                var cp:ManifoldPoint = manifoldPtr.getContactPoint(i);
                if (cp.getDistance() <= 0)
				{
                    cp.getPositionWorldOnA(pos1);
                    cp.getPositionWorldOnB(pos2);

                    rel_pos1.subtractBy(pos1, body0.getCenterOfMassPosition());
                    rel_pos2.subtractBy(pos2, body1.getCenterOfMassPosition());

                    // this jacobian entry is re-used for all iterations
                    var mat1:Matrix3f = body0.getCenterOfMassTransformTo(new Transform()).basis;
                    mat1.transpose();

                    var mat2:Matrix3f = body1.getCenterOfMassTransformTo(new Transform()).basis;
                    mat2.transpose();

                    var jac:JacobianEntry = jacobiansPool.get();
                    jac.init(mat1, mat2,
                            rel_pos1, rel_pos2, cp.normalWorldOnB,
                            body0.getInvInertiaDiagLocal(), body0.getInvMass(),
                            body1.getInvInertiaDiagLocal(), body1.getInvMass());

                    var jacDiagAB:Float = jac.getDiagonal();
                    jacobiansPool.release(jac);

                    var cpd:ConstraintPersistentData = cast cp.userPersistentData;
                    if (cpd != null) 
					{
                        // might be invalid
                        cpd.persistentLifeTime++;
                        if (cpd.persistentLifeTime != cp.getLifeTime())
						{
                            //printf("Invalid: cpd->m_persistentLifeTime = %i cp.getLifeTime() = %i\n",cpd->m_persistentLifeTime,cp.getLifeTime());
                            //new (cpd) btConstraintPersistentData;
                            cpd.reset();
                            cpd.persistentLifeTime = cp.getLifeTime();

                        } 
						else
						{
                            //printf("Persistent: cpd->m_persistentLifeTime = %i cp.getLifeTime() = %i\n",cpd->m_persistentLifeTime,cp.getLifeTime());
                        }
                    } 
					else
					{
                        // todo: should this be in a pool?
                        //void* mem = btAlignedAlloc(sizeof(btConstraintPersistentData),16);
                        //cpd = new (mem)btConstraintPersistentData;
                        cpd = new ConstraintPersistentData();
                        //assert(cpd != null);

                        //printf("totalCpd = %i Created Ptr %x\n",totalCpd,cpd);
                        cp.userPersistentData = cpd;
                        cpd.persistentLifeTime = cp.getLifeTime();
                        //printf("CREATED: %x . cpd->m_persistentLifeTime = %i cp.getLifeTime() = %i\n",cpd,cpd->m_persistentLifeTime,cp.getLifeTime());
                    }
					
					#if debug
                    Assert.assert (cpd != null);
					#end

                    cpd.jacDiagABInv = 1 / jacDiagAB;

                    // Dependent on Rigidbody A and B types, fetch the contact/friction response func
                    // perhaps do a similar thing for friction/restutution combiner funcs...

                    cpd.frictionSolverFunc = frictionDispatch[body0.frictionSolverType][body1.frictionSolverType];
                    cpd.contactSolverFunc = contactDispatch[body0.contactSolverType][body1.contactSolverType];

                    body0.getVelocityInLocalPoint(rel_pos1, vel1);
                    body1.getVelocityInLocalPoint(rel_pos2, vel2);
                    vel.subtractBy(vel1, vel2);

                    var rel_vel:Float;
                    rel_vel = cp.normalWorldOnB.dot(vel);

                    var combinedRestitution:Float = cp.combinedRestitution;

                    cpd.penetration = cp.getDistance(); ///btScalar(info.m_numIterations);
                    cpd.friction = cp.combinedFriction;
                    cpd.restitution = restitutionCurve(rel_vel, combinedRestitution);
                    if (cpd.restitution <= 0)
					{
                        cpd.restitution = 0;
                    }

                    // restitution and penetration work in same direction so
                    // rel_vel

                    var penVel:Float = -cpd.penetration / info.timeStep;

                    if (cpd.restitution > penVel)
					{
                        cpd.penetration = 0;
                    }

                    var relaxation:Float = info.damping;
                    if ((info.solverMode & SolverMode.SOLVER_USE_WARMSTARTING) != 0) 
					{
                        cpd.appliedImpulse *= relaxation;
                    } 
					else
					{
                        cpd.appliedImpulse = 0;
                    }

                    // for friction
                    cpd.prevAppliedImpulse = cpd.appliedImpulse;

                    // re-calculate friction direction every frame, todo: check if this is really needed
                    TransformUtil.planeSpace1(cp.normalWorldOnB, cpd.frictionWorldTangential0, cpd.frictionWorldTangential1);

                    //#define NO_FRICTION_WARMSTART 1
                    //#ifdef NO_FRICTION_WARMSTART
                    cpd.accumulatedTangentImpulse0 = 0;
                    cpd.accumulatedTangentImpulse1 = 0;
                    //#endif //NO_FRICTION_WARMSTART
                    var denom0:Float = body0.computeImpulseDenominator(pos1, cpd.frictionWorldTangential0);
                    var denom1:Float = body1.computeImpulseDenominator(pos2, cpd.frictionWorldTangential0);
                    var denom:Float = relaxation / (denom0 + denom1);
                    cpd.jacDiagABInvTangent0 = denom;

                    denom0 = body0.computeImpulseDenominator(pos1, cpd.frictionWorldTangential1);
                    denom1 = body1.computeImpulseDenominator(pos2, cpd.frictionWorldTangential1);
                    denom = relaxation / (denom0 + denom1);
                    cpd.jacDiagABInvTangent1 = denom;

                    //btVector3 totalImpulse =
                    //	//#ifndef NO_FRICTION_WARMSTART
                    //	//cpd->m_frictionWorldTangential0*cpd->m_accumulatedTangentImpulse0+
                    //	//cpd->m_frictionWorldTangential1*cpd->m_accumulatedTangentImpulse1+
                    //	//#endif //NO_FRICTION_WARMSTART
                    //	cp.normalWorldOnB*cpd.appliedImpulse;
                    totalImpulse.scaleBy(cpd.appliedImpulse, cp.normalWorldOnB);

                    ///
                    {
                        torqueAxis0.crossBy(rel_pos1, cp.normalWorldOnB);

                        cpd.angularComponentA.copyFrom(torqueAxis0);
                        body0.getInvInertiaTensorWorld().transform(cpd.angularComponentA);

                        torqueAxis1.crossBy(rel_pos2, cp.normalWorldOnB);

                        cpd.angularComponentB.copyFrom(torqueAxis1);
                        body1.getInvInertiaTensorWorld().transform(cpd.angularComponentB);
                    }
                    {
                        ftorqueAxis0.crossBy(rel_pos1, cpd.frictionWorldTangential0);

                        cpd.frictionAngularComponent0A.copyFrom(ftorqueAxis0);
                        body0.getInvInertiaTensorWorld().transform(cpd.frictionAngularComponent0A);
                    }
                    {
                        ftorqueAxis1.crossBy(rel_pos1, cpd.frictionWorldTangential1);

                        cpd.frictionAngularComponent1A.copyFrom(ftorqueAxis1);
                        body0.getInvInertiaTensorWorld().transform(cpd.frictionAngularComponent1A);
                    }
                    {
                        ftorqueAxis0.crossBy(rel_pos2, cpd.frictionWorldTangential0);

                        cpd.frictionAngularComponent0B.copyFrom(ftorqueAxis0);
                        body1.getInvInertiaTensorWorld().transform(cpd.frictionAngularComponent0B);
                    }
                    {
                        ftorqueAxis1.crossBy(rel_pos2, cpd.frictionWorldTangential1);

                        cpd.frictionAngularComponent1B.copyFrom(ftorqueAxis1);
                        body1.getInvInertiaTensorWorld().transform(cpd.frictionAngularComponent1B);
                    }

                    ///

                    // apply previous frames impulse on both bodies
                    body0.applyImpulse(totalImpulse, rel_pos1);

                    tmpVec.negateBy(totalImpulse);
                    body1.applyImpulse(tmpVec, rel_pos2);
                }

            }
        }
    }

    public function solveCombinedContactFriction(body0:RigidBody, body1:RigidBody, cp:ManifoldPoint, info:ContactSolverInfo, iter:Int,  debugDrawer:IDebugDraw):Float
	{
        var maxImpulse:Float = 0;

		if (cp.getDistance() <= 0) 
		{
			{
				//btConstraintPersistentData* cpd = (btConstraintPersistentData*) cp.m_userPersistentData;
				var impulse:Float = ContactConstraint.resolveSingleCollisionCombined(body0, body1, cp, info);

				if (maxImpulse < impulse)
				{
					maxImpulse = impulse;
				}
			}
		}
		
        return maxImpulse;
    }

    private function solve(body0:RigidBody, body1:RigidBody, cp:ManifoldPoint, info:ContactSolverInfo, iter:Int,  debugDrawer:IDebugDraw):Float
	{
        var maxImpulse:Float = 0;

		if (cp.getDistance() <= 0) 
		{
			{
				var cpd:ConstraintPersistentData = cast cp.userPersistentData;
				var impulse:Float = cpd.contactSolverFunc.resolveContact(body0, body1, cp, info);

				if (maxImpulse < impulse) 
				{
					maxImpulse = impulse;
				}
			}
		}

        return maxImpulse;
    }

    private inline function solveFriction(body0:RigidBody, body1:RigidBody, cp:ManifoldPoint, info:ContactSolverInfo, iter:Int,  debugDrawer:IDebugDraw):Float
	{
		if (cp.getDistance() <= 0)
		{
			var cpd:ConstraintPersistentData = cast cp.userPersistentData;
			cpd.frictionSolverFunc.resolveContact(body0, body1, cp, info);
		}
        return 0;
    }
	
	public inline function reset():Void 
	{
		btSeed2 = 0;
	}

    /**
     * Advanced: Override the default contact solving function for contacts, for certain types of rigidbody<br>
     * See RigidBody.contactSolverType and RigidBody.frictionSolverType
     */
    public function setContactSolverFunc(func:ContactSolverFunc, type0:Int, type1:Int):Void
	{
        contactDispatch[type0][type1] = func;
    }

    /**
     * Advanced: Override the default friction solving function for contacts, for certain types of rigidbody<br>
     * See RigidBody.contactSolverType and RigidBody.frictionSolverType
     */
    public function setFrictionSolverFunc(func:ContactSolverFunc, type0:Int, type1:Int):Void
	{
        frictionDispatch[type0][type1] = func;
    }

    public function setRandSeed(seed:Int):Void
	{
        btSeed2 = seed;
    }

    public function getRandSeed():Int
	{
        return btSeed2;
    }
}

//class CustomContactDestroyedCallback extends ContactDestroyedCallback
//{
	//public var solver:SequentialImpulseConstraintSolver;
	//public function new(solver:SequentialImpulseConstraintSolver)
	//{
		//super();
		//this.solver = solver;
	//}
	//
	//override public function contactDestroyed(userPersistentData:Dynamic):Bool
	//{
		//Assert.assert (userPersistentData != null);
		//var cpd:ConstraintPersistentData = cast userPersistentData;
		////btAlignedFree(cpd);
		//this.solver.totalCpd--;
		////printf("totalCpd = %i. DELETED Ptr %x\n",totalCpd,userPersistentData);
		//return true;
	//}
//}

@:final class OrderIndex 
{
	public var manifoldIndex:Int;
	public var pointIndex:Int;
	
	public function new()
	{
		
	}
}