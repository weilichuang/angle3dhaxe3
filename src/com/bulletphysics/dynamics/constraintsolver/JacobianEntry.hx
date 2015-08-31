package com.bulletphysics.dynamics.constraintsolver;
import com.bulletphysics.linearmath.LinearMathUtil;
import de.polygonal.ds.error.Assert;
import com.vecmath.Matrix3f;
import com.vecmath.Vector3f;

//notes:
// Another memory optimization would be to store m_1MinvJt in the remaining 3 w components
// which makes the btJacobianEntry memory layout 16 bytes
// if you only are interested in angular part, just feed massInvA and massInvB zero

/**
 * Jacobian entry is an abstraction that allows to describe constraints.
 * It can be used in combination with a constraint solver.
 * Can be used to relate the effect of an impulse to the constraint error.
 *
 * @author weilichuang
 */
class JacobianEntry
{
	//protected final BulletStack stack = BulletStack.get();

    public var linearJointAxis:Vector3f = new Vector3f();
    public var aJ:Vector3f = new Vector3f();
    public var bJ:Vector3f = new Vector3f();
    public var m_0MinvJt:Vector3f = new Vector3f();
    public var m_1MinvJt:Vector3f = new Vector3f();
    // Optimization: can be stored in the w/last component of one of the vectors
    public var Adiag:Float;

    public function new()
	{
    }

    /**
     * Constraint between two different rigidbodies.
     */
    public function init( world2A:Matrix3f,world2B:Matrix3f,
                      rel_pos1:Vector3f,rel_pos2:Vector3f,
                      jointAxis:Vector3f,
                      inertiaInvA:Vector3f,
                      massInvA:Float,
                      inertiaInvB:Vector3f,
                      massInvB:Float):Void
	{
        linearJointAxis.copyFrom(jointAxis);

        aJ.cross(rel_pos1, linearJointAxis);
        world2A.transform(aJ);

        bJ.copyFrom(linearJointAxis);
        bJ.negateLocal();
        bJ.cross(rel_pos2, bJ);
        world2B.transform(bJ);

        LinearMathUtil.mul(m_0MinvJt, inertiaInvA, aJ);
        LinearMathUtil.mul(m_1MinvJt, inertiaInvB, bJ);
        Adiag = massInvA + m_0MinvJt.dot(aJ) + massInvB + m_1MinvJt.dot(bJ);

        Assert.assert (Adiag > 0);
    }

    /**
     * Angular constraint between two different rigidbodies.
     */
    public function init2(jointAxis:Vector3f,
						 world2A:Matrix3f,
						 world2B:Matrix3f,
						 inertiaInvA:Vector3f,
						 inertiaInvB:Vector3f):Void 
	{
        linearJointAxis.setTo(0, 0, 0);

        aJ.copyFrom(jointAxis);
        world2A.transform(aJ);

        bJ.copyFrom(jointAxis);
        bJ.negateLocal();
        world2B.transform(bJ);

        LinearMathUtil.mul(m_0MinvJt, inertiaInvA, aJ);
        LinearMathUtil.mul(m_1MinvJt, inertiaInvB, bJ);
        Adiag = m_0MinvJt.dot(aJ) + m_1MinvJt.dot(bJ);

        Assert.assert (Adiag > 0);
    }

    /**
     * Angular constraint between two different rigidbodies.
     */
    public function init3(axisInA:Vector3f,
						  axisInB:Vector3f,
						  inertiaInvA:Vector3f,
						  inertiaInvB:Vector3f):Void
    {
        linearJointAxis.setTo(0, 0, 0);
        aJ.copyFrom(axisInA);

        bJ.copyFrom(axisInB);
        bJ.negateLocal();

        LinearMathUtil.mul(m_0MinvJt, inertiaInvA, aJ);
        LinearMathUtil.mul(m_1MinvJt, inertiaInvB, bJ);
        Adiag = m_0MinvJt.dot(aJ) + m_1MinvJt.dot(bJ);

        Assert.assert (Adiag > 0);
    }

    /**
     * Constraint on one rigidbody.
     */
    public function init4(
						world2A:Matrix3f,
						rel_pos1:Vector3f, 
						rel_pos2:Vector3f,
						jointAxis:Vector3f,
						inertiaInvA:Vector3f,
						massInvA:Float):Void
	{
        linearJointAxis.copyFrom(jointAxis);

        aJ.cross(rel_pos1, jointAxis);
        world2A.transform(aJ);

        bJ.copyFrom(jointAxis);
        bJ.negateLocal();
        bJ.cross(rel_pos2, bJ);
        world2A.transform(bJ);

        LinearMathUtil.mul(m_0MinvJt, inertiaInvA, aJ);
        m_1MinvJt.setTo(0, 0, 0);
        Adiag = massInvA + m_0MinvJt.dot(aJ);

        Assert.assert (Adiag > 0);
    }

    public function getDiagonal():Float
	{
        return Adiag;
    }

    /**
     * For two constraints on the same rigidbody (for example vehicle friction).
     */
    public function getNonDiagonal(jacB:JacobianEntry, massInvA:Float):Float
	{
        var jacA:JacobianEntry = this;
        var lin:Float = massInvA * jacA.linearJointAxis.dot(jacB.linearJointAxis);
        var ang:Float = jacA.m_0MinvJt.dot(jacB.aJ);
        return lin + ang;
    }

    /**
     * For two constraints on sharing two same rigidbodies (for example two contact points between two rigidbodies).
     */
    public function getNonDiagonal2(jacB:JacobianEntry, massInvA:Float, massInvB:Float):Float
	{
        var jacA:JacobianEntry = this;

        var lin:Vector3f = new Vector3f();
        LinearMathUtil.mul(lin, jacA.linearJointAxis, jacB.linearJointAxis);

        var ang0:Vector3f = new Vector3f();
        LinearMathUtil.mul(ang0, jacA.m_0MinvJt, jacB.aJ);

        var ang1:Vector3f = new Vector3f();
        LinearMathUtil.mul(ang1, jacA.m_1MinvJt, jacB.bJ);

        var lin0:Vector3f = new Vector3f();
        lin0.scale2(massInvA, lin);

        var lin1:Vector3f = new Vector3f();
        lin1.scale2(massInvB, lin);

        var sum:Vector3f = new Vector3f();
        LinearMathUtil.add4(sum, ang0, ang1, lin0, lin1);

        return sum.x + sum.y + sum.z;
    }

    public function getRelativeVelocity(linvelA:Vector3f, angvelA:Vector3f, linvelB:Vector3f, angvelB:Vector3f):Float
	{
        var linrel:Vector3f = new Vector3f();
        linrel.sub2(linvelA, linvelB);

        var angvela:Vector3f = new Vector3f();
        LinearMathUtil.mul(angvela, angvelA, aJ);

        var angvelb:Vector3f = new Vector3f();
        LinearMathUtil.mul(angvelb, angvelB, bJ);

        LinearMathUtil.mul(linrel, linrel, linearJointAxis);

        angvela.addLocal(angvelb);
        angvela.addLocal(linrel);

        var rel_vel2:Float = angvela.x + angvela.y + angvela.z;
        return rel_vel2 + BulletGlobals.FLT_EPSILON;
    }
	
}