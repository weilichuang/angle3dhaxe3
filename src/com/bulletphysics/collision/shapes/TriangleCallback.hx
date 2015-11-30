package com.bulletphysics.collision.shapes;
import org.angle3d.math.Vector3f;

/**
 * TriangleCallback provides a callback for each overlapping triangle when calling
 * processAllTriangles.<p>
 * <p/>
 * This callback is called by processAllTriangles for all {ConcaveShape} derived
 * classes, such as {BvhTriangleMeshShape}, {StaticPlaneShape} and
 * {HeightfieldTerrainShape}.
 *
 * @author weilichuang
 */
interface TriangleCallback
{
	function processTriangle(triangle:Array<Vector3f>, partId:Int, triangleIndex:Int):Void;
}