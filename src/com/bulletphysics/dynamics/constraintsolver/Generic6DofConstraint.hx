package com.bulletphysics.dynamics.constraintsolver;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.linearmath.LinearMathUtil;
import org.angle3d.math.Matrix3f;
import org.angle3d.math.Vector3f;

/**
 * Generic6DofConstraint between two rigidbodies each with a pivot point that descibes
 * the axis location in local space.<p>
 * <p/>
 * Generic6DofConstraint can leave any of the 6 degree of freedom "free" or "locked".
 * Currently this limit supports rotational motors.<br>
 * <p/>
 * <ul>
 * <li>For linear limits, use {#setLinearUpperLimit}, {#setLinearLowerLimit}.
 * You can set the parameters with the {TranslationalLimitMotor} structure accsesible
 * through the {#getTranslationalLimitMotor} method.
 * At this moment translational motors are not supported. May be in the future.</li>
 * <p/>
 * <li>For angular limits, use the {RotationalLimitMotor} structure for configuring
 * the limit. This is accessible through {#getRotationalLimitMotor} method,
 * this brings support for limit parameters and motors.</li>
 * <p/>
 * <li>Angulars limits have these possible ranges:
 * <table border="1">
 * <tr>
 * <td><b>AXIS</b></td>
 * <td><b>MIN ANGLE</b></td>
 * <td><b>MAX ANGLE</b></td>
 * </tr><tr>
 * <td>X</td>
 * <td>-PI</td>
 * <td>PI</td>
 * </tr><tr>
 * <td>Y</td>
 * <td>-PI/2</td>
 * <td>PI/2</td>
 * </tr><tr>
 * <td>Z</td>
 * <td>-PI/2</td>
 * <td>PI/2</td>
 * </tr>
 * </table>
 * </li>
 * </ul>
 
 */
class Generic6DofConstraint extends TypedConstraint
{

	private var frameInA:Transform = new Transform(); //!< the constraint space w.r.t body A
    private var frameInB:Transform = new Transform(); //!< the constraint space w.r.t body B

    private var jacLinear:Array<JacobianEntry> = [new JacobianEntry(), new JacobianEntry(), new JacobianEntry()]; //!< 3 orthogonal linear constraints
    private var jacAng:Array<JacobianEntry> = [new JacobianEntry(), new JacobianEntry(), new JacobianEntry()]; //!< 3 orthogonal angular constraints

    private var linearLimits:TranslationalLimitMotor = new TranslationalLimitMotor();

    private var angularLimits:Array<RotationalLimitMotor> = [new RotationalLimitMotor(), new RotationalLimitMotor(), new RotationalLimitMotor()];

    private var timeStep:Float;
    private var calculatedTransformA:Transform = new Transform();
    private var calculatedTransformB:Transform = new Transform();
    private var calculatedAxisAngleDiff:Vector3f = new Vector3f();
    private var calculatedAxis:Array<Vector3f> = [new Vector3f(), new Vector3f(), new Vector3f()];

    private var anchorPos:Vector3f = new Vector3f(); // point betwen pivots of bodies A and B to solve linear axes
	
	private var calculatedLinearDiff:Vector3f = new Vector3f();

    public var useLinearReferenceFrameA:Bool;

	public function new()
	{
		super(TypedConstraintType.D6_CONSTRAINT_TYPE);
		useLinearReferenceFrameA = true;
	}
	
	
    public function init2(rbA:RigidBody, rbB:RigidBody, frameInA:Transform, frameInB:Transform, useLinearReferenceFrameA:Bool)
	{
        this.init(TypedConstraintType.D6_CONSTRAINT_TYPE, rbA, rbB);
        this.frameInA.fromTransform(frameInA);
        this.frameInB.fromTransform(frameInB);
        this.useLinearReferenceFrameA = useLinearReferenceFrameA;
    }

    private static function getMatrixElem(mat:Matrix3f, index:Int):Float
	{
        var i:Int = index % 3;
        var j:Int = Std.int(index / 3);
        return mat.getElement(i, j);
    }

    /**
     * MatrixToEulerXYZ from http://www.geometrictools.com/LibFoundation/Mathematics/Wm4Matrix3.inl.html
     */
    private static function matrixToEulerXYZ(mat:Matrix3f, xyz:Vector3f):Bool
	{
        //	// rot =  cy*cz          -cy*sz           sy
        //	//        cz*sx*sy+cx*sz  cx*cz-sx*sy*sz -cy*sx
        //	//       -cx*cz*sy+sx*sz  cz*sx+cx*sy*sz  cx*cy
        //

        if (getMatrixElem(mat, 2) < 1.0)
		{
            if (getMatrixElem(mat, 2) > -1.0)
			{
                xyz.x = Math.atan2(-getMatrixElem(mat, 5), getMatrixElem(mat, 8));
                xyz.y = Math.asin(getMatrixElem(mat, 2));
                xyz.z = Math.atan2(-getMatrixElem(mat, 1), getMatrixElem(mat, 0));
                return true;
            } 
			else 
			{
                // WARNING.  Not unique.  XA - ZA = -atan2(r10,r11)
                xyz.x = -Math.atan2(getMatrixElem(mat, 3), getMatrixElem(mat, 4));
                xyz.y = -BulletGlobals.SIMD_HALF_PI;
                xyz.z = 0.0;
                return false;
            }
        } 
		else 
		{
            // WARNING.  Not unique.  XAngle + ZAngle = atan2(r10,r11)
            xyz.x = Math.atan2(getMatrixElem(mat, 3), getMatrixElem(mat, 4));
            xyz.y = BulletGlobals.SIMD_HALF_PI;
            xyz.z = 0.0;
        }

        return false;
    }
	
	/**
	 * tests linear limits
	 */
	private function calculateLinearInfo():Void
	{
		calculatedLinearDiff.subtractBy(calculatedTransformB.origin, calculatedTransformA.origin);

		var basisInv:Matrix3f = new Matrix3f();
		basisInv.copyFrom(calculatedTransformA.basis);
		basisInv.invertLocal();
		basisInv.multVecLocal(calculatedLinearDiff);    // t = this*t      (t is the param)

		linearLimits.currentLinearDiff.copyFrom(calculatedLinearDiff);
		for(i in 0...3)
		{
			linearLimits.testLimitValue(i, LinearMathUtil.getCoord(calculatedLinearDiff, i) );
		}
	}

    /**
     * Calcs the euler angles between the two bodies.
     */
    private function calculateAngleInfo():Void
	{
        var mat:Matrix3f = new Matrix3f();

        var relative_frame:Matrix3f = new Matrix3f();
        mat.copyFrom(calculatedTransformA.basis);
		mat.invertLocal();
        relative_frame.multBy(mat, calculatedTransformB.basis);

        matrixToEulerXYZ(relative_frame, calculatedAxisAngleDiff);

        // in euler angle mode we do not actually constrain the angular velocity
        // along the axes axis[0] and axis[2] (although we do use axis[1]) :
        //
        //    to get			constrain w2-w1 along		...not
        //    ------			---------------------		------
        //    d(angle[0])/dt = 0	ax[1] x ax[2]			ax[0]
        //    d(angle[1])/dt = 0	ax[1]
        //    d(angle[2])/dt = 0	ax[0] x ax[1]			ax[2]
        //
        // constraining w2-w1 along an axis 'a' means that a'*(w2-w1)=0.
        // to prove the result for angle[0], write the expression for angle[0] from
        // GetInfo1 then take the derivative. to prove this for angle[2] it is
        // easier to take the euler rate expression for d(angle[2])/dt with respect
        // to the components of w and set that to 0.

        var axis0:Vector3f = new Vector3f();
        calculatedTransformB.basis.copyColumnTo(0, axis0);

        var axis2:Vector3f = new Vector3f();
        calculatedTransformA.basis.copyColumnTo(2, axis2);

        calculatedAxis[1].crossBy(axis2, axis0);
        calculatedAxis[0].crossBy(calculatedAxis[1], axis2);
        calculatedAxis[2].crossBy(axis0, calculatedAxis[1]);

        //    if(m_debugDrawer)
        //    {
        //
        //    	char buff[300];
        //		sprintf(buff,"\n X: %.2f ; Y: %.2f ; Z: %.2f ",
        //		m_calculatedAxisAngleDiff[0],
        //		m_calculatedAxisAngleDiff[1],
        //		m_calculatedAxisAngleDiff[2]);
        //    	m_debugDrawer->reportErrorWarning(buff);
        //    }
    }

    /**
     * Calcs global transform of the offsets.<p>
     * Calcs the global transform for the joint offset for body A an B, and also calcs the agle differences between the bodies.
     * <p/>
     * See also: Generic6DofConstraint.getCalculatedTransformA, Generic6DofConstraint.getCalculatedTransformB, Generic6DofConstraint.calculateAngleInfo
     */
    public function calculateTransforms():Void
	{
        rbA.getCenterOfMassTransformTo(calculatedTransformA);
        calculatedTransformA.mul(frameInA);

        rbB.getCenterOfMassTransformTo(calculatedTransformB);
        calculatedTransformB.mul(frameInB);

		calculateLinearInfo();
        calculateAngleInfo();
    }

    private function buildLinearJacobian(jacLinear_index:Int, normalWorld:Vector3f, pivotAInW:Vector3f, pivotBInW:Vector3f):Void
	{
        var mat1:Matrix3f = rbA.getCenterOfMassTransformTo(new Transform()).basis;
        mat1.transposeLocal();

        var mat2:Matrix3f = rbB.getCenterOfMassTransformTo(new Transform()).basis;
        mat2.transposeLocal();

        var tmp1:Vector3f = new Vector3f();
        tmp1.subtractBy(pivotAInW, rbA.getCenterOfMassPosition());

        var tmp2:Vector3f = new Vector3f();
        tmp2.subtractBy(pivotBInW, rbB.getCenterOfMassPosition());

        jacLinear[jacLinear_index].init(
                mat1,
                mat2,
                tmp1,
                tmp2,
                normalWorld,
                rbA.getInvInertiaDiagLocal(),
                rbA.getInvMass(),
                rbB.getInvInertiaDiagLocal(),
                rbB.getInvMass());
    }

    private function buildAngularJacobian(jacAngular_index:Int, jointAxisW:Vector3f):Void
	{
        var mat1:Matrix3f = rbA.getCenterOfMassTransformTo(new Transform()).basis;
        mat1.transposeLocal();

        var mat2:Matrix3f = rbB.getCenterOfMassTransformTo(new Transform()).basis;
        mat2.transposeLocal();

        jacAng[jacAngular_index].init2(jointAxisW,
                mat1,
                mat2,
                rbA.getInvInertiaDiagLocal(),
                rbB.getInvInertiaDiagLocal());
    }

    /**
     * Test angular limit.<p>
     * Calculates angular correction and returns true if limit needs to be corrected.
     * Generic6DofConstraint.buildJacobian must be called previously.
     */
    public function testAngularLimitMotor(axis_index:Int):Bool
	{
        var angle:Float = LinearMathUtil.getCoord(calculatedAxisAngleDiff, axis_index);

        // test limits
        angularLimits[axis_index].testLimitValue(angle);
        return angularLimits[axis_index].needApplyTorques();
    }
	
	/**
	 * Test linear limit.<p>
	 * Calculates linear correction and returns true if limit needs to be corrected.
	 * Generic6DofConstraint.buildJacobian must be called previously.
	 */
	public function testLinearLimitMotor(axis_index:Int):Bool
	{
		var diff:Float = LinearMathUtil.getCoord(calculatedLinearDiff, axis_index);

		// test limits
		linearLimits.testLimitValue(axis_index, diff); 
		return linearLimits.needApplyForces(axis_index);
	}
	
	override public function buildJacobian():Void 
	{
		// Clear accumulated impulses for the next simulation step
        linearLimits.accumulatedImpulse.setTo(0, 0, 0);
        for (i in 0...3) 
		{
            angularLimits[i].accumulatedImpulse = 0;
        }

        // calculates transform
        calculateTransforms();

        var tmpVec:Vector3f = new Vector3f();

        //  const btVector3& pivotAInW = m_calculatedTransformA.getOrigin();
        //  const btVector3& pivotBInW = m_calculatedTransformB.getOrigin();
        calcAnchorPos();
        var pivotAInW:Vector3f = anchorPos.clone();
        var pivotBInW:Vector3f = anchorPos.clone();

        // not used here
        //    btVector3 rel_pos1 = pivotAInW - m_rbA.getCenterOfMassPosition();
        //    btVector3 rel_pos2 = pivotBInW - m_rbB.getCenterOfMassPosition();

        var normalWorld:Vector3f = new Vector3f();
        // linear part
        for (i in 0...3)
		{
            if ( testLinearLimitMotor(i))
			{
                if (useLinearReferenceFrameA) 
				{
                    calculatedTransformA.basis.copyColumnTo(i, normalWorld);
                }
				else
				{
                    calculatedTransformB.basis.copyColumnTo(i, normalWorld);
                }

                buildLinearJacobian(i, normalWorld,
                        pivotAInW, pivotBInW);

            }
        }

        // angular part
        for (i in 0...3)
		{
            // calculates error angle
            if (testAngularLimitMotor(i)) 
			{
                this.getAxis(i, normalWorld);
                // Create angular atom
                buildAngularJacobian(/*jacAng[i]*/i, normalWorld);
            }
        }
	}
	
	override public function solveConstraint(timeStep:Float):Void 
	{
		this.timeStep = timeStep;

        //calculateTransforms();

        // linear

        var pointInA:Vector3f = calculatedTransformA.origin.clone();
        var pointInB:Vector3f = calculatedTransformB.origin.clone();

        var jacDiagABInv:Float;
        var linear_axis:Vector3f = new Vector3f();
        for (i in 0...3)
		{
            if (linearLimits.needApplyForces(i))
			{
                jacDiagABInv = 1 / jacLinear[i].getDiagonal();

                if (useLinearReferenceFrameA)
				{
                    calculatedTransformA.basis.copyColumnTo(i, linear_axis);
                } 
				else 
				{
                    calculatedTransformB.basis.copyColumnTo(i, linear_axis);
                }

                linearLimits.solveLinearAxis(
                        this.timeStep,
                        jacDiagABInv,
                        rbA, pointInA,
                        rbB, pointInB,
                        i, linear_axis, anchorPos);

            }
        }

        // angular
        var angular_axis:Vector3f = new Vector3f();
        var angularJacDiagABInv:Float;
        for (i in 0...3) 
		{
            if (angularLimits[i].needApplyTorques()) 
			{
                // get axis
                getAxis(i, angular_axis);

                angularJacDiagABInv = 1 / jacAng[i].getDiagonal();

                angularLimits[i].solveAngularLimits(this.timeStep, angular_axis, angularJacDiagABInv, rbA, rbB);
            }
        }
	}

    public function updateRHS(timeStep:Float):Void
	{
    }

    /**
     * Get the rotation axis in global coordinates.
     * Generic6DofConstraint.buildJacobian must be called previously.
     */
    public function getAxis(axis_index:Int, out:Vector3f):Vector3f
	{
        out.copyFrom(calculatedAxis[axis_index]);
        return out;
    }

    /**
     * Get the relative Euler angle.
     * Generic6DofConstraint.buildJacobian must be called previously.
     */
    public function getAngle(axis_index:Int):Float
	{
        return LinearMathUtil.getCoord(calculatedAxisAngleDiff, axis_index);
    }

    /**
     * Gets the global transform of the offset for body A.<p>
     * See also: Generic6DofConstraint.getFrameOffsetA, Generic6DofConstraint.getFrameOffsetB, Generic6DofConstraint.calculateAngleInfo.
     */
    public function getCalculatedTransformA(out:Transform):Transform
	{
        out.fromTransform(calculatedTransformA);
        return out;
    }

    /**
     * Gets the global transform of the offset for body B.<p>
     * See also: Generic6DofConstraint.getFrameOffsetA, Generic6DofConstraint.getFrameOffsetB, Generic6DofConstraint.calculateAngleInfo.
     */
    public function getCalculatedTransformB(out:Transform):Transform
	{
        out.fromTransform(calculatedTransformB);
        return out;
    }

    public function getFrameOffsetA(out:Transform):Transform
	{
        out.fromTransform(frameInA);
        return out;
    }

    public function getFrameOffsetB(out:Transform):Transform
	{
        out.fromTransform(frameInB);
        return out;
    }

    public function setLinearLowerLimit(linearLower:Vector3f):Void
	{
        linearLimits.lowerLimit.copyFrom(linearLower);
    }

    public function setLinearUpperLimit(linearUpper:Vector3f):Void
	{
        linearLimits.upperLimit.copyFrom(linearUpper);
    }

    public function setAngularLowerLimit(angularLower:Vector3f):Void
	{
        angularLimits[0].loLimit = angularLower.x;
        angularLimits[1].loLimit = angularLower.y;
        angularLimits[2].loLimit = angularLower.z;
    }

    public function setAngularUpperLimit(angularUpper:Vector3f):Void
	{
        angularLimits[0].hiLimit = angularUpper.x;
        angularLimits[1].hiLimit = angularUpper.y;
        angularLimits[2].hiLimit = angularUpper.z;
    }

    /**
     * Retrieves the angular limit informacion.
     */
    public function getRotationalLimitMotor(index:Int):RotationalLimitMotor
	{
        return angularLimits[index];
    }

    /**
     * Retrieves the limit informacion.
     */
    public function getTranslationalLimitMotor():TranslationalLimitMotor
	{
        return linearLimits;
    }

    /**
     * first 3 are linear, next 3 are angular
     */
    public function setLimit(axis:Int, lo:Float, hi:Float):Void
	{
        if (axis < 3) 
		{
            LinearMathUtil.setCoord(linearLimits.lowerLimit, axis, lo);
            LinearMathUtil.setCoord(linearLimits.upperLimit, axis, hi);
        } 
		else 
		{
            angularLimits[axis - 3].loLimit = lo;
            angularLimits[axis - 3].hiLimit = hi;
        }
    }

    /**
     * Test limit.<p>
     * - free means upper &lt; lower,<br>
     * - locked means upper == lower<br>
     * - limited means upper &gt; lower<br>
     * - limitIndex: first 3 are linear, next 3 are angular
     */
    public function isLimited(limitIndex:Int):Bool
	{
        if (limitIndex < 3)
		{
            return linearLimits.isLimited(limitIndex);
        }
        return angularLimits[limitIndex - 3].isLimited();
    }

    // overridable
    public function calcAnchorPos():Void
	{
        var imA:Float = rbA.getInvMass();
        var imB:Float = rbB.getInvMass();
        var weight:Float;
        if (imB == 0)
		{
            weight = 1;
        } 
		else
		{
            weight = imA / (imA + imB);
        }
        var pA:Vector3f = calculatedTransformA.origin;
        var pB:Vector3f = calculatedTransformB.origin;

        var tmp1:Vector3f = new Vector3f();
        var tmp2:Vector3f = new Vector3f();

        tmp1.scaleBy(weight, pA);
        tmp2.scaleBy(1 - weight, pB);
        anchorPos.addBy(tmp1, tmp2);
    }
}