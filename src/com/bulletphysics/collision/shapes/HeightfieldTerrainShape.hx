package com.bulletphysics.collision.shapes ;

import com.bulletphysics.collision.broadphase.BroadphaseNativeType;
import com.bulletphysics.collision.shapes.ConcaveShape;
import com.bulletphysics.collision.shapes.ScalarType;
import com.bulletphysics.collision.shapes.TriangleCallback;
import com.bulletphysics.linearmath.MatrixUtil;
import com.bulletphysics.linearmath.Transform;
import flash.Vector;
import org.angle3d.math.Matrix3f;
import org.angle3d.math.Vector3f;


class HeightfieldTerrainShape extends ConcaveShape 
{

	public static inline var XAXIS:Int = 0;
	public static inline var YAXIS:Int = 1;
	public static inline var ZAXIS:Int = 2;

	private var m_localAabbMin:Vector3f = new Vector3f();
	private var m_localAabbMax:Vector3f = new Vector3f();
	private var m_localOrigin:Vector3f = new Vector3f();

	// /terrain data
	private var m_heightStickWidth:Int;
	private var m_heightStickLength:Int;
	private var m_minHeight:Float;
	private var m_maxHeight:Float;
	private var m_width:Float;
	private var m_length:Float;
	private var m_heightScale:Float;
	private var m_heightfieldDataFloat:Array<Float>;
	private var m_heightDataType:ScalarType;
	private var m_flipQuadEdges:Bool;
	private var m_useDiamondSubdivision:Bool;
	private var m_upAxis:Int;
	private var m_localScaling:Vector3f = new Vector3f();

	public function new(heightStickWidth:Int, heightStickLength:Int, heightfieldData:Array<Float>, heightScale:Float, minHeight:Float, maxHeight:Float, upAxis:Int, flipQuadEdges:Bool)
	{
		super();
		_shapeType = BroadphaseNativeType.TERRAIN_SHAPE_PROXYTYPE;
		initialize(heightStickWidth, heightStickLength, heightfieldData, heightScale, minHeight, maxHeight, upAxis, ScalarType.FLOAT, flipQuadEdges);
	}

	private function initialize(heightStickWidth:Int, heightStickLength:Int, heightfieldData:Array<Float>, heightScale:Float, minHeight:Float, maxHeight:Float, upAxis:Int,f:ScalarType, flipQuadEdges:Bool):Void
	{
		m_heightStickWidth = heightStickWidth;
		m_heightStickLength = heightStickLength;
		m_minHeight = minHeight*heightScale;
		m_maxHeight = maxHeight*heightScale;
		m_width = (heightStickWidth - 1);
		m_length = (heightStickLength - 1);
		m_heightScale = heightScale;
		m_heightfieldDataFloat = heightfieldData;
		m_heightDataType = ScalarType.FLOAT;
		m_flipQuadEdges = flipQuadEdges;
		m_useDiamondSubdivision = false;
		m_upAxis = upAxis;
		m_localScaling.setTo(1., 1., 1.);

		// determine min/max axis-aligned bounding box (aabb) values
		switch (m_upAxis)
		{
			case 0: 
			{
				m_localAabbMin.setTo(m_minHeight, 0, 0);
				m_localAabbMax.setTo(m_maxHeight, m_width, m_length);
			}
			case 1: 
			{
				m_localAabbMin.setTo(0, m_minHeight, 0);
				m_localAabbMax.setTo(m_width, m_maxHeight, m_length);
			}
			case 2:
			{
				m_localAabbMin.setTo(0, 0, m_minHeight);
				m_localAabbMax.setTo(m_width, m_length, m_maxHeight);
			}
		}

		// remember origin (defined as exact middle of aabb)
		// m_localOrigin = btScalar(0.5) * (m_localAabbMin + m_localAabbMax);

		m_localOrigin.copyFrom(m_localAabbMin);
		m_localOrigin.addLocal(m_localAabbMax);
		m_localOrigin.x = m_localOrigin.x * 0.5;
		m_localOrigin.y = m_localOrigin.y * 0.5;
		m_localOrigin.z = m_localOrigin.z * 0.5;

	}
	
	override public function processAllTriangles(callback:TriangleCallback, aabbMin:Vector3f, aabbMax:Vector3f):Void 
	{
		var localAabbMin:Vector3f = new Vector3f();

		localAabbMin.x = aabbMin.x * (1. / m_localScaling.x);
		localAabbMin.y = aabbMin.y * (1. / m_localScaling.y);
		localAabbMin.z = aabbMin.z * (1. / m_localScaling.z);

		var localAabbMax:Vector3f = new Vector3f();
		localAabbMax.x = aabbMax.x * (1. / m_localScaling.x);
		localAabbMax.y = aabbMax.y * (1. / m_localScaling.y);
		localAabbMax.z = aabbMax.z * (1. / m_localScaling.z);

		localAabbMin.addLocal(m_localOrigin);
		localAabbMax.addLocal(m_localOrigin);

		// quantize the aabbMin and aabbMax, and adjust the start/end ranges
		var quantizedAabbMin:Vector<Int> = new Vector<Int>(3);
		var quantizedAabbMax:Vector<Int> = new Vector<Int>(3);
		quantizeWithClamp(quantizedAabbMin, localAabbMin);
		quantizeWithClamp(quantizedAabbMax, localAabbMax);

		// expand the min/max quantized values
		// this is to catch the case where the input aabb falls between grid points!
		for (i in 0...3)
		{
			quantizedAabbMin[i] = quantizedAabbMin[i] - 1;
			quantizedAabbMax[i] = quantizedAabbMax[i] + 1;
		}

		var startX:Int = 0;
		var endX:Int = m_heightStickWidth - 1;
		var startJ:Int = 0;
		var endJ:Int = m_heightStickLength - 1;

		switch (m_upAxis)
		{
			case 0: 
			{
				if (quantizedAabbMin[1] > startX)
					startX = quantizedAabbMin[1];
				if (quantizedAabbMax[1] < endX)
					endX = quantizedAabbMax[1];
				if (quantizedAabbMin[2] > startJ)
					startJ = quantizedAabbMin[2];
				if (quantizedAabbMax[2] < endJ)
					endJ = quantizedAabbMax[2];
			}
			case 1: 
			{
				if (quantizedAabbMin[0] > startX)
					startX = quantizedAabbMin[0];
				if (quantizedAabbMax[0] < endX)
					endX = quantizedAabbMax[0];
				if (quantizedAabbMin[2] > startJ)
					startJ = quantizedAabbMin[2];
				if (quantizedAabbMax[2] < endJ)
					endJ = quantizedAabbMax[2];
			}

			case 2:
			{
				if (quantizedAabbMin[0] > startX)
					startX = quantizedAabbMin[0];
				if (quantizedAabbMax[0] < endX)
					endX = quantizedAabbMax[0];
				if (quantizedAabbMin[1] > startJ)
					startJ = quantizedAabbMin[1];
				if (quantizedAabbMax[1] < endJ)
					endJ = quantizedAabbMax[1];
			}
		}

		for (j in startJ...endJ)
		{
			for (x in startX...endX)
			{
				// Vector3f vertices[3];
				var vertices:Array<Vector3f> = new Array<Vector3f>();
				vertices[0] = new Vector3f();
				vertices[1] = new Vector3f();
				vertices[2] = new Vector3f();
				
				// XXX
				if (m_flipQuadEdges || (m_useDiamondSubdivision && (((j + x) & 1) != 0)))
				{
					// first triangle
					getVertex(x, j, vertices[0]);
					getVertex(x + 1, j, vertices[1]);
					getVertex(x + 1, j + 1, vertices[2]);
					callback.processTriangle(vertices, x, j);
					// callback->processTriangle(vertices,x,j);
					// second triangle
					getVertex(x, j, vertices[0]);
					getVertex(x + 1, j + 1, vertices[1]);
					getVertex(x, j + 1, vertices[2]);
					// callback->processTriangle(vertices,x,j);
                                        callback.processTriangle(vertices, x, j);
				} 
				else
				{
					// first triangle
					getVertex(x, j, vertices[0]);
					getVertex(x, j + 1, vertices[1]);
					getVertex(x + 1, j, vertices[2]);
					// callback->processTriangle(vertices,x,j);
                                        callback.processTriangle(vertices, x, j);
					// second triangle
					getVertex(x + 1, j, vertices[0]);
					getVertex(x, j + 1, vertices[1]);
					getVertex(x + 1, j + 1, vertices[2]);
					// callback->processTriangle(vertices,x,j);
                                        callback.processTriangle(vertices, x, j);
				}
			}
		}
	}

	// / this returns the vertex in bullet-local coordinates
	private function getVertex(x:Int, y:Int, vertex:Vector3f):Void
	{
		var height:Float = getRawHeightFieldValue(x, y);

		switch (m_upAxis)
		{
			case 0: 
				vertex.setTo(height - m_localOrigin.x, (-m_width / 2.0) + x, (-m_length / 2.0) + y);
			case 1: 
				vertex.setTo((-m_width / 2.0) + x, height - m_localOrigin.y, (-m_length / 2.0) + y);
			case 2: 
				vertex.setTo((-m_width / 2.0) + x, (-m_length / 2.0) + y, height - m_localOrigin.z);
		}

		vertex.x = vertex.x * m_localScaling.x;
		vertex.y = vertex.y * m_localScaling.y;
		vertex.z = vertex.z * m_localScaling.z;
	}
	
	override public function calculateLocalInertia(mass:Float, inertia:Vector3f):Void 
	{
		inertia.setTo(0, 0, 0);
	}

	override public function getAabb(t:Transform, aabbMin:Vector3f, aabbMax:Vector3f):Void 
	{
		var halfExtents:Vector3f = new Vector3f();
		halfExtents.copyFrom(m_localAabbMax);
		halfExtents.subtractLocal(m_localAabbMin);
		halfExtents.x = halfExtents.x * m_localScaling.x * 0.5;
		halfExtents.y = halfExtents.y * m_localScaling.y * 0.5;
		halfExtents.z = halfExtents.z * m_localScaling.z * 0.5;

		/*Vector3f localOrigin(0, 0, 0);
		localOrigin[m_upAxis] = (m_minHeight + m_maxHeight) * 0.5f; XXX
		localOrigin *= m_localScaling;*/

		var abs_b:Matrix3f = t.basis.clone();
		MatrixUtil.absolute(abs_b);

		var tmp:Vector3f = new Vector3f();

		var center:Vector3f = t.origin.clone();
		var extent:Vector3f = new Vector3f();
		abs_b.copyRowTo(0, tmp);
		extent.x = tmp.dot(halfExtents);
		abs_b.copyRowTo(1, tmp);
		extent.y = tmp.dot(halfExtents);
		abs_b.copyRowTo(2, tmp);
		extent.z = tmp.dot(halfExtents);

		var margin:Vector3f = new Vector3f();
		margin.setTo(getMargin(), getMargin(), getMargin());
		extent.addLocal(margin);

		aabbMin.subtractBy(center, extent);
		aabbMax.addBy(center, extent);
	}
	
	override public function getLocalScaling(out:Vector3f):Vector3f 
	{
		return m_localScaling;
	}
	
	override public function getName():String 
	{
		return "Terrain";
	}

	// / This returns the "raw" (user's initial) height, not the actual height.
	// / The actual height needs to be adjusted to be relative to the center
	// / of the heightfield's AABB.

	private function getRawHeightFieldValue(x:Int, y:Int):Float
	{
		return m_heightfieldDataFloat[(y * m_heightStickWidth) + x] * m_heightScale;
	}

	public static function getQuantized(x:Float):Int
	{
		if (x < 0.0) 
		{
			return Std.int(x - 0.5);
		}
		return Std.int(x + 0.5);
	}

	// / given input vector, return quantized version
	/**
	 * This routine is basically determining the gridpoint indices for a given input vector, answering the question: "which gridpoint is closest to the provided point?".
	 *
	 * "with clamp" means that we restrict the point to be in the heightfield's axis-aligned bounding box.
	 */
	private function quantizeWithClamp(out:Vector<Int>, clampedPoint:Vector3f):Void
	{

		/*
		 * btVector3 clampedPoint(point); XXX
		clampedPoint.setMax(m_localAabbMin);
		clampedPoint.setMin(m_localAabbMax);

		 * clampedPoint.clampMax(m_localAabbMax,);
		clampedPoint.clampMax(m_localAabbMax);
		clampedPoint.clampMax(m_localAabbMax);

		clampedPoint.clampMin(m_localAabbMin);
		clampedPoint.clampMin(m_localAabbMin); ///CLAMPS
		clampedPoint.clampMin(m_localAabbMin);*/

		out[0] = getQuantized(clampedPoint.x);
		out[1] = getQuantized(clampedPoint.y);
		out[2] = getQuantized(clampedPoint.z);
	}
}
