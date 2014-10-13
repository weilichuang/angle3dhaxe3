package com.bulletphysics.collision.shapes;
import com.bulletphysics.collision.shapes.TriangleCallback;
import com.bulletphysics.linearmath.TransformUtil;
import com.bulletphysics.linearmath.VectorUtil;
import vecmath.Vector3f;

/**
 * StaticPlaneShape simulates an infinite non-moving (static) collision plane.
 *
 * @author weilichuang
 */
class StaticPlaneShape extends ConcaveShape
{
	private var localAabbMin:Vector3f = new Vector3f(0, 0, 0);
	private var localAabbMax:Vector3f = new Vector3f(0, 0, 0);
	
	private var planeNormal:Vector3f = new Vector3f(0, 0, 0);
	private var planeConstant:Float;
	private var localScaling:Vector3f = new Vector3f(0, 0, 0);

	public function new(planeNormal:Vector3f, planeConstant:Float) 
	{
		super();
		
		this.planeNormal.fromVector3f(planeNormal);
		this.planeNormal.normalize();
		
		this.planeConstant = planeConstant;
	}
	
	public function getPlaneNormal(out:Vector3f):Vector3f
	{
		out.fromVector3f(planeNormal);
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
        halfExtents.sub(aabbMax, aabbMin);
        halfExtents.scale(0.5);

        var radius:Float = halfExtents.length();
        var center:Vector3f = new Vector3f();
        center.add(aabbMax, aabbMin);
        center.scale(0.5);

        // this is where the triangles are generated, given AABB and plane equation (normal/constant)

        var tangentDir0:Vector3f = new Vector3f();
		var tangentDir1:Vector3f = new Vector3f();

        // tangentDir0/tangentDir1 can be precalculated
        TransformUtil.planeSpace1(planeNormal, tangentDir0, tangentDir1);

        var supVertex0:Vector3f = new Vector3f(), supVertex1 = new Vector3f();

        var projectedCenter:Vector3f = new Vector3f();
        tmp.scale(planeNormal.dot(center) - planeConstant, planeNormal);
        projectedCenter.sub(center, tmp);

        var triangle:Array<Vector3f> = [new Vector3f(), new Vector3f(), new Vector3f()];

        tmp1.scale(radius, tangentDir0);
        tmp2.scale(radius, tangentDir1);
        VectorUtil.add3(triangle[0], projectedCenter, tmp1, tmp2);

        tmp1.scale(radius, tangentDir0);
        tmp2.scale(radius, tangentDir1);
        tmp.sub(tmp1, tmp2);
        VectorUtil.add(triangle[1], projectedCenter, tmp);

        tmp1.scale(radius, tangentDir0);
        tmp2.scale(radius, tangentDir1);
        tmp.sub(tmp1, tmp2);
        triangle[2].sub(projectedCenter, tmp);

        callback.processTriangle(triangle, 0, 0);

        tmp1.scale(radius, tangentDir0);
        tmp2.scale(radius, tangentDir1);
        tmp.sub(tmp1, tmp2);
        triangle[0].sub(projectedCenter, tmp);

        tmp1.scale(radius, tangentDir0);
        tmp2.scale(radius, tangentDir1);
        tmp.add(tmp1, tmp2);
        triangle[1].sub(projectedCenter, tmp);

        tmp1.scale(radius, tangentDir0);
        tmp2.scale(radius, tangentDir1);
        VectorUtil.add3(triangle[2], projectedCenter, tmp1, tmp2);

        callback.processTriangle(triangle, 0, 1);
	}
	
	
}