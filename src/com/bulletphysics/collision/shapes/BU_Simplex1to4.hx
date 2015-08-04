package com.bulletphysics.collision.shapes;
import com.bulletphysics.collision.broadphase.BroadphaseNativeType;
import com.vecmath.Vector3f;

/**
 * BU_Simplex1to4 implements feature based and implicit simplex of up to 4 vertices
 * (tetrahedron, triangle, line, vertex).
 * @author weilichuang
 */
class BU_Simplex1to4 extends PolyhedralConvexShape
{

	private var numVertices:Int = 0;
    private var vertices:Array<Vector3f> = [];

    public function new() 
	{
		super();
    }

    public function reset():Void
	{
        numVertices = 0;
    }
	
	override public function getShapeType():BroadphaseNativeType 
	{
		return BroadphaseNativeType.TETRAHEDRAL_SHAPE_PROXYTYPE;
	}

    public function addVertex(pt:Vector3f):Void
	{
		if (numVertices == 4)
			return;
			
        if (vertices[numVertices] == null)
		{
            vertices[numVertices] = new Vector3f();
        }

        vertices[numVertices++] = pt;

        recalcLocalAabb();
    }
	
	override public function getNumVertices():Int 
	{
		return numVertices;
	}
	
	override public function getNumEdges():Int 
	{
		// euler formula, F-E+V = 2, so E = F+V-2

        switch (numVertices)
		{
            case 0:
                return 0;
            case 1:
                return 0;
            case 2:
                return 1;
            case 3:
                return 3;
            case 4:
                return 6;
        }

        return 0;
	}
	
	override public function getEdge(i:Int, pa:Vector3f, pb:Vector3f):Void 
	{
		switch (numVertices)
		{
            case 2:
                pa.fromVector3f(vertices[0]);
                pb.fromVector3f(vertices[1]);
            case 3:
                switch (i)
				{
                    case 0:
                        pa.fromVector3f(vertices[0]);
                        pb.fromVector3f(vertices[1]);
                        
                    case 1:
                        pa.fromVector3f(vertices[1]);
                        pb.fromVector3f(vertices[2]);
                        
                    case 2:
                        pa.fromVector3f(vertices[2]);
                        pb.fromVector3f(vertices[0]);
                        
                }
                
            case 4:
                switch (i) 
				{
                    case 0:
                        pa.fromVector3f(vertices[0]);
                        pb.fromVector3f(vertices[1]);
                        
                    case 1:
                        pa.fromVector3f(vertices[1]);
                        pb.fromVector3f(vertices[2]);
                        
                    case 2:
                        pa.fromVector3f(vertices[2]);
                        pb.fromVector3f(vertices[0]);
                        
                    case 3:
                        pa.fromVector3f(vertices[0]);
                        pb.fromVector3f(vertices[3]);
                        
                    case 4:
                        pa.fromVector3f(vertices[1]);
                        pb.fromVector3f(vertices[3]);
                        
                    case 5:
                        pa.fromVector3f(vertices[2]);
                        pb.fromVector3f(vertices[3]);
                        
                }
        }
	}
	
	override public function getVertex(i:Int, vtx:Vector3f):Void 
	{
		vtx.fromVector3f(vertices[i]);
	}
	
	override public function getNumPlanes():Int 
	{
		switch (numVertices) 
		{
            case 0:
                return 0;
            case 1:
                return 0;
            case 2:
                return 0;
            case 3:
                return 2;
            case 4:
                return 4;
        }
        return 0;
	}

    override public function getPlane(planeNormal:Vector3f, planeSupport:Vector3f, i:Int):Void 
	{
		
	}

    public function getIndex(i:Int):Int
	{
        return 0;
    }
	
	override public function isInside(pt:Vector3f, tolerance:Float):Bool 
	{
		return false;
	}
	
	override public function getName():String 
	{
		return "BU_Simplex1to4";
	}
	
}