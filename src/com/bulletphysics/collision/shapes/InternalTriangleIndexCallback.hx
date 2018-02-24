package com.bulletphysics.collision.shapes;
import angle3d.math.Vector3f;

/**
 * Callback for internal processing of triangles.
 
 */
interface InternalTriangleIndexCallback
{

	function internalProcessTriangleIndex(triangle:Array<Vector3f>, partId:Int, triangleIndex:Int):Void;
}