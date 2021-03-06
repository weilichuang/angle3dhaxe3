package com.bulletphysics.collision.shapes;
import com.bulletphysics.collision.broadphase.BroadphaseNativeType;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.linearmath.LinearMathUtil;
import org.angle3d.math.Vector3f;

/**
 * Single triangle shape.
 
 */
class TriangleShape extends PolyhedralConvexShape
{
	public var vertices1:Array<Vector3f>;

	private var tmp1:Vector3f = new Vector3f();
    private var tmp2:Vector3f = new Vector3f();
	
	public function new(p0:Vector3f, p1:Vector3f, p2:Vector3f) 
	{
		super();
		
		_shapeType = BroadphaseNativeType.TRIANGLE_SHAPE_PROXYTYPE;
		
		this.vertices1 = [new Vector3f(), new Vector3f(), new Vector3f()];
		
		if (p0 != null && p1 != null && p2 != null)
		{
			this.vertices1[0].copyFrom(p0);
			this.vertices1[1].copyFrom(p1);
			this.vertices1[2].copyFrom(p2);
		}
	}
	
	public function init(p0:Vector3f, p1:Vector3f, p2:Vector3f):Void
	{
		this.vertices1[0].copyFrom(p0);
		this.vertices1[1].copyFrom(p1);
		this.vertices1[2].copyFrom(p2);
	}
	
	public function getVertexPtr(index:Int):Vector3f
	{
		return vertices1[index];
	}
	
	override public function getVertex(index:Int,vert:Vector3f):Void
	{
		vert.copyFrom(vertices1[index]);
	}
	
	override public function getNumVertices():Int
	{
		return 3;
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
		tmp1.setTo(dir.dot(vertices1[0]), dir.dot(vertices1[1]), dir.dot(vertices1[2]));
        out.copyFrom(vertices1[LinearMathUtil.maxAxis(tmp1)]);
        return out;
	}
	
	override public function batchedUnitVectorGetSupportingVertexWithoutMargin(vectors:Array<Vector3f>, supportVerticesOut:Array<Vector3f>, numVectors:Int):Void 
	{
        for (i in 0...numVectors)
		{
            var dir:Vector3f = vectors[i];
            tmp1.setTo(dir.dot(vertices1[0]), dir.dot(vertices1[1]), dir.dot(vertices1[2]));
            supportVerticesOut[i].copyFrom(vertices1[LinearMathUtil.maxAxis(tmp1)]);
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
        tmp1.subtractBy(vertices1[1], vertices1[0]);
        tmp2.subtractBy(vertices1[2], vertices1[0]);

        normal.crossBy(tmp1, tmp2);
        normal.normalizeLocal();
	}
	
	public function getPlaneEquation(i:Int, planeNormal:Vector3f, planeSupport:Vector3f):Void
	{
		calcNormal(planeNormal);
		planeSupport.copyFrom(vertices1[0]);
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
			var pa:Vector3f = new Vector3f();
			var pb:Vector3f = new Vector3f();
			var edge:Vector3f = new Vector3f();
			var edgeNormal:Vector3f = new Vector3f();
            // inside check on edge-planes
            for (i in 0...3)
			{
                getEdge(i, pa, pb);
                
                edge.subtractBy(pb, pa);
                
                edgeNormal.crossBy(edge, normal);
                edgeNormal.normalizeLocal();
				
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
            penetrationVector.scaleLocal(-1);
        }
	}
}