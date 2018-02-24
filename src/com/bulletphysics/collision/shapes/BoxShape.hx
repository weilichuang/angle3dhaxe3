package com.bulletphysics.collision.shapes;
import com.bulletphysics.collision.broadphase.BroadphaseNativeType;
import com.bulletphysics.linearmath.AabbUtil2;
import com.bulletphysics.linearmath.ScalarUtil;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.linearmath.LinearMathUtil;
import angle3d.error.Assert;
import angle3d.math.Vector3f;
import angle3d.math.Vector4f;

/**
 * BoxShape is a box primitive around the origin, its sides axis aligned with length
 * specified by half extents, in local shape coordinates. When used as part of a
 * {CollisionObject} or {RigidBody} it will be an oriented box in world space.
 
 */
class BoxShape extends PolyhedralConvexShape
{
	//help var
	private static var tmpVec:Vector3f = new Vector3f();
	private static var plane:Vector4f = new Vector4f();

	public function new(boxHalfExtents:Vector3f) 
	{
		super();
		
		_shapeType = BroadphaseNativeType.BOX_SHAPE_PROXYTYPE;
		
		//优化前代码
		//var margin:Vector3f = new Vector3f(getMargin(), getMargin(), getMargin());
		//VectorUtil.mul(implicitShapeDimensions, boxHalfExtents, localScaling);
		//implicitShapeDimensions.sub(margin);
		
		//优化后代码
		var margin:Float = getMargin();
		implicitShapeDimensions.x = boxHalfExtents.x * localScaling.x - margin;
		implicitShapeDimensions.y = boxHalfExtents.y * localScaling.y - margin;
		implicitShapeDimensions.z = boxHalfExtents.z * localScaling.z - margin;
	}
	
	
	public inline function getHalfExtentsWithMargin(out:Vector3f):Vector3f
	{
        var halfExtents:Vector3f = getHalfExtentsWithoutMargin(out);
		
        //var margin:Vector3f = new Vector3f();
        //margin.setTo(getMargin(), getMargin(), getMargin());
        //halfExtents.add(margin);
		//优化后代码
		var margin:Float = getMargin();
		halfExtents.x += margin;
		halfExtents.y += margin;
		halfExtents.z += margin;
		
        return halfExtents;
    }

    public inline function getHalfExtentsWithoutMargin(out:Vector3f):Vector3f
	{
        out.copyFrom(implicitShapeDimensions); // changed in Bullet 2.63: assume the scaling and margin are included
        return out;
    }

    override public function localGetSupportingVertex(vec:Vector3f, out:Vector3f):Vector3f 
	{
		var halfExtents:Vector3f = getHalfExtentsWithoutMargin(out);

        var margin:Float = collisionMargin;//getMargin();
        halfExtents.x += margin;
        halfExtents.y += margin;
        halfExtents.z += margin;
		
		if (vec.x < 0)
			halfExtents.x = -halfExtents.x;
			
		if (vec.y < 0)
			halfExtents.y = -halfExtents.y;
			
		if (vec.z < 0)
			halfExtents.z = -halfExtents.z;

        return halfExtents;
	}
	
	override public function localGetSupportingVertexWithoutMargin(vec:Vector3f, out:Vector3f):Vector3f 
	{
		var halfExtents:Vector3f = getHalfExtentsWithoutMargin(out);
		
		if (vec.x < 0)
			halfExtents.x = -halfExtents.x;
			
		if (vec.y < 0)
			halfExtents.y = -halfExtents.y;
			
		if (vec.z < 0)
			halfExtents.z = -halfExtents.z;

        return halfExtents;
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
        //var oldMargin:Vector3f = new Vector3f();
        //oldMargin.setTo(getMargin(), getMargin(), getMargin());
        //var implicitShapeDimensionsWithMargin:Vector3f = new Vector3f();
        //implicitShapeDimensionsWithMargin.add(implicitShapeDimensions, oldMargin);

        //super.setMargin(margin);
		
        //var newMargin:Vector3f = new Vector3f();
        //newMargin.setTo(getMargin(), getMargin(), getMargin());
        //implicitShapeDimensions.sub(implicitShapeDimensionsWithMargin, newMargin);
		
		var oldMargin:Float = collisionMargin;// getMargin();
		
		super.setMargin(margin);
		
		var newMargin:Float = collisionMargin;// getMargin();
		
		implicitShapeDimensions.x += oldMargin - newMargin;
		implicitShapeDimensions.y += oldMargin - newMargin;
		implicitShapeDimensions.z += oldMargin - newMargin;
	}
	
	//TODO optimize
	override public function setLocalScaling(scaling:Vector3f):Void 
	{
		var oldMargin:Vector3f = new Vector3f();
        oldMargin.setTo(getMargin(), getMargin(), getMargin());
        var implicitShapeDimensionsWithMargin:Vector3f = new Vector3f();
        implicitShapeDimensionsWithMargin.addBy(implicitShapeDimensions, oldMargin);
		
        var unScaledImplicitShapeDimensionsWithMargin:Vector3f = new Vector3f();
        LinearMathUtil.div(unScaledImplicitShapeDimensionsWithMargin, implicitShapeDimensionsWithMargin, localScaling);

        super.setLocalScaling(scaling);

        LinearMathUtil.mul(implicitShapeDimensions, unScaledImplicitShapeDimensionsWithMargin, localScaling);
        implicitShapeDimensions.subtractLocal(oldMargin);
	}
	
	override public function getAabb(trans:Transform, aabbMin:Vector3f, aabbMax:Vector3f):Void 
	{
		var margin:Float = collisionMargin;//getMargin();
		AabbUtil2.transformAabb(getHalfExtentsWithoutMargin(tmpVec), margin, trans, aabbMin, aabbMax);
	}
	
	override public function calculateLocalInertia(mass:Float, inertia:Vector3f):Void 
	{
        var halfExtents:Vector3f = getHalfExtentsWithMargin(tmpVec);

        var lx:Float = 2 * halfExtents.x;
        var ly:Float = 2 * halfExtents.y;
        var lz:Float = 2 * halfExtents.z;
		var lx2:Float = lx * lx;
		var ly2:Float = ly * ly;
		var lz2:Float = lz * lz;
		
		var massInv12:Float = mass / 12;

        inertia.setTo(massInv12 * (ly2 + lz2),
					  massInv12 * (lx2 + lz2),
					  massInv12 * (lx2 + ly2));
	}
	
	override public function getPlane(planeNormal:Vector3f, planeSupport:Vector3f, i:Int):Void 
	{
		// this plane might not be aligned...
        getPlaneEquation(plane, i);
        planeNormal.setTo(plane.x, plane.y, plane.z);
		
        tmpVec.negateBy(planeNormal);
        localGetSupportingVertex(tmpVec, planeSupport);
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
        var halfExtents:Vector3f = getHalfExtentsWithoutMargin(tmpVec);

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
                Assert.assert(false);
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
                Assert.assert(false);
        }

        getVertex(edgeVert0, pa);
        getVertex(edgeVert1, pb);
	}
	
	override public function isInside(pt:Vector3f, tolerance:Float):Bool 
	{
		var halfExtents:Vector3f = getHalfExtentsWithoutMargin(tmpVec);

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
				#if debug
                Assert.assert (false);
				#end
        }
	}
}