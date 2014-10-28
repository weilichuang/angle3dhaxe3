package com.bulletphysics.collision.gimpact ;
import com.bulletphysics.collision.shapes.CollisionShape;

/**
 * ...
 * @author weilichuang
 */
class GIM_ShapeRetriever
{

	public var gim_shape:GImpactShapeInterface;
    public var trishape:TriangleShapeEx = new TriangleShapeEx(null,null,null);
    public var tetrashape:TetrahedronShapeEx = new TetrahedronShapeEx();

    public var child_retriever:ChildShapeRetriever = new ChildShapeRetriever();
    public var tri_retriever:TriangleShapeRetriever = new TriangleShapeRetriever();
    public var tetra_retriever:TetraShapeRetriever = new TetraShapeRetriever();
    public var current_retriever:ChildShapeRetriever;

    public function new(gim_shape:GImpactShapeInterface)
	{
        this.gim_shape = gim_shape;

        // select retriever
        if (gim_shape.needsRetrieveTriangles()) 
		{
            current_retriever = tri_retriever;
        } 
		else if (gim_shape.needsRetrieveTetrahedrons())
		{
            current_retriever = tetra_retriever;
        } 
		else 
		{
            current_retriever = child_retriever;
        }

        current_retriever.parent = this;
    }

    public function getChildShape(index:Int):CollisionShape 
	{
        return current_retriever.getChildShape(index);
    }
}

class ChildShapeRetriever 
{
	public var parent:GIM_ShapeRetriever;
	
	public function new()
	{
		
	}

	public function getChildShape(index:Int):CollisionShape
	{
		return parent.gim_shape.getChildShape(index);
	}
}

class TriangleShapeRetriever extends ChildShapeRetriever
{
	public function new()
	{
		super();
	}
	
	override public function getChildShape(index:Int):CollisionShape 
	{
		parent.gim_shape.getBulletTriangle(index, parent.trishape);
		return parent.trishape;
	}
}

class TetraShapeRetriever extends ChildShapeRetriever 
{
	public function new()
	{
		super();
	}
	
	override public function getChildShape(index:Int):CollisionShape 
	{
		parent.gim_shape.getBulletTetrahedron(index, parent.tetrashape);
		return parent.tetrashape;
	}
}