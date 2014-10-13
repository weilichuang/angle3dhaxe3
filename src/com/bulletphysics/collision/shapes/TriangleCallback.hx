package com.bulletphysics.collision.shapes;
import vecmath.Vector3f;

/**
 * TriangleCallback provides a callback for each overlapping triangle when calling
 * processAllTriangles.<p>
 * <p/>
 * This callback is called by processAllTriangles for all {@link ConcaveShape} derived
 * classes, such as {@link BvhTriangleMeshShape}, {@link StaticPlaneShape} and
 * {@link HeightfieldTerrainShape}.
 *
 * @author weilichuang
 */
class TriangleCallback
{

	public function new() 
	{
		
	}
	
	public function processTriangle(triangle:Array<Vector3f>, partId:Int, triangleIndex:Int):Void
	{
		
	}
	
}