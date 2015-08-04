package com.bulletphysics.collision.shapes;

import com.bulletphysics.BulletGlobals;
import com.bulletphysics.collision.broadphase.BroadphaseNativeType;
import com.bulletphysics.linearmath.LinearMathUtil;
import com.bulletphysics.util.ObjectArrayList;
import de.polygonal.ds.error.Assert;
import flash.Vector;
import com.vecmath.Vector3f;

/**
 * ConvexHullShape implements an implicit convex hull of an array of vertices.
 * Bullet provides a general and fast collision detector for convex shapes based
 * on GJK and EPA using localGetSupportingVertex.
 * 
 * @author jezek2
 */
class ConvexHullShape extends PolyhedralConvexShape 
{

	private var points:ObjectArrayList<Vector3f> = new ObjectArrayList<Vector3f>();
	
	/**
	 * TODO: This constructor optionally takes in a pointer to points. Each point is assumed to be 3 consecutive float (x,y,z), the striding defines the number of bytes between each point, in memory.
	 * It is easier to not pass any points in the constructor, and just add one point at a time, using addPoint.
	 * ConvexHullShape make an internal copy of the points.
	 */
	// TODO: make better constuctors (ByteBuffer, etc.)
	public function new(points:ObjectArrayList<Vector3f>)
	{
		super();
		
		for (i in 0...points.size())
		{
			this.points.add(points.getQuick(i).clone());
		}
		
		recalcLocalAabb();
	}
	
	override public function setLocalScaling(scaling:Vector3f):Void 
	{
		localScaling.fromVector3f(scaling);
		recalcLocalAabb();
	}
	
	public function addPoint(point:Vector3f):Void
	{
		points.add(point.clone());
		recalcLocalAabb();
	}

	public function getPoints():ObjectArrayList<Vector3f>
	{
		return points;
	}

	public function getNumPoints():Int
	{
		return points.size();
	}
	
	override public function localGetSupportingVertexWithoutMargin(vec0:Vector3f, out:Vector3f):Vector3f 
	{
		var supVec:Vector3f = out;
		supVec.setTo(0, 0, 0);
		var newDot:Float;
		var maxDot:Float = -1e30;

		var vec:Vector3f = vec0.clone();
		var lenSqr:Float = vec.lengthSquared();
		if (lenSqr < 0.0001) 
		{
			vec.setTo(1, 0, 0);
		}
		else
		{
			var rlen:Float = 1 / Math.sqrt(lenSqr);
			vec.scale(rlen);
		}


		var vtx:Vector3f = new Vector3f();
		for (i in 0...points.size())
		{
			LinearMathUtil.mul(vtx, points.getQuick(i), localScaling);

			newDot = vec.dot(vtx);
			if (newDot > maxDot) 
			{
				maxDot = newDot;
				supVec.fromVector3f(vtx);
			}
		}
		return out;
	}
	
	override public function batchedUnitVectorGetSupportingVertexWithoutMargin(vectors:Array<Vector3f>, supportVerticesOut:Array<Vector3f>, numVectors:Int):Void 
	{
		var newDot:Float;

		// JAVA NOTE: rewritten as code used W coord for temporary usage in Vector3
		// TODO: optimize it
		var wcoords:Vector<Float> = new Vector(numVectors);

		// use 'w' component of supportVerticesOut?
		{
			for (i in 0...numVectors) 
			{
				//supportVerticesOut[i][3] = btScalar(-1e30);
				wcoords[i] = -1e30;
			}
		}
		var vtx:Vector3f = new Vector3f();
		for (i in 0...points.size()) 
		{
			LinearMathUtil.mul(vtx, points.getQuick(i), localScaling);

			for (j in 0...numVectors)
			{
				var vec:Vector3f = vectors[j];

				newDot = vec.dot(vtx);
				//if (newDot > supportVerticesOut[j][3])
				if (newDot > wcoords[j])
				{
					// WARNING: don't swap next lines, the w component would get overwritten!
					supportVerticesOut[j].fromVector3f(vtx);
					//supportVerticesOut[j][3] = newDot;
					wcoords[j] = newDot;
				}
			}
		}
	}
	
	override public function localGetSupportingVertex(vec:Vector3f, out:Vector3f):Vector3f 
	{
		var supVertex:Vector3f = localGetSupportingVertexWithoutMargin(vec, out);

		if (getMargin() != 0)
		{
			var vecnorm:Vector3f = vec.clone();
			if (vecnorm.lengthSquared() < (BulletGlobals.FLT_EPSILON * BulletGlobals.FLT_EPSILON))
			{
				vecnorm.setTo(-1, -1, -1);
			}
			vecnorm.normalize();
			supVertex.scaleAdd(getMargin(), vecnorm, supVertex);
		}
		return out;
	}

	/**
	 * Currently just for debugging (drawing), perhaps future support for algebraic continuous collision detection.
	 * Please note that you can debug-draw ConvexHullShape with the Raytracer Demo.
	 */
	override public function getNumVertices():Int 
	{
		return points.size();
	}
	
	override public function getNumEdges():Int 
	{
		return points.size();
	}

	override public function getEdge(i:Int, pa:Vector3f, pb:Vector3f):Void 
	{
		var index0:Int = i % points.size();
		var index1:Int = (i + 1) % points.size();
		LinearMathUtil.mul(pa, points.getQuick(index0), localScaling);
		LinearMathUtil.mul(pb, points.getQuick(index1), localScaling);
	}

	override public function getVertex(i:Int, vtx:Vector3f):Void 
	{
		LinearMathUtil.mul(vtx, points.getQuick(i), localScaling);
	}

	override public function getNumPlanes():Int 
	{
		return 0;
	}

	override public function getPlane(planeNormal:Vector3f, planeSupport:Vector3f, i:Int):Void 
	{
		Assert.assert(false);
	}

	override public function isInside(pt:Vector3f, tolerance:Float):Bool 
	{
		Assert.assert(false);
		return false;
	}

	override public function getShapeType():BroadphaseNativeType
	{
		return BroadphaseNativeType.CONVEX_HULL_SHAPE_PROXYTYPE;
	}

	override public function getName():String
	{
		return "Convex";
	}
}
