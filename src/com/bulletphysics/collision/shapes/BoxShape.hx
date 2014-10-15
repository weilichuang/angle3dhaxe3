package com.bulletphysics.collision.shapes;
import com.bulletphysics.collision.broadphase.BroadphaseNativeType;
import com.bulletphysics.linearmath.AabbUtil2;
import com.bulletphysics.linearmath.ScalarUtil;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.linearmath.VectorUtil;
import com.bulletphysics.util.Assert;
import vecmath.Vector3f;
import vecmath.Vector4f;

/**
 * BoxShape is a box primitive around the origin, its sides axis aligned with length
 * specified by half extents, in local shape coordinates. When used as part of a
 * {@link CollisionObject} or {@link RigidBody} it will be an oriented box in world space.
 * @author weilichuang
 */
class BoxShape extends PolyhedralConvexShape
{

	public function new(boxHalfExtents:Vector3f) 
	{
		super();
		
		var margin:Vector3f = new Vector3f(getMargin(), getMargin(), getMargin());
		VectorUtil.mul(implicitShapeDimensions, boxHalfExtents, localScaling);
		implicitShapeDimensions.sub(margin);
	}
	
	
	public function getHalfExtentsWithMargin(out:Vector3f):Vector3f
	{
        var halfExtents:Vector3f = getHalfExtentsWithoutMargin(out);
        var margin:Vector3f = new Vector3f();
        margin.setTo(getMargin(), getMargin(), getMargin());
        halfExtents.add(margin);
        return out;
    }

    public function getHalfExtentsWithoutMargin(out:Vector3f):Vector3f
	{
        out.fromVector3f(implicitShapeDimensions); // changed in Bullet 2.63: assume the scaling and margin are included
        return out;
    }
	
	override public function getShapeType():BroadphaseNativeType 
	{
		return BroadphaseNativeType.BOX_SHAPE_PROXYTYPE;
	}

    override public function localGetSupportingVertex(vec0:Vector3f, out:Vector3f):Vector3f 
	{
		var halfExtents:Vector3f = getHalfExtentsWithoutMargin(out);

        var margin:Float = getMargin();
        halfExtents.x += margin;
        halfExtents.y += margin;
        halfExtents.z += margin;

        out.setTo(
                ScalarUtil.fsel(vec0.x, halfExtents.x, -halfExtents.x),
                ScalarUtil.fsel(vec0.y, halfExtents.y, -halfExtents.y),
                ScalarUtil.fsel(vec0.z, halfExtents.z, -halfExtents.z));
        return out;
	}
	
	override public function localGetSupportingVertexWithoutMargin(vec:Vector3f, out:Vector3f):Vector3f 
	{
		var halfExtents:Vector3f = getHalfExtentsWithoutMargin(out);

        out.setTo(
                ScalarUtil.fsel(vec.x, halfExtents.x, -halfExtents.x),
                ScalarUtil.fsel(vec.y, halfExtents.y, -halfExtents.y),
                ScalarUtil.fsel(vec.z, halfExtents.z, -halfExtents.z));
        return out;
	}
		
	override public function batchedUnitVectorGetSupportingVertexWithoutMargin(vectors:Array<Vector3f>, supportVerticesOut:Array<Vector3f>, numVectors:Int):Void 
	{
		var halfExtents:Vector3f = getHalfExtentsWithoutMargin(new Vector3f());

        for (i in 0...numVectors) 
		{
            var vec:Vector3f = vectors[i];
            supportVerticesOut[i].setTo(ScalarUtil.fsel(vec.x, halfExtents.x, -halfExtents.x),
										ScalarUtil.fsel(vec.y, halfExtents.y, -halfExtents.y),
										ScalarUtil.fsel(vec.z, halfExtents.z, -halfExtents.z));
        }
	}
	
	override public function setMargin(margin:Float):Void 
	{
		// correct the implicitShapeDimensions for the margin
        var oldMargin:Vector3f = new Vector3f();
        oldMargin.setTo(getMargin(), getMargin(), getMargin());
        var implicitShapeDimensionsWithMargin:Vector3f = new Vector3f();
        implicitShapeDimensionsWithMargin.add(implicitShapeDimensions, oldMargin);

        super.setMargin(margin);
		
        var newMargin:Vector3f = new Vector3f();
        newMargin.setTo(getMargin(), getMargin(), getMargin());
        implicitShapeDimensions.sub(implicitShapeDimensionsWithMargin, newMargin);
	}
	
	override public function setLocalScaling(scaling:Vector3f):Void 
	{
		var oldMargin:Vector3f = new Vector3f();
        oldMargin.setTo(getMargin(), getMargin(), getMargin());
        var implicitShapeDimensionsWithMargin:Vector3f = new Vector3f();
        implicitShapeDimensionsWithMargin.add(implicitShapeDimensions, oldMargin);
        var unScaledImplicitShapeDimensionsWithMargin:Vector3f = new Vector3f();
        VectorUtil.div(unScaledImplicitShapeDimensionsWithMargin, implicitShapeDimensionsWithMargin, localScaling);

        super.setLocalScaling(scaling);

        VectorUtil.mul(implicitShapeDimensions, unScaledImplicitShapeDimensionsWithMargin, localScaling);
        implicitShapeDimensions.sub(oldMargin);
	}
	
	override public function getAabb(trans:Transform, aabbMin:Vector3f, aabbMax:Vector3f):Void 
	{
		AabbUtil2.transformAabb(getHalfExtentsWithoutMargin(new Vector3f()), getMargin(), trans, aabbMin, aabbMax);
	}
	
	override public function calculateLocalInertia(mass:Float, inertia:Vector3f):Void 
	{
		//btScalar margin = btScalar(0.);
        var halfExtents:Vector3f = getHalfExtentsWithMargin(new Vector3f());

        var lx:Float = 2 * halfExtents.x;
        var ly:Float = 2 * halfExtents.y;
        var lz:Float = 2 * halfExtents.z;

        inertia.setTo(mass / 12 * (ly * ly + lz * lz),
					mass / 12 * (lx * lx + lz * lz),
					mass / 12 * (lx * lx + ly * ly));
	}
	
	override public function getPlane(planeNormal:Vector3f, planeSupport:Vector3f, i:Int):Void 
	{
		// this plane might not be aligned...
        var plane:Vector4f = new Vector4f();
        getPlaneEquation(plane, i);
        planeNormal.setTo(plane.x, plane.y, plane.z);
        var tmp:Vector3f = new Vector3f();
        tmp.negate(planeNormal);
        localGetSupportingVertex(tmp, planeSupport);
	}

	override public function getNumPlanes():Int 
	{
		return 6;
	}
	
	override public function getNumVertices():Int 
	{
		return 8;
	}
	
	override public function getNumEdges():Int 
	{
		return 12;
	}
	
	override public function getVertex(i:Int, vtx:Vector3f):Void 
	{
		var halfExtents:Vector3f = getHalfExtentsWithoutMargin(new Vector3f());

        vtx.setTo(halfExtents.x * (1 - (i & 1)) - halfExtents.x * (i & 1),
                  halfExtents.y * (1 - ((i & 2) >> 1)) - halfExtents.y * ((i & 2) >> 1),
                  halfExtents.z * (1 - ((i & 4) >> 2)) - halfExtents.z * ((i & 4) >> 2));
	}

    public function getPlaneEquation(plane:Vector4f, i:Int):Void
	{
        var halfExtents:Vector3f = getHalfExtentsWithoutMargin(new Vector3f());

        switch (i) 
		{
            case 0:
                plane.setTo(1, 0, 0, -halfExtents.x);
            case 1:
                plane.setTo(-1, 0, 0, -halfExtents.x);
            case 2:
                plane.setTo(0, 1, 0, -halfExtents.y);
            case 3:
                plane.setTo(0, -1, 0, -halfExtents.y);
            case 4:
                plane.setTo(0, 0, 1, -halfExtents.z);
            case 5:
                plane.setTo(0, 0, -1, -halfExtents.z);
            default:
                com.bulletphysics.util.Assert.assert(false);
        }
    }
	
	override public function getEdge(i:Int, pa:Vector3f, pb:Vector3f):Void 
	{
		var edgeVert0:Int = 0;
        var edgeVert1:Int = 0;

        switch (i) 
		{
            case 0:
                edgeVert0 = 0;
                edgeVert1 = 1;
            case 1:
                edgeVert0 = 0;
                edgeVert1 = 2;
            case 2:
                edgeVert0 = 1;
                edgeVert1 = 3;
            case 3:
                edgeVert0 = 2;
                edgeVert1 = 3;
            case 4:
                edgeVert0 = 0;
                edgeVert1 = 4;
            case 5:
                edgeVert0 = 1;
                edgeVert1 = 5;
            case 6:
                edgeVert0 = 2;
                edgeVert1 = 6;
            case 7:
                edgeVert0 = 3;
                edgeVert1 = 7;
            case 8:
                edgeVert0 = 4;
                edgeVert1 = 5;
            case 9:
                edgeVert0 = 4;
                edgeVert1 = 6;
            case 10:
                edgeVert0 = 5;
                edgeVert1 = 7;
            case 11:
                edgeVert0 = 6;
                edgeVert1 = 7;
            default:
                com.bulletphysics.util.Assert.assert(false);
        }

        getVertex(edgeVert0, pa);
        getVertex(edgeVert1, pb);
	}
	
	override public function isInside(pt:Vector3f, tolerance:Float):Bool 
	{
		var halfExtents:Vector3f = getHalfExtentsWithoutMargin(new Vector3f());

        //btScalar minDist = 2*tolerance;

        var result:Bool =
                        (pt.x <= (halfExtents.x + tolerance)) &&
                        (pt.x >= (-halfExtents.x - tolerance)) &&
                        (pt.y <= (halfExtents.y + tolerance)) &&
                        (pt.y >= (-halfExtents.y - tolerance)) &&
                        (pt.z <= (halfExtents.z + tolerance)) &&
                        (pt.z >= (-halfExtents.z - tolerance));

        return result;
	}

	override public function getName():String 
	{
		return "Box";
	}
	
	override public function getNumPreferredPenetrationDirections():Int 
	{
		return 6;
	}

    override public function getPreferredPenetrationDirection(index:Int, penetrationVector:Vector3f):Void 
	{
		switch (index) 
		{
            case 0:
                penetrationVector.setTo(1, 0, 0);
            case 1:
                penetrationVector.setTo(-1, 0, 0);
            case 2:
                penetrationVector.setTo(0, 1, 0);
            case 3:
                penetrationVector.setTo(0, -1, 0);
            case 4:
                penetrationVector.setTo(0, 0, 1);
            case 5:
                penetrationVector.setTo(0, 0, -1);
            default:
                Assert.assert (false);
        }
	}
}