package com.bulletphysics.collision.shapes;
import com.bulletphysics.collision.broadphase.BroadphaseNativeType;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.linearmath.LinearMathUtil;
import de.polygonal.core.math.Mathematics;
import org.angle3d.math.Matrix3f;
import com.bulletphysics.linearmath.MatrixUtil;
import org.angle3d.math.Vector3f;

/**
 * CapsuleShape represents a capsule around the Y axis, there is also the
 * {CapsuleShapeX} aligned around the X axis and {CapsuleShapeZ} around
 * the Z axis.<p>
 * <p/>
 * The total height is height+2*radius, so the height is just the height between
 * the center of each "sphere" of the capsule caps.<p>
 * <p/>
 * CapsuleShape is a convex hull of two spheres. The {MultiSphereShape} is
 * a more general collision shape that takes the convex hull of multiple sphere,
 * so it can also represent a capsule when just using two spheres.
 * @author weilichuang
 */
class CapsuleShape extends ConvexInternalShape
{
	private var upAxis:Int;

	public function new(radius:Float, height:Float) 
	{
		super();
		_shapeType = BroadphaseNativeType.CAPSULE_SHAPE_PROXYTYPE;
		upAxis = 1;
		implicitShapeDimensions.setTo(radius, 0.5 * height, radius);
	}
	
	override public function localGetSupportingVertexWithoutMargin(vec0:Vector3f, out:Vector3f):Vector3f 
	{
		var supVec:Vector3f = out;
        supVec.setTo(0, 0, 0);

        var maxDot:Float = -1e30;

        var vec:Vector3f = vec0.clone();
        var lenSqr:Float = vec.lengthSquared;
        if (lenSqr < 0.0001) 
		{
            vec.setTo(1, 0, 0);
        } 
		else 
		{
            var rlen:Float = Mathematics.invSqrt(lenSqr);
            vec.scaleLocal(rlen);
        }

        var vtx:Vector3f = new Vector3f();
        var newDot:Float;

        var radius:Float = getRadius();

        var tmp1:Vector3f = new Vector3f();
        var tmp2:Vector3f = new Vector3f();
        var pos:Vector3f = new Vector3f();

        {
            pos.setTo(0, 0, 0);
            LinearMathUtil.setCoord(pos, getUpAxis(), getHalfHeight());

            LinearMathUtil.mul(tmp1, vec, localScaling);
            tmp1.scaleLocal(radius);
            tmp2.scaleBy(getMargin(), vec);
            vtx.addBy(pos, tmp1);
            vtx.subtractLocal(tmp2);
            newDot = vec.dot(vtx);
            if (newDot > maxDot)
			{
                maxDot = newDot;
                supVec.copyFrom(vtx);
            }
        }
        {
            pos.setTo(0, 0, 0);
            LinearMathUtil.setCoord(pos, getUpAxis(), -getHalfHeight());

            LinearMathUtil.mul(tmp1, vec, localScaling);
            tmp1.scaleLocal(radius);
            tmp2.scaleBy(getMargin(), vec);
            vtx.addBy(pos, tmp1);
            vtx.subtractLocal(tmp2);
            newDot = vec.dot(vtx);
            if (newDot > maxDot) 
			{
                maxDot = newDot;
                supVec.copyFrom(vtx);
            }
        }

        return out;
	}
	
	override public function batchedUnitVectorGetSupportingVertexWithoutMargin(vectors:Array<Vector3f>, supportVerticesOut:Array<Vector3f>, numVectors:Int):Void 
	{
		throw "Not Supported yet.";
	}
	
	override public function calculateLocalInertia(mass:Float, inertia:Vector3f):Void 
	{
		// as an approximation, take the inertia of the box that bounds the spheres

        var ident:Transform = new Transform();
        ident.setIdentity();

        var radius:Float = getRadius();

        var halfExtents:Vector3f = new Vector3f();
        halfExtents.setTo(radius, radius, radius);
        LinearMathUtil.setCoord(halfExtents, getUpAxis(), radius + getHalfHeight());

        var margin:Float = BulletGlobals.CONVEX_DISTANCE_MARGIN;

        var lx:Float = 2 * (halfExtents.x + margin);
        var ly:Float = 2 * (halfExtents.y + margin);
        var lz:Float = 2 * (halfExtents.z + margin);
        var x2:Float = lx * lx;
        var y2:Float = ly * ly;
        var z2:Float = lz * lz;
        var scaledmass:Float = mass * 0.08333333;

        inertia.x = scaledmass * (y2 + z2);
        inertia.y = scaledmass * (x2 + z2);
        inertia.z = scaledmass * (x2 + y2);
	}
	
	override public function getAabb(t:Transform, aabbMin:Vector3f, aabbMax:Vector3f):Void 
	{
		var tmp:Vector3f = new Vector3f();

        var halfExtents:Vector3f = new Vector3f();
        halfExtents.setTo(getRadius(), getRadius(), getRadius());
        LinearMathUtil.setCoord(halfExtents, upAxis, getRadius() + getHalfHeight());

        halfExtents.x += getMargin();
        halfExtents.y += getMargin();
        halfExtents.z += getMargin();

        var abs_b:Matrix3f = new Matrix3f();
        abs_b.copyFrom(t.basis);
        MatrixUtil.absolute(abs_b);

        var center:Vector3f = t.origin;
        var extent:Vector3f = new Vector3f();

        abs_b.copyRowTo(0, tmp);
        extent.x = tmp.dot(halfExtents);
        abs_b.copyRowTo(1, tmp);
        extent.y = tmp.dot(halfExtents);
        abs_b.copyRowTo(2, tmp);
        extent.z = tmp.dot(halfExtents);

        aabbMin.subtractBy(center, extent);
        aabbMax.addBy(center, extent);
	}
	
	override public function getName():String 
	{
		return "CapsuleShape";
	}
	
	public function getUpAxis():Int
	{
		return upAxis;
	}
	
	public function getRadius():Float
	{
		var radiusAxis:Int = (upAxis + 2) % 3;
		return LinearMathUtil.getCoord(implicitShapeDimensions, radiusAxis);
	}
	
	public function getHalfHeight():Float
	{
		return LinearMathUtil.getCoord(implicitShapeDimensions, upAxis);
	}
}