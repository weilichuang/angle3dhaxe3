package com.bulletphysics.linearmath;
import com.bulletphysics.linearmath.MatrixUtil;
import org.angle3d.math.FastMath;
import org.angle3d.math.Matrix3f;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;

/**
 * Utility functions for transforms.
 
 */
class TransformUtil
{

	public static inline var SIMDSQRT12:Float = 0.7071067811865475244008443621048490;
    public static inline var ANGULAR_MOTION_THRESHOLD:Float = 0.35355339059327376220042218105242;// 0.5 * BulletGlobals.SIMD_HALF_PI;

    public static inline function recipSqrt(x:Float):Float 
	{
        return 1 / Math.sqrt(x);  /* reciprocal square root */
    }

    public static function planeSpace1(n:Vector3f, p:Vector3f, q:Vector3f):Void 
	{
        if (FastMath.abs(n.z) > SIMDSQRT12) 
		{
            // choose p in y-z plane
            var a:Float = n.y * n.y + n.z * n.z;
            var k:Float = recipSqrt(a);
            p.setTo(0, -n.z * k, n.y * k);
            // set q = n x p
            q.setTo(a * k, -n.x * p.z, n.x * p.y);
        } 
		else 
		{
            // choose p in x-y plane
            var a:Float = n.x * n.x + n.y * n.y;
            var k:Float = recipSqrt(a);
            p.setTo(-n.y * k, n.x * k, 0);
            // set q = n x p
            q.setTo(-n.z * p.y, n.z * p.x, a * k);
        }
    }

	private static var axis:Vector3f = new Vector3f();
	private static var dorn:Quaternion = new Quaternion();
	private static var tmpQuat:Quaternion = new Quaternion();
	private static var predictedOrn:Quaternion = new Quaternion();
    public static inline function integrateTransform(curTrans:Transform, linvel:Vector3f, angvel:Vector3f, 
											timeStep:Float, predictedTransform:Transform):Void 
	{
        predictedTransform.origin.scaleAddBy(timeStep, linvel, curTrans.origin);
//	//#define QUATERNION_DERIVATIVE
//	#ifdef QUATERNION_DERIVATIVE
//		btQuaternion predictedOrn = curTrans.getRotation();
//		predictedOrn += (angvel * predictedOrn) * (timeStep * btScalar(0.5));
//		predictedOrn.normalize();
//	#else
        // Exponential map
        // google for "Practical Parameterization of Rotations Using the Exponential Map", F. Sebastian Grassia

        var fAngle:Float = angvel.length;

        // limit the angular motion
        if (fAngle * timeStep > ANGULAR_MOTION_THRESHOLD) 
		{
            fAngle = ANGULAR_MOTION_THRESHOLD / timeStep;
        }

        if (fAngle < 0.001)
		{
            // use Taylor's expansions of sync function
            axis.scaleBy(0.5 * timeStep - (timeStep * timeStep * timeStep) * (0.020833333333) * fAngle * fAngle, angvel);
        } 
		else 
		{
            // sync(fAngle) = sin(c*fAngle)/t
            axis.scaleBy(Math.sin(0.5 * fAngle * timeStep) / fAngle, angvel);
        }
        
        dorn.setTo(axis.x, axis.y, axis.z, Math.cos(fAngle * timeStep * 0.5));
        var orn0:Quaternion = curTrans.getRotation(tmpQuat);

        predictedOrn.multBy(dorn, orn0);
        predictedOrn.normalizeLocal();
//  #endif
        predictedTransform.setRotation(predictedOrn);
    }

    public static function calculateVelocity(transform0:Transform, transform1:Transform, 
											timeStep:Float, linVel:Vector3f, angVel:Vector3f):Void 
	{
        linVel.subtractBy(transform1.origin, transform0.origin);
        linVel.scaleLocal(1 / timeStep);

        var axis:Vector3f = new Vector3f();
        var angle:Array<Float> = [0];
        calculateDiffAxisAngle(transform0, transform1, axis, angle);
        angVel.scaleBy(angle[0] / timeStep, axis);
    }

    public static function calculateDiffAxisAngle(transform0:Transform, transform1:Transform,
												axis:Vector3f, angle:Array<Float>):Void 
	{
// #ifdef USE_QUATERNION_DIFF
//		btQuaternion orn0 = transform0.getRotation();
//		btQuaternion orn1a = transform1.getRotation();
//		btQuaternion orn1 = orn0.farthest(orn1a);
//		btQuaternion dorn = orn1 * orn0.inverse();
// #else
        var tmp:Matrix3f = new Matrix3f();
        tmp.copyFrom(transform0.basis);
        tmp.invertLocal();

        var dmat:Matrix3f = new Matrix3f();
        dmat.multBy(transform1.basis, tmp);

        var dorn:Quaternion = new Quaternion();
        MatrixUtil.getRotation(dmat, dorn);
// #endif

        // floating point inaccuracy can lead to w component > 1..., which breaks

        dorn.normalizeLocal();

        angle[0] = QuaternionUtil.getAngle(dorn);
        axis.setTo(dorn.x, dorn.y, dorn.z);
        // TODO: probably not needed
        //axis[3] = btScalar(0.);

        // check for axis length
        var len:Float = axis.lengthSquared;
        if (len < BulletGlobals.FLT_EPSILON * BulletGlobals.FLT_EPSILON)
		{
            axis.setTo(1, 0, 0);
        }
		else 
		{
            axis.scaleLocal(1 / Math.sqrt(len));
        }
    }
	
}