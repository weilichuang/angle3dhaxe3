package com.bulletphysics.collision.gimpact ;

import com.bulletphysics.collision.broadphase.BroadphaseNativeType;
import com.bulletphysics.collision.dispatch.CollisionWorld.RayResultCallback;
import com.bulletphysics.collision.shapes.CollisionShape;
import com.bulletphysics.collision.shapes.ConcaveShape;
import com.bulletphysics.collision.shapes.TriangleCallback;
import com.bulletphysics.collision.gimpact.BoxCollision.AABB;
import com.bulletphysics.linearmath.Transform;

import org.angle3d.math.Vector3f;

/**
 * Base class for gimpact shapes.
 *
 * @author weilichuang
 */
class GImpactShapeInterface extends ConcaveShape 
{

    private var localAABB:AABB = new AABB();
    private var needs_update:Bool;
    private var localScaling:Vector3f = new Vector3f();
    public var box_set:GImpactBvh = new GImpactBvh(); // optionally boxset

    public function new()
	{
		super();
		_shapeType = BroadphaseNativeType.GIMPACT_SHAPE_PROXYTYPE;
		
        localAABB.invalidate();
        needs_update = true;
        localScaling.setTo(1, 1, 1);
    }

    /**
     * Performs refit operation.<p>
     * Updates the entire Box set of this shape.<p>
     * <p/>
     * postUpdate() must be called for attemps to calculating the box set, else this function
     * will does nothing.<p>
     * <p/>
     * if m_needs_update == true, then it calls calcLocalAABB();
     */
    public function updateBound():Void
	{
        if (!needs_update)
		{
            return;
        }
        calcLocalAABB();
        needs_update = false;
    }
	
	override public function getAabb(t:Transform, aabbMin:Vector3f, aabbMax:Vector3f):Void 
	{
		var transformedbox:AABB = localAABB.clone();
        transformedbox.appy_transform(t);
        aabbMin.copyFrom(transformedbox.min);
        aabbMax.copyFrom(transformedbox.max);
	}

    /**
     * Tells to this object that is needed to refit the box set.
     */
    public function postUpdate():Void
	{
        needs_update = true;
    }

    /**
     * Obtains the local box, which is the global calculated box of the total of subshapes.
     */
    public function getLocalBox(out:AABB):AABB
	{
        out.fromAABB(localAABB);
        return out;
    }

	/**
     * You must call updateBound() for update the box set.
     */
    override public function setLocalScaling(scaling:Vector3f):Void 
	{
		localScaling.copyFrom(scaling);
        postUpdate();
	}

    override public function getLocalScaling(out:Vector3f):Vector3f 
	{
		out.copyFrom(localScaling);
		return out;
	}


    override public function setMargin(margin:Float):Void 
	{
		collisionMargin = margin;
        var i:Int = getNumChildShapes();
        while ((i--) != 0)
		{
            var child:CollisionShape = getChildShape(i);
            child.setMargin(margin);
        }

        needs_update = true;
	}

    /**
     * Base method for determinig which kind of GIMPACT shape we get.
     */
    public function getGImpactShapeType():ShapeType
	{
		return null;
	}

    public function getBoxSet():GImpactBvh
	{
        return box_set;
    }

    /**
     * Determines if this class has a hierarchy structure for sorting its primitives.
     */
    public function hasBoxSet():Bool
	{
        if (box_set.getNodeCount() == 0)
		{
            return false;
        }
        return true;
    }

    /**
     * Obtains the primitive manager.
     */
    public function getPrimitiveManager():PrimitiveManagerBase
	{
		return null;
	}

    /**
     * Gets the number of children.
     */
    public function getNumChildShapes():Int
	{
		return 0;
	}

    /**
     * If true, then its children must get transforms.
     */
    public function childrenHasTransform():Bool
	{
		return false;
	}

    /**
     * Determines if this shape has triangles.
     */
    public function needsRetrieveTriangles():Bool
	{
		return false;
	}

    /**
     * Determines if this shape has tetrahedrons.
     */
    public function needsRetrieveTetrahedrons():Bool
	{
		return false;
	}

    public function getBulletTriangle(prim_index:Int, triangle:TriangleShapeEx):Void
	{
		
	}

    public function getBulletTetrahedron(prim_index:Int, tetrahedron:TetrahedronShapeEx):Void
	{
		
	}

    /**
     * Call when reading child shapes.
     */
    public function lockChildShapes():Void 
	{
    }

    public function unlockChildShapes():Void
	{
    }

    /**
     * If this trimesh.
     */
    public function getPrimitiveTriangle(index:Int, triangle:PrimitiveTriangle):Void
	{
        getPrimitiveManager().get_primitive_triangle(index, triangle);
    }

    /**
     * Use this function for perfofm refit in bounding boxes.
     */
    private function calcLocalAABB():Void
	{
        lockChildShapes();
        if (box_set.getNodeCount() == 0)
		{
            box_set.buildSet();
        } 
		else
		{
            box_set.update();
        }
        unlockChildShapes();

        box_set.getGlobalBox(localAABB);
    }

    /**
     * Retrieves the bound from a child.
     */
    public function getChildAabb(child_index:Int, t:Transform, aabbMin:Vector3f, aabbMax:Vector3f):Void
	{
        var child_aabb:AABB = new AABB();
        getPrimitiveManager().get_primitive_box(child_index, child_aabb);
        child_aabb.appy_transform(t);
        aabbMin.copyFrom(child_aabb.min);
        aabbMax.copyFrom(child_aabb.max);
    }

    /**
     * Gets the children.
     */
    public function getChildShape(index:Int):CollisionShape
	{
		return null;
	}

    /**
     * Gets the children transform.
     */
    public function getChildTransform(index:Int):Transform
	{
		return null;
	}

    /**
     * Sets the children transform.<p>
     * You must call updateBound() for update the box set.
     */
    public function setChildTransform(index:Int, transform:Transform):Void
	{
		
	}

    /**
     * Virtual method for ray collision.
     */
    public function rayTest(rayFrom:Vector3f, rayTo:Vector3f, resultCallback:RayResultCallback):Void
	{
    }

    /**
     * Function for retrieve triangles. It gives the triangles in local space.
     */
	override public function processAllTriangles(callback:TriangleCallback, aabbMin:Vector3f, aabbMax:Vector3f):Void 
	{
	}
}
