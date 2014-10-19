package com.bulletphysics.collision.shapes;
import com.bulletphysics.collision.broadphase.BroadphaseNativeType;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.linearmath.VectorUtil;
import vecmath.Vector3f;

/**
 * Single triangle shape.
 * @author weilichuang
 */
class TriangleShape extends PolyhedralConvexShape
{
	public var vertices1:Array<Vector3f>;

	public function new(p0:Vector3f, p1:Vector3f, p2:Vector3f) 
	{
		super();
		
		this.vertices1 = [new Vector3f(), new Vector3f(), new Vector3f()];
		
		if (p0 != null && p1 != null && p2 != null)
		{
			this.vertices1[0].fromVector3f(p0);
			this.vertices1[1].fromVector3f(p1);
			this.vertices1[2].fromVector3f(p2);
		}
	}
	
	public function init(p0:Vector3f, p1:Vector3f, p2:Vector3f):Void
	{
		this.vertices1[0].fromVector3f(p0);
		this.vertices1[1].fromVector3f(p1);
		this.vertices1[2].fromVector3f(p2);
	}
	
	public function getVertexPtr(index:Int):Vector3f
	{
		return vertices1[index];
	}
	
	override public function getVertex(index:Int,vert:Vector3f):Void
	{
		vert.fromVector3f(vertices1[index]);
	}
	
	override public function getNumVertices():Int
	{
		return 3;
	}
	
	override public function getShapeType():BroadphaseNativeType 
	{
		return BroadphaseNativeType.TRIANGLE_SHAPE_PROXYTYPE;
	}
	
	override public function getNumEdges():Int 
	{
		return 3;
	}
	
	override public function getEdge(i:Int, pa:Vector3f, pb:Vector3f):Void 
	{
		getVertex(i, pa);
		getVertex((i + 1) % 3, pb);
	}
	
	override public function getAabb(trans:Transform, aabbMin:Vector3f, aabbMax:Vector3f):Void 
	{
		getAabbSlow(trans, aabbMin, aabbMax);
	}
	
	override public function localGetSupportingVertexWithoutMargin(dir:Vector3f, out:Vector3f):Vector3f 
	{
		var dots:Vector3f = new Vector3f();
		dots.setTo(dir.dot(vertices1[0]), dir.dot(vertices1[1]), dir.dot(vertices1[2]));
        out.fromVector3f(vertices1[VectorUtil.maxAxis(dots)]);
        return out;
	}
	
	override public function batchedUnitVectorGetSupportingVertexWithoutMargin(vectors:Array<Vector3f>, supportVerticesOut:Array<Vector3f>, numVectors:Int):Void 
	{
		var dots:Vector3f = new Vector3f();

        for (i in 0...numVectors)
		{
            var dir:Vector3f = vectors[i];
            dots.setTo(dir.dot(vertices1[0]), dir.dot(vertices1[1]), dir.dot(vertices1[2]));
            supportVerticesOut[i].fromVector3f(vertices1[VectorUtil.maxAxis(dots)]);
        }
	}
	
	override public function getPlane(planeNormal:Vector3f, planeSupport:Vector3f, i:Int):Void 
	{
		getPlaneEquation(i, planeNormal, planeSupport);
	}
	
	override public function getNumPlanes():Int 
	{
		return 1;
	}
	
	public function calcNormal(normal:Vector3f):Void
	{
		var tmp1:Vector3f = new Vector3f();
        var tmp2:Vector3f = new Vector3f();

        tmp1.sub2(vertices1[1], vertices1[0]);
        tmp2.sub2(vertices1[2], vertices1[0]);

        normal.cross(tmp1, tmp2);
        normal.normalize();
	}
	
	public function getPlaneEquation(i:Int, planeNormal:Vector3f, planeSupport:Vector3f):Void
	{
		calcNormal(planeNormal);
		planeSupport.fromVector3f(vertices1[0]);
	}
	
	override public function calculateLocalInertia(mass:Float, inertia:Vector3f):Void 
	{
		inertia.setTo(0, 0, 0);
	}
	
	override public function isInside(pt:Vector3f, tolerance:Float):Bool 
	{
		var normal:Vector3f = new Vector3f();
        calcNormal(normal);
        // distance to plane
        var dist:Float = pt.dot(normal);
        var planeconst:Float = vertices1[0].dot(normal);
        dist -= planeconst;
        if (dist >= -tolerance && dist <= tolerance) 
		{
            // inside check on edge-planes
            for (i in 0...3)
			{
                var pa:Vector3f = new Vector3f();
				var pb:Vector3f = new Vector3f();
                getEdge(i, pa, pb);
                var edge:Vector3f = new Vector3f();
                edge.sub2(pb, pa);
                var edgeNormal:Vector3f = new Vector3f();
                edgeNormal.cross(edge, normal);
                edgeNormal.normalize();
                /*float*/
                dist = pt.dot(edgeNormal);
                var edgeConst:Float = pa.dot(edgeNormal);
                dist -= edgeConst;
                if (dist < -tolerance)
				{
                    return false;
                }
            }

            return true;
        }

        return false;
	}
	
	override public function getName():String 
	{
		return "Triangle";
	}
	
	override public function getNumPreferredPenetrationDirections():Int 
	{
		return 2;
	}
	
	override public function getPreferredPenetrationDirection(index:Int, penetrationVector:Vector3f):Void 
	{
		calcNormal(penetrationVector);
        if (index != 0) 
		{
            penetrationVector.scale(-1);
        }
	}
}