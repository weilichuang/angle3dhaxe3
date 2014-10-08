package com.bulletphysics.linearmath.convexhull;
import com.bulletphysics.util.IntArrayList;
import com.bulletphysics.util.ObjectArrayList;
import com.vecmath.Vector3f;

/**
 * Contains resulting polygonal representation.<p>
 * <p/>
 * Depending on the {@link #polygons} flag, array of indices consists of:<br>
 * <b>for triangles:</b> indices are array indexes into the vertex list<br>
 * <b>for polygons:</b> indices are in the form (number of points in face) (p1, p2, p3, ...)
 * 
 * @author weilichuang
 */
class HullResult
{

	/**
     * True if indices represents polygons, false indices are triangles.
     */
    public var polygons:Bool = true;

    /**
     * Number of vertices in the output hull.
     */
    public var numOutputVertices:Int = 0;

    /**
     * Array of vertices.
     */
    public var outputVertices:ObjectArrayList<Vector3f> = new ObjectArrayList<Vector3f>();

    /**
     * Number of faces produced.
     */
    public var numFaces:Int = 0;

    /**
     * Total number of indices.
     */
    public var numIndices:Int = 0;

    /**
     * Array of indices.
     */
    public var indices:IntArrayList = new IntArrayList();
	
}