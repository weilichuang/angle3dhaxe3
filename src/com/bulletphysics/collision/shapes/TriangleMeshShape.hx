package com.bulletphysics.collision.shapes;
import com.bulletphysics.collision.shapes.TriangleCallback;
import com.bulletphysics.linearmath.AabbUtil2;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.linearmath.LinearMathUtil;
import de.polygonal.ds.error.Assert;
import org.angle3d.math.Matrix3f;
import com.bulletphysics.linearmath.MatrixUtil;
import org.angle3d.math.Vector3f;

/**
 * Concave triangle mesh abstract class. Use {BvhTriangleMeshShape} as concrete
 * implementation.
 * @author weilichuang
 */
class TriangleMeshShape extends ConcaveShape
{

	private var localAabbMin:Vector3f = new Vector3f();
    private var localAabbMax:Vector3f = new Vector3f();
    private var meshInterface:StridingMeshInterface;

    /**
     * TriangleMeshShape constructor has been disabled/protected, so that users will not mistakenly use this class.
     * Don't use btTriangleMeshShape but use btBvhTriangleMeshShape instead!
     */
    public function new(meshInterface:StridingMeshInterface)
	{
		super();
		
        this.meshInterface = meshInterface;

        // JAVA NOTE: moved to BvhTriangleMeshShape
        //recalcLocalAabb();
    }

    public function localGetSupportingVertex(vec:Vector3f, out:Vector3f):Vector3f
	{
        var tmp:Vector3f = new Vector3f();

        var supportVertex:Vector3f = out;

        var ident:Transform = new Transform();
        ident.setIdentity();

        var supportCallback:SupportVertexCallback = new SupportVertexCallback(vec, ident);

        var aabbMax:Vector3f = new Vector3f();
        aabbMax.setTo(1e30, 1e30, 1e30);
        tmp.negateBy(aabbMax);

        processAllTriangles(supportCallback, tmp, aabbMax);

        supportCallback.getSupportVertexLocal(supportVertex);

        return out;
    }

    public function localGetSupportingVertexWithoutMargin(vec:Vector3f, out:Vector3f):Vector3f
	{
		Assert.assert(false);
        return localGetSupportingVertex(vec, out);
    }

    public function recalcLocalAabb():Void
	{
		var vec:Vector3f = new Vector3f();
        for (i in 0...3)
		{
            vec.setTo(0, 0, 0);
            LinearMathUtil.setCoord(vec, i, 1);
            var tmp:Vector3f = localGetSupportingVertex(vec, new Vector3f());
            LinearMathUtil.setCoord(localAabbMax, i, LinearMathUtil.getCoord(tmp, i) + collisionMargin);
            LinearMathUtil.setCoord(vec, i, -1);
            localGetSupportingVertex(vec, tmp);
            LinearMathUtil.setCoord(localAabbMin, i, LinearMathUtil.getCoord(tmp, i) - collisionMargin);
        }
    }
	
	override public function getAabb(t:Transform, aabbMin:Vector3f, aabbMax:Vector3f):Void 
	{
		var tmp:Vector3f = new Vector3f();

        var localHalfExtents:Vector3f = new Vector3f();
        localHalfExtents.subtractBy(localAabbMax, localAabbMin);
        localHalfExtents.scaleLocal(0.5);

        var localCenter:Vector3f = new Vector3f();
        localCenter.addBy(localAabbMax, localAabbMin);
        localCenter.scaleLocal(0.5);

        var abs_b:Matrix3f = t.basis.clone();
        MatrixUtil.absolute(abs_b);

        var center:Vector3f = localCenter.clone();
        t.transform(center);

        var extent:Vector3f = new Vector3f();
        abs_b.copyRowTo(0, tmp);
        extent.x = tmp.dot(localHalfExtents);
        abs_b.copyRowTo(1, tmp);
        extent.y = tmp.dot(localHalfExtents);
        abs_b.copyRowTo(2, tmp);
        extent.z = tmp.dot(localHalfExtents);

        var margin:Vector3f = new Vector3f();
        margin.setTo(getMargin(), getMargin(), getMargin());
        extent.addLocal(margin);

        aabbMin.subtractBy(center, extent);
        aabbMax.addBy(center, extent);
	}
	
	override public function processAllTriangles(callback:TriangleCallback, aabbMin:Vector3f, aabbMax:Vector3f):Void 
	{
		var filterCallback:FilteredCallback = new FilteredCallback(callback, aabbMin, aabbMax);

        meshInterface.internalProcessAllTriangles(filterCallback, aabbMin, aabbMax);
	}

    override public function calculateLocalInertia(mass:Float, inertia:Vector3f):Void 
	{
		// moving concave objects not supported
        Assert.assert(false);
        inertia.setTo(0, 0, 0);
	}
	
	override public function setLocalScaling(scaling:Vector3f):Void 
	{
		meshInterface.setScaling(scaling);
        recalcLocalAabb();
	}

    override public function getLocalScaling(out:Vector3f):Vector3f 
	{
		return meshInterface.getScaling(out);
	}
   
    public function getMeshInterface():StridingMeshInterface
	{
        return meshInterface;
    }

    public function getLocalAabbMin(out:Vector3f):Vector3f
	{
        out.copyFrom(localAabbMin);
        return out;
    }

    public function getLocalAabbMax(out:Vector3f):Vector3f
	{
        out.copyFrom(localAabbMax);
        return out;
    }
	
	override public function getName():String 
	{
		return "TRIANGLEMESH";
	}
}

class SupportVertexCallback implements TriangleCallback 
{
	private var supportVertexLocal:Vector3f = new Vector3f(0, 0, 0);
	public var worldTrans:Transform = new Transform();
	public var maxDot:Float = -1e30;
	public var supportVecLocal:Vector3f = new Vector3f();

	public function new(supportVecWorld:Vector3f, trans:Transform)
	{
		this.worldTrans.fromTransform(trans);
		MatrixUtil.transposeTransform(supportVecLocal, supportVecWorld, worldTrans.basis);
	}
	
	public function processTriangle(triangle:Array<Vector3f>, partId:Int, triangleIndex:Int):Void 
	{
		for (i in 0...3) 
		{
			var dot:Float = supportVecLocal.dot(triangle[i]);
			if (dot > maxDot)
			{
				maxDot = dot;
				supportVertexLocal.copyFrom(triangle[i]);
			}
		}
	}

	public function getSupportVertexWorldSpace(out:Vector3f):Vector3f
	{
		out.copyFrom(supportVertexLocal);
		worldTrans.transform(out);
		return out;
	}

	public function getSupportVertexLocal(out:Vector3f):Vector3f
	{
		out.copyFrom(supportVertexLocal);
		return out;
	}
}

class FilteredCallback implements InternalTriangleIndexCallback 
{
	public var callback:TriangleCallback;
	public var aabbMin:Vector3f = new Vector3f();
	public var aabbMax:Vector3f = new Vector3f();

	public function new(callback:TriangleCallback, aabbMin:Vector3f, aabbMax:Vector3f)
	{
		this.callback = callback;
		this.aabbMin.copyFrom(aabbMin);
		this.aabbMax.copyFrom(aabbMax);
	}

	public function internalProcessTriangleIndex(triangle:Array<Vector3f>, partId:Int, triangleIndex:Int):Void
	{
		if (AabbUtil2.testTriangleAgainstAabb2(triangle, aabbMin, aabbMax))
		{
			// check aabb in triangle-space, before doing this
			callback.processTriangle(triangle, partId, triangleIndex);
		}
	}
}