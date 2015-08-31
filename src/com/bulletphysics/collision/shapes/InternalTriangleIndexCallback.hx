package com.bulletphysics.collision.shapes;
import org.angle3d.math.Vector3f;

/**
 * Callback for internal processing of triangles.
 * @author weilichuang
 */
interface InternalTriangleIndexCallback
{

	function internalProcessTriangleIndex(triangle:Array<Vector3f>, partId:Int, triangleIndex:Int):Void;
}