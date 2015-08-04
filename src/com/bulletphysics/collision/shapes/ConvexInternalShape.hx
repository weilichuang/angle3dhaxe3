package com.bulletphysics.collision.shapes;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.linearmath.LinearMathUtil;
import com.bulletphysics.linearmath.MatrixUtil;
import com.vecmath.Vector3f;

/**
 * ConvexInternalShape is an internal base class, shared by most convex shape implementations.
 * @author weilichuang
 */
class ConvexInternalShape extends ConvexShape
{
	private var localScaling:Vector3f = new Vector3f(1, 1, 1);
	private var implicitShapeDimensions:Vector3f = new Vector3f();
	private var collisionMargin:Float = BulletGlobals.CONVEX_DISTANCE_MARGIN;

	public function new() 
	{
		super();
	}
	
	override public function getAabb(t:Transform, aabbMin:Vector3f, aabbMax:Vector3f):Void 
	{
		getAabbSlow(t, aabbMin, aabbMax);
	}
	
	override public function getAabbSlow(trans:Transform, aabbMin:Vector3f, aabbMax:Vector3f):Void 
	{
		var margin:Float = getMargin();
        var vec:Vector3f = new Vector3f();
        var tmp1:Vector3f = new Vector3f();
        var tmp2:Vector3f = new Vector3f();

        for (i in 0...3) 
		{
            vec.setTo(0, 0, 0);
			
            LinearMathUtil.setCoord(vec, i, 1);

            MatrixUtil.transposeTransform(tmp1, vec, trans.basis);
			
            localGetSupportingVertex(tmp1, tmp2);

            trans.transform(tmp2);

            LinearMathUtil.setCoord(aabbMax, i, LinearMathUtil.getCoord(tmp2, i) + margin);

            LinearMathUtil.setCoord(vec, i, -1);

            MatrixUtil.transposeTransform(tmp1, vec, trans.basis);
            localGetSupportingVertex(tmp1, tmp2);
            trans.transform(tmp2);

            LinearMathUtil.setCoord(aabbMin, i, LinearMathUtil.getCoord(tmp2, i) - margin);
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
	
	override public function setLocalScaling(scaling:Vector3f):Void
	{
        localScaling.absolute(scaling);
    }

    override public function getLocalScaling(out:Vector3f):Vector3f
	{
        out.fromVector3f(localScaling);
        return out;
    }

    override public function getMargin():Float
	{
        return collisionMargin;
    }

    override public function setMargin(margin:Float):Void
	{
        this.collisionMargin = margin;
    }

    override public function getNumPreferredPenetrationDirections():Int
	{
        return 0;
    }

    override public function getPreferredPenetrationDirection(index:Int, penetrationVector:Vector3f):Void
	{
    }
}