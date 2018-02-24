package com.bulletphysics.linearmath.convexhull;
import com.bulletphysics.util.ObjectArrayList;
import angle3d.math.Vector3f;

/**
 * Describes point cloud data and other input for conversion to polygonal representation.
 * 
 
 */
class HullDesc
{

	/**
     * Flags to use when generating the convex hull, see {HullFlags}.
     */
    public var flags:Int = HullFlags.DEFAULT;

    /**
     * Number of vertices in the input point cloud.
     */
    public var vcount:Int = 0;

    /**
     * Array of vertices.
     */
    public var vertices:ObjectArrayList<Vector3f>;

    /**
     * Stride of each vertex, in bytes.
     */
    public var vertexStride:Int = 3 * 4;

    /**
     * Epsilon value for removing duplicates. This is a normalized value, if normalized bit is on.
     */
    public var normalEpsilon:Float = 0.001;

    /**
     * Maximum number of vertices to be considered for the hull.
     */
    public var maxVertices:Int = 4096;

    /**
     * Maximum number of faces to be considered for the hull.
     */
    public var maxFaces:Int = 4096;
	
	public function new()
	{
		
	}

    public function init(flag:Int, vcount:Int, vertices:ObjectArrayList<Vector3f>, stride:Int = 12)
	{
        this.flags = flag;
        this.vcount = vcount;
        this.vertices = vertices;
        this.vertexStride = stride;
        this.normalEpsilon = 0.001;
        this.maxVertices = 4096;
    }

    public function hasHullFlag(flag:Int):Bool
	{
        if ((this.flags & flag) != 0)
		{
            return true;
        }
        return false;
    }

    public function setHullFlag(flag:Int):Void
	{
        flags |= flag;
    }

    public function clearHullFlag(flag:Int):Void
	{
        flags &= ~flag;
    }
	
}