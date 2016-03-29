package com.bulletphysics.collision.shapes;
import com.bulletphysics.collision.broadphase.BroadphaseNativeType;
import com.bulletphysics.collision.shapes.TriangleCallback;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.linearmath.TransformUtil;
import com.bulletphysics.linearmath.LinearMathUtil;
import org.angle3d.math.Vector3f;

/**
 * StaticPlaneShape simulates an infinite non-moving (static) collision plane.
 *
 * @author weilichuang
 */
class StaticPlaneShape extends ConcaveShape
{
	private var localAabbMin:Vector3f = new Vector3f();
	private var localAabbMax:Vector3f = new Vector3f();
	
	private var planeNormal:Vector3f = new Vector3f();
	private var planeConstant:Float;
	private var localScaling:Vector3f = new Vector3f(0, 0, 0);

	public function new(planeNormal:Vector3f, planeConstant:Float) 
	{
		super();
		
		_shapeType = BroadphaseNativeType.STATIC_PLANE_PROXYTYPE;
		
		this.planeNormal.copyFrom(planeNormal);
		this.planeNormal.normalizeLocal();
		
		this.planeConstant = planeConstant;
	}
	
	public function getPlaneNormal(out:Vector3f):Vector3f
	{
		out.copyFrom(planeNormal);
		return out;
	}
	
	public function getPlaneConstant():Float
	{
		return planeConstant;
	}
	
	override public function processAllTriangles(callback:TriangleCallback, aabbMin:Vector3f, aabbMax:Vector3f):Void 
	{
		var tmp:Vector3f = new Vector3f();
        var tmp1:Vector3f = new Vector3f();
        var tmp2:Vector3f = new Vector3f();

        var halfExtents:Vector3f = new Vector3f();
        halfExtents.subtractBy(aabbMax, aabbMin);
        halfExtents.scaleLocal(0.5);

        var radius:Float = halfExtents.length;
        var center:Vector3f = new Vector3f();
        center.addBy(aabbMax, aabbMin);
        center.scaleLocal(0.5);

        // this is where the triangles are generated, given AABB and plane equation (normal/constant)

        var tangentDir0:Vector3f = new Vector3f();
		var tangentDir1:Vector3f = new Vector3f();

        // tangentDir0/tangentDir1 can be precalculated
        TransformUtil.planeSpace1(planeNormal, tangentDir0, tangentDir1);

        var projectedCenter:Vector3f = new Vector3f();
        tmp.scaleBy(planeNormal.dot(center) - planeConstant, planeNormal);
        projectedCenter.subtractBy(center, tmp);

        var triangle:Array<Vector3f> = [new Vector3f(), new Vector3f(), new Vector3f()];

        tmp1.scaleBy(radius, tangentDir0);
        tmp2.scaleBy(radius, tangentDir1);
        LinearMathUtil.add3(triangle[0], projectedCenter, tmp1, tmp2);

        tmp1.scaleBy(radius, tangentDir0);
        tmp2.scaleBy(radius, tangentDir1);
        tmp.subtractBy(tmp1, tmp2);
        LinearMathUtil.add(triangle[1], projectedCenter, tmp);

        tmp1.scaleBy(radius, tangentDir0);
        tmp2.scaleBy(radius, tangentDir1);
        tmp.subtractBy(tmp1, tmp2);
        triangle[2].subtractBy(projectedCenter, tmp);

        callback.processTriangle(triangle, 0, 0);

        tmp1.scaleBy(radius, tangentDir0);
        tmp2.scaleBy(radius, tangentDir1);
        tmp.subtractBy(tmp1, tmp2);
        triangle[0].subtractBy(projectedCenter, tmp);

        tmp1.scaleBy(radius, tangentDir0);
        tmp2.scaleBy(radius, tangentDir1);
        tmp.addBy(tmp1, tmp2);
        triangle[1].subtractBy(projectedCenter, tmp);

        tmp1.scaleBy(radius, tangentDir0);
        tmp2.scaleBy(radius, tangentDir1);
        LinearMathUtil.add3(triangle[2], projectedCenter, tmp1, tmp2);

        callback.processTriangle(triangle, 0, 1);
	}
	
	override public function getAabb(t:Transform, aabbMin:Vector3f, aabbMax:Vector3f):Void 
	{
		aabbMin.setTo( -1e30, -1e30, -1e30);
		aabbMax.setTo(1e30, 1e30, 1e30);
	}

	override public function setLocalScaling(scaling:Vector3f):Void 
	{
		localScaling.copyFrom(scaling);
	}
	
	override public function getLocalScaling(out:Vector3f):Vector3f 
	{
		out.copyFrom(localScaling);
		return out;
	}
	
	override public function calculateLocalInertia(mass:Float, inertia:Vector3f):Void 
	{
		//moving concave objects not supported
		inertia.setTo(0, 0, 0);
	}
	
	override public function getName():String 
	{
		return "STATICPLANE";
	}
	
}