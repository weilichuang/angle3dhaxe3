package com.bulletphysics.collision.shapes;
import com.bulletphysics.linearmath.Transform;
import org.angle3d.math.Vector3f;

/**
 * ConvexShape is an abstract shape class. It describes general convex shapes
 * using the {#localGetSupportingVertex localGetSupportingVertex} interface
 * used in combination with GJK or ConvexCast.
 
 */
 //凸面体
class ConvexShape extends CollisionShape
{
	public static inline var MAX_PREFERRED_PENETRATION_DIRECTIONS:Int = 10;

	public function new() 
	{
		super();
	}
	
	public function localGetSupportingVertex(vec:Vector3f, out:Vector3f):Vector3f
	{
		return out;
	}

    public function localGetSupportingVertexWithoutMargin(vec:Vector3f, out:Vector3f):Vector3f
	{
		return out;
	}

    //notice that the vectors should be unit length
    public function batchedUnitVectorGetSupportingVertexWithoutMargin(vectors:Array<Vector3f>,supportVerticesOut:Array<Vector3f>, numVectors:Int):Void
	{
		
	}

    public function getAabbSlow(trans:Transform, aabbMin:Vector3f, aabbMax:Vector3f):Void 
	{
		
	}

    override public function setLocalScaling(scaling:Vector3f):Void 
	{
		
	}

    override public function getLocalScaling(out:Vector3f):Vector3f 
	{
		return out;
	}

    public function getNumPreferredPenetrationDirections():Int 
	{
		return 0;
	}

    public function getPreferredPenetrationDirection(index:Int, penetrationVector:Vector3f):Void 
	{
		
	}
	
}