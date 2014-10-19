package com.bulletphysics.collision.shapes;
import com.bulletphysics.linearmath.AabbUtil2;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.linearmath.VectorUtil;
import com.bulletphysics.util.Assert;
import de.polygonal.core.math.Mathematics;
import vecmath.Vector3f;

/**
 * PolyhedralConvexShape is an internal interface class for polyhedral convex shapes.
 * @author weilichuang
 */
class PolyhedralConvexShape extends ConvexInternalShape
{
	private static var _directions:Array<Vector3f> = [new Vector3f(1, 0, 0),
													new Vector3f(0, 1, 0),
													new Vector3f(0, 0, 1),
													new Vector3f(-1, 0, 0),
													new Vector3f(0, -1, 0),
													new Vector3f(0, 0, -1)];
	
	private static var _supporting:Array<Vector3f> = [new Vector3f(0, 0, 0),
													new Vector3f(0, 0, 0),
													new Vector3f(0, 0, 0),
													new Vector3f(0, 0, 0),
													new Vector3f(0, 0, 0),
													new Vector3f(0, 0, 0)];
	
	private var localAabbMin:Vector3f = new Vector3f(1, 1, 1);
	private var localAabbMax:Vector3f = new Vector3f( -1, -1, -1);
	private var isLocalAabbValid:Bool = false;

	public function new() 
	{
		super();
	}
	
	override public function localGetSupportingVertexWithoutMargin(vec0:Vector3f, out:Vector3f):Vector3f 
	{
        var supVec:Vector3f = out;
        supVec.setTo(0, 0, 0);

        var maxDot:Float = -1e30;

        var vec:Vector3f = vec0.clone();
        var lenSqr:Float = vec.lengthSquared();
        if (lenSqr < 0.0001)
		{
            vec.setTo(1, 0, 0);
        } 
		else
		{
            var rlen:Float = Mathematics.invSqrt(lenSqr);
            vec.scale(rlen);
        }

        var vtx:Vector3f = new Vector3f();
        var newDot:Float;
        for (i in 0...getNumVertices()) 
		{
            getVertex(i, vtx);
            newDot = vec.dot(vtx);
            if (newDot > maxDot)
			{
                maxDot = newDot;
                supVec = vtx;
            }
        }

        return out;
	}
	
	override public function batchedUnitVectorGetSupportingVertexWithoutMargin(vectors:Array<Vector3f>, supportVerticesOut:Array<Vector3f>, numVectors:Int):Void 
	{
		var vtx:Vector3f = new Vector3f();
        var newDot:Float;

        // JAVA NOTE: rewritten as code used W coord for temporary usage in Vector3
        // TODO: optimize it
        var wcoords:Array<Float> = [];
        for (i in 0...numVectors)
		{
            // TODO: used w in vector3:
            //supportVerticesOut[i].w = -1e30f;
            wcoords[i] = -1e30;
        }

        for (j in 0...numVectors) 
		{
            var vec:Vector3f = vectors[j];

            for (i in 0...getNumVertices())
			{
                getVertex(i, vtx);
                newDot = vec.dot(vtx);
                //if (newDot > supportVerticesOut[j].w)
                if (newDot > wcoords[j]) 
				{
                    //WARNING: don't swap next lines, the w component would get overwritten!
                    supportVerticesOut[j].fromVector3f(vtx);
                    //supportVerticesOut[j].w = newDot;
                    wcoords[j] = newDot;
                }
            }
        }
	}
	
	override public function calculateLocalInertia(mass:Float, inertia:Vector3f):Void 
	{
		// not yet, return box inertia

        var margin:Float = getMargin();

        var ident:Transform = new Transform();
        var aabbMin:Vector3f = new Vector3f();
		var aabbMax:Vector3f = new Vector3f();
        getAabb(ident, aabbMin, aabbMax);

        var halfExtents:Vector3f = new Vector3f();
        halfExtents.sub2(aabbMax, aabbMin);
        halfExtents.scale(0.5);

        var lx:Float = 2 * (halfExtents.x + margin);
        var ly:Float = 2 * (halfExtents.y + margin);
        var lz:Float = 2 * (halfExtents.z + margin);
        var x2:Float = lx * lx;
        var y2:Float = ly * ly;
        var z2:Float = lz * lz;
        var scaledmass:Float = mass * 0.08333333;

        inertia.setTo(y2 + z2, x2 + z2, x2 + y2);
        inertia.scale(scaledmass);
	}
	
	private function getNonvirtualAabb(trans:Transform, aabbMin:Vector3f, aabbMax:Vector3f, margin:Float):Void
	{
		// lazy evaluation of local aabb
		Assert.assert (isLocalAabbValid);
		
		AabbUtil2.transformAabb2(localAabbMin, localAabbMax, margin, trans, aabbMin, aabbMax);
	}
	
	override public function getAabb(trans:Transform, aabbMin:Vector3f, aabbMax:Vector3f):Void 
	{
		getNonvirtualAabb(trans, aabbMin, aabbMax, getMargin());
	}
	
	private function _PolyhedralConvexShape_getAabb(trans:Transform, aabbMin:Vector3f, aabbMax:Vector3f):Void 
	{
		getNonvirtualAabb(trans, aabbMin, aabbMax, getMargin());
	}
	
	public function recalcLocalAabb():Void
	{
		isLocalAabbValid = true;

        //#if 1

        batchedUnitVectorGetSupportingVertexWithoutMargin(_directions, _supporting, 6);

        for (i in 0...3) 
		{
            VectorUtil.setCoord(localAabbMax, i, VectorUtil.getCoord(_supporting[i], i) + collisionMargin);
            VectorUtil.setCoord(localAabbMin, i, VectorUtil.getCoord(_supporting[i + 3], i) - collisionMargin);
        }

        //#else
        //for (int i=0; i<3; i++) {
        //	Vector3f vec = new Vector3f();
        //	vec.set(0f, 0f, 0f);
        //	VectorUtil.setCoord(vec, i, 1f);
        //	Vector3f tmp = localGetSupportingVertex(vec, new Vector3f());
        //	VectorUtil.setCoord(localAabbMax, i, VectorUtil.getCoord(tmp, i) + collisionMargin);
        //	VectorUtil.setCoord(vec, i, -1f);
        //	localGetSupportingVertex(vec, tmp);
        //	VectorUtil.setCoord(localAabbMin, i, VectorUtil.getCoord(tmp, i) - collisionMargin);
        //}
        //#endif
	}
	
	override public function setLocalScaling(scaling:Vector3f):Void 
	{
		super.setLocalScaling(scaling);
		recalcLocalAabb();
	}
	
	public function getNumVertices():Int
	{
		return 0;
	}
	
	public function getNumEdges():Int
	{
		return 0;
	}
	
	public function getEdge(i:Int, pa:Vector3f, pb:Vector3f):Void
	{
		
	}
	
	public function getVertex(i:Int, vtx:Vector3f):Void
	{
		
	}
	
	public function getNumPlanes():Int
	{
		return 0;
	}
	
	public function getPlane(planeNormal:Vector3f, planeSupport:Vector3f, i:Int):Void
	{
		
	}
	
	public function isInside(pt:Vector3f, tolerance:Float):Bool
	{
		return true;
	}
}