package com.bulletphysics.dynamics.constraintsolver;
import com.bulletphysics.collision.narrowphase.ManifoldPoint;

/**
 * Contact solving function.
 * @author weilichuang
 */
interface ContactSolverFunc
{
	function resolveContact(body1:RigidBody, body2:RigidBody, contactPoint:ManifoldPoint, info:ContactSolverInfo):Float;
}