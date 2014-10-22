package com.bulletphysics.extras.gimpact;
import com.bulletphysics.collision.dispatch.CollisionWorld.RayResultCallback;
import com.bulletphysics.collision.shapes.CollisionShape;
import com.bulletphysics.collision.shapes.StridingMeshInterface;
import com.bulletphysics.collision.shapes.TriangleCallback;
import com.bulletphysics.extras.gimpact.BoxCollision.AABB;
import com.bulletphysics.extras.gimpact.PrimitiveManagerBase;
import com.bulletphysics.extras.gimpact.ShapeType;
import com.bulletphysics.extras.gimpact.TetrahedronShapeEx;
import com.bulletphysics.extras.gimpact.TriangleShapeEx;
import com.bulletphysics.linearmath.Transform;
import de.polygonal.ds.error.Assert;
import com.bulletphysics.util.ObjectArrayList;
import vecmath.Vector3f;

/**
 * ...
 * @author weilichuang
 */
class GImpactMeshShape extends GImpactShapeInterface 
{

    private var mesh_parts:ObjectArrayList<GImpactMeshShapePart> = new ObjectArrayList<GImpactMeshShapePart>();

    public function new(meshInterface:StridingMeshInterface)
	{
		super();
        buildMeshParts(meshInterface);
    }

    public function getMeshPartCount():Int
	{
        return mesh_parts.size();
    }

    public function getMeshPart(index:Int):GImpactMeshShapePart
	{
        return mesh_parts.getQuick(index);
    }
	
	override public function setLocalScaling(scaling:Vector3f):Void 
	{
		localScaling.fromVector3f(scaling);

        var i:Int = mesh_parts.size();
        while ((i--) != 0)
		{
            var part:GImpactMeshShapePart = mesh_parts.getQuick(i);
            part.setLocalScaling(scaling);
        }

        needs_update = true;
	}

	override public function setMargin(margin:Float):Void 
	{
		collisionMargin = margin;

        var i:Int = mesh_parts.size();
        while ((i--) != 0)
		{
            var part:GImpactMeshShapePart = mesh_parts.getQuick(i);
            part.setMargin(margin);
        }

        needs_update = true;
	}

    override public function postUpdate():Void 
	{
		var i:Int = mesh_parts.size();
        while ((i--) != 0) 
		{
            var part:GImpactMeshShapePart = mesh_parts.getQuick(i);
            part.postUpdate();
        }

        needs_update = true;
	}

    override public function calculateLocalInertia(mass:Float, inertia:Vector3f):Void 
	{
		//#ifdef CALC_EXACT_INERTIA
        inertia.setTo(0, 0, 0);

        var i:Int = getMeshPartCount();
        var partmass:Float = mass / i;

        var partinertia:Vector3f = new Vector3f();

        while ((i--) != 0) 
		{
            getMeshPart(i).calculateLocalInertia(partmass, partinertia);
            inertia.add(partinertia);
        }

        ////#else
        //
        //// Calc box inertia
        //
        //btScalar lx= m_localAABB.m_max[0] - m_localAABB.m_min[0];
        //btScalar ly= m_localAABB.m_max[1] - m_localAABB.m_min[1];
        //btScalar lz= m_localAABB.m_max[2] - m_localAABB.m_min[2];
        //const btScalar x2 = lx*lx;
        //const btScalar y2 = ly*ly;
        //const btScalar z2 = lz*lz;
        //const btScalar scaledmass = mass * btScalar(0.08333333);
        //
        //inertia = scaledmass * (btVector3(y2+z2,x2+z2,x2+y2));
        ////#endif
	}
	
	override public function getPrimitiveManager():PrimitiveManagerBase 
	{
		Assert.assert (false);
        return null;
	}
		
	override public function getNumChildShapes():Int 
	{
		Assert.assert (false);
        return 0;
	}

    override public function childrenHasTransform():Bool 
	{
		Assert.assert (false);
        return false;
	}

	override public function needsRetrieveTriangles():Bool 
	{
		Assert.assert (false);
        return false;
	}

    override public function needsRetrieveTetrahedrons():Bool 
	{
		Assert.assert (false);
        return false;
	}

    override public function getBulletTriangle(prim_index:Int, triangle:TriangleShapeEx):Void 
	{
		Assert.assert (false);
	}

    override public function getBulletTetrahedron(prim_index:Int, tetrahedron:TetrahedronShapeEx):Void 
	{
		Assert.assert (false);
	}

    override public function lockChildShapes():Void 
	{
		Assert.assert (false);
	}

    override public function unlockChildShapes():Void 
	{
		Assert.assert (false);
	}

    override public function getChildAabb(child_index:Int, t:Transform, aabbMin:Vector3f, aabbMax:Vector3f):Void 
	{
		Assert.assert (false);
	}

    override public function getChildShape(index:Int):CollisionShape 
	{
		Assert.assert (false);
		return null;
	}

    override public function getChildTransform(index:Int):Transform 
	{
		Assert.assert (false);
		return null;
	}

    override public function setChildTransform(index:Int, transform:Transform):Void 
	{
		Assert.assert (false);
	}

    override public function getGImpactShapeType():ShapeType 
	{
		return ShapeType.TRIMESH_SHAPE;
	}

    override public function getName():String 
	{
		return "GImpactMesh";
	}

    override public function rayTest(rayFrom:Vector3f, rayTo:Vector3f, resultCallback:RayResultCallback):Void 
	{
		
	}
    
	override public function processAllTriangles(callback:TriangleCallback, aabbMin:Vector3f, aabbMax:Vector3f):Void 
	{
		var i:Int = mesh_parts.size();
        while ((i--) != 0) 
		{
            mesh_parts.getQuick(i).processAllTriangles(callback, aabbMin, aabbMax);
        }
	}

    private function buildMeshParts(meshInterface:StridingMeshInterface):Void
	{
        for (i in 0...meshInterface.getNumSubParts())
		{
            var newpart:GImpactMeshShapePart = new GImpactMeshShapePart();
			newpart.init(meshInterface, i);
            mesh_parts.add(newpart);
        }
    }
	
	override function calcLocalAABB():Void 
	{
		var tmpAABB:AABB = new AABB();

        localAABB.invalidate();
        var i:Int = mesh_parts.size();
        while ((i--) != 0) {
            mesh_parts.getQuick(i).updateBound();
            localAABB.merge(mesh_parts.getQuick(i).getLocalBox(tmpAABB));
        }
	}
}
