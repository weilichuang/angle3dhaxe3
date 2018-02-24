package com.bulletphysics.collision.shapes;
import com.bulletphysics.linearmath.convexhull.HullDesc;
import com.bulletphysics.linearmath.convexhull.HullFlags;
import com.bulletphysics.linearmath.convexhull.HullLibrary;
import com.bulletphysics.linearmath.convexhull.HullResult;
import com.bulletphysics.linearmath.MiscUtil;
import com.bulletphysics.util.IntArrayList;
import com.bulletphysics.util.ObjectArrayList;
import angle3d.math.Vector3f;

/**
 * ShapeHull takes a {ConvexShape}, builds the convex hull using {HullLibrary}
 * and provides triangle indices and vertices.
 *
 */
class ShapeHull 
{

    private var vertices:ObjectArrayList<Vector3f> = new ObjectArrayList<Vector3f>();
    private var indices:IntArrayList = new IntArrayList();
    private var numIndices:Int;
    private var shape:ConvexShape;

    private var unitSpherePoints:ObjectArrayList<Vector3f>  = new ObjectArrayList<Vector3f>();

    public function new(shape:ConvexShape)
	{
        this.shape = shape;
        this.vertices.clear();
        this.indices.clear();
        this.numIndices = 0;

        unitSpherePoints.resize(NUM_UNITSPHERE_POINTS + ConvexShape.MAX_PREFERRED_PENETRATION_DIRECTIONS * 2, Vector3f);
        for (i in 0...constUnitSpherePoints.size())
		{
            unitSpherePoints.getQuick(i).copyFrom(constUnitSpherePoints.getQuick(i));
        }
    }

    public function buildHull(margin:Float):Bool
	{
        var norm:Vector3f = new Vector3f();

        var numSampleDirections:Int = NUM_UNITSPHERE_POINTS;
        {
            var numPDA:Int = shape.getNumPreferredPenetrationDirections();
            if (numPDA != 0)
			{
                for (i in 0...numPDA)
				{
                    shape.getPreferredPenetrationDirection(i, norm);
                    unitSpherePoints.getQuick(numSampleDirections).copyFrom(norm);
                    numSampleDirections++;
                }
            }
        }

        var supportPoints:ObjectArrayList<Vector3f> = new ObjectArrayList<Vector3f>();
        supportPoints.resize(NUM_UNITSPHERE_POINTS + ConvexShape.MAX_PREFERRED_PENETRATION_DIRECTIONS * 2, Vector3f);

        for (i in 0...numSampleDirections)
		{
            shape.localGetSupportingVertex(unitSpherePoints.getQuick(i), supportPoints.getQuick(i));
        }

        var hd:HullDesc = new HullDesc();
        hd.flags = HullFlags.TRIANGLES;
        hd.vcount = numSampleDirections;

        //#ifdef BT_USE_DOUBLE_PRECISION
        //hd.mVertices = &supportPoints[0];
        //hd.mVertexStride = sizeof(btVector3);
        //#else
        hd.vertices = supportPoints;
        //hd.vertexStride = 3 * 4;
        //#endif

        var hl:HullLibrary = new HullLibrary();
        var hr:HullResult = new HullResult();
        if (!hl.createConvexHull(hd, hr))
		{
            return false;
        }

        vertices.resize(hr.numOutputVertices, Vector3f);

        for (i in 0...hr.numOutputVertices)
		{
            vertices.getQuick(i).copyFrom(hr.outputVertices.getQuick(i));
        }
        numIndices = hr.numIndices;
        MiscUtil.resizeIntArrayList(indices, numIndices, 0);
        for (i in 0...numIndices)
		{
            indices.set(i, hr.indices.get(i));
        }

        // free temporary hull result that we just copied
        hl.releaseResult(hr);

        return true;
    }

    public function numTriangles():Int
	{
        return Std.int(numIndices / 3);
    }

    public function numVertices():Int
	{
        return vertices.size();
    }

    public function getNumIndices():Int
	{
        return numIndices;
    }

    public function getVertexPointer():ObjectArrayList<Vector3f>
	{
        return vertices;
    }

    public function getIndexPointer():IntArrayList
	{
        return indices;
    }

    ////////////////////////////////////////////////////////////////////////////

    private static inline var NUM_UNITSPHERE_POINTS:Int = 42;

    private static var constUnitSpherePoints:ObjectArrayList<Vector3f>;

    static function __init__():Void
	{
		constUnitSpherePoints = new ObjectArrayList<Vector3f>();
        constUnitSpherePoints.add(new Vector3f(0.000000, -0.000000, -1.000000));
        constUnitSpherePoints.add(new Vector3f(0.723608, -0.525725, -0.447219));
        constUnitSpherePoints.add(new Vector3f(-0.276388, -0.850649, -0.447219));
        constUnitSpherePoints.add(new Vector3f(-0.894426, -0.000000, -0.447216));
        constUnitSpherePoints.add(new Vector3f(-0.276388, 0.850649, -0.447220));
        constUnitSpherePoints.add(new Vector3f(0.723608, 0.525725, -0.447219));
        constUnitSpherePoints.add(new Vector3f(0.276388, -0.850649, 0.447220));
        constUnitSpherePoints.add(new Vector3f(-0.723608, -0.525725, 0.447219));
        constUnitSpherePoints.add(new Vector3f(-0.723608, 0.525725, 0.447219));
        constUnitSpherePoints.add(new Vector3f(0.276388, 0.850649, 0.447219));
        constUnitSpherePoints.add(new Vector3f(0.894426, 0.000000, 0.447216));
        constUnitSpherePoints.add(new Vector3f(-0.000000, 0.000000, 1.000000));
        constUnitSpherePoints.add(new Vector3f(0.425323, -0.309011, -0.850654));
        constUnitSpherePoints.add(new Vector3f(-0.162456, -0.499995, -0.850654));
        constUnitSpherePoints.add(new Vector3f(0.262869, -0.809012, -0.525738));
        constUnitSpherePoints.add(new Vector3f(0.425323, 0.309011, -0.850654));
        constUnitSpherePoints.add(new Vector3f(0.850648, -0.000000, -0.525736));
        constUnitSpherePoints.add(new Vector3f(-0.525730, -0.000000, -0.850652));
        constUnitSpherePoints.add(new Vector3f(-0.688190, -0.499997, -0.525736));
        constUnitSpherePoints.add(new Vector3f(-0.162456, 0.499995, -0.850654));
        constUnitSpherePoints.add(new Vector3f(-0.688190, 0.499997, -0.525736));
        constUnitSpherePoints.add(new Vector3f(0.262869, 0.809012, -0.525738));
        constUnitSpherePoints.add(new Vector3f(0.951058, 0.309013, 0.000000));
        constUnitSpherePoints.add(new Vector3f(0.951058, -0.309013, 0.000000));
        constUnitSpherePoints.add(new Vector3f(0.587786, -0.809017, 0.000000));
        constUnitSpherePoints.add(new Vector3f(0.000000, -1.000000, 0.000000));
        constUnitSpherePoints.add(new Vector3f(-0.587786, -0.809017, 0.000000));
        constUnitSpherePoints.add(new Vector3f(-0.951058, -0.309013, -0.000000));
        constUnitSpherePoints.add(new Vector3f(-0.951058, 0.309013, -0.000000));
        constUnitSpherePoints.add(new Vector3f(-0.587786, 0.809017, -0.000000));
        constUnitSpherePoints.add(new Vector3f(-0.000000, 1.000000, -0.000000));
        constUnitSpherePoints.add(new Vector3f(0.587786, 0.809017, -0.000000));
        constUnitSpherePoints.add(new Vector3f(0.688190, -0.499997, 0.525736));
        constUnitSpherePoints.add(new Vector3f(-0.262869, -0.809012, 0.525738));
        constUnitSpherePoints.add(new Vector3f(-0.850648, 0.000000, 0.525736));
        constUnitSpherePoints.add(new Vector3f(-0.262869, 0.809012, 0.525738));
        constUnitSpherePoints.add(new Vector3f(0.688190, 0.499997, 0.525736));
        constUnitSpherePoints.add(new Vector3f(0.525730, 0.000000, 0.850652));
        constUnitSpherePoints.add(new Vector3f(0.162456, -0.499995, 0.850654));
        constUnitSpherePoints.add(new Vector3f(-0.425323, -0.309011, 0.850654));
        constUnitSpherePoints.add(new Vector3f(-0.425323, 0.309011, 0.850654));
        constUnitSpherePoints.add(new Vector3f(0.162456, 0.499995, 0.850654));
    }

}
