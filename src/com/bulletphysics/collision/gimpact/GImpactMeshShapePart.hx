package com.bulletphysics.collision.gimpact ;

import com.bulletphysics.collision.shapes.CollisionShape;
import com.bulletphysics.collision.shapes.StridingMeshInterface;
import com.bulletphysics.collision.shapes.TriangleCallback;
import com.bulletphysics.collision.gimpact.BoxCollision.AABB;
import com.bulletphysics.collision.gimpact.PrimitiveManagerBase;
import com.bulletphysics.collision.gimpact.ShapeType;
import com.bulletphysics.collision.gimpact.TetrahedronShapeEx;
import com.bulletphysics.collision.gimpact.TriangleShapeEx;
import com.bulletphysics.linearmath.Transform;
import angle3d.error.Assert;
import com.bulletphysics.util.IntArrayList;

import angle3d.math.Vector3f;

/**
 * This class manages a sub part of a mesh supplied by the StridingMeshInterface interface.<p>
 * <p/>
 * - Simply create this shape by passing the StridingMeshInterface to the constructor
 * GImpactMeshShapePart, then you must call updateBound() after creating the mesh<br>
 * - When making operations with this shape, you must call <b>lock</b> before accessing
 * to the trimesh primitives, and then call <b>unlock</b><br>
 * - You can handle deformable meshes with this shape, by calling postUpdate() every time
 * when changing the mesh vertices.
 *
 
 */
class GImpactMeshShapePart extends GImpactShapeInterface 
{

    public var primitive_manager:TrimeshPrimitiveManager = new TrimeshPrimitiveManager();

    private var collided:IntArrayList = new IntArrayList();

    public function new()
	{
		super();
        box_set.setPrimitiveManager(primitive_manager);
    }

    public function init(meshInterface:StridingMeshInterface, part:Int):Void
	{
        primitive_manager.meshInterface = meshInterface;
        primitive_manager.part = part;
        box_set.setPrimitiveManager(primitive_manager);
    }
	
	override public function childrenHasTransform():Bool 
	{
		return false;
	}
	
	override public function lockChildShapes():Void 
	{
		var dummymanager:TrimeshPrimitiveManager = cast box_set.getPrimitiveManager();
        dummymanager.lock();
	}
	
	override public function unlockChildShapes():Void 
	{
		var dummymanager:TrimeshPrimitiveManager = cast box_set.getPrimitiveManager();
        dummymanager.unlock();
	}
	
	override public function getNumChildShapes():Int 
	{
		return primitive_manager.get_primitive_count();
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

    override public function getPrimitiveManager():PrimitiveManagerBase 
	{
		return primitive_manager;
	}

    public function getTrimeshPrimitiveManager():TrimeshPrimitiveManager
	{
        return primitive_manager;
    }
	
	override public function calculateLocalInertia(mass:Float, inertia:Vector3f):Void 
	{
		lockChildShapes();

        //#define CALC_EXACT_INERTIA 1
        //#ifdef CALC_EXACT_INERTIA
        inertia.setTo(0, 0, 0);

        var i:Int = getVertexCount();
        var pointmass:Float = mass / i;

        var pointintertia:Vector3f = new Vector3f();

        while ((i--) != 0)
		{
            getVertex(i, pointintertia);
            GImpactMassUtil.get_point_inertia(pointintertia, pointmass, pointintertia);
            inertia.addLocal(pointintertia);
        }

        //#else
        //
        //// Calc box inertia
        //
        //float lx= localAABB.max.x - localAABB.min.x;
        //float ly= localAABB.max.y - localAABB.min.y;
        //float lz= localAABB.max.z - localAABB.min.z;
        //float x2 = lx*lx;
        //float y2 = ly*ly;
        //float z2 = lz*lz;
        //float scaledmass = mass * 0.08333333f;
        //
        //inertia.set(y2+z2,x2+z2,x2+y2);
        //inertia.scale(scaledmass);
        //
        //#endif
        unlockChildShapes();
	}

	override public function getName():String 
	{
		return "GImpactMeshShapePart";
	}
	
	override public function getGImpactShapeType():ShapeType 
	{
		return ShapeType.TRIMESH_SHAPE_PART;
	}

	override public function needsRetrieveTriangles():Bool 
	{
		return true;
	}

	override public function needsRetrieveTetrahedrons():Bool 
	{
		return false;
	}

	override public function getBulletTriangle(prim_index:Int, triangle:TriangleShapeEx):Void 
	{
		primitive_manager.get_bullet_triangle(prim_index, triangle);
	}

    override public function getBulletTetrahedron(prim_index:Int, tetrahedron:TetrahedronShapeEx):Void 
	{
		Assert.assert (false);
	}


    public function getVertexCount():Int
	{
        return primitive_manager.get_vertex_count();
    }

    public function getVertex(vertex_index:Int, vertex:Vector3f):Void
	{
        primitive_manager.get_vertex(vertex_index, vertex);
    }
	
	override public function setMargin(margin:Float):Void 
	{
		primitive_manager.margin = margin;
        postUpdate();
	}

	override public function getMargin():Float 
	{
		return primitive_manager.margin;
	}

    override public function setLocalScaling(scaling:Vector3f):Void 
	{
		primitive_manager.scale.copyFrom(scaling);
        postUpdate();
	}

    override public function getLocalScaling(out:Vector3f):Vector3f 
	{
		out.copyFrom(primitive_manager.scale);
        return out;
	}
	
    public function getPart():Int
	{
        return primitive_manager.part;
    }
	
	override public function processAllTriangles(callback:TriangleCallback, aabbMin:Vector3f, aabbMax:Vector3f):Void 
	{
		lockChildShapes();
        var box:AABB = new AABB();
        box.min.copyFrom(aabbMin);
        box.max.copyFrom(aabbMax);

        collided.clear();
        box_set.boxQuery(box, collided);

        if (collided.size() == 0) {
            unlockChildShapes();
            return;
        }

        var part:Int = getPart();
        var triangle:PrimitiveTriangle = new PrimitiveTriangle();
        var i:Int = collided.size();
        while ((i--) != 0)
		{
            getPrimitiveTriangle(collided.get(i), triangle);
            callback.processTriangle(triangle.vertices, part, collided.get(i));
        }
        unlockChildShapes();
	}

}
