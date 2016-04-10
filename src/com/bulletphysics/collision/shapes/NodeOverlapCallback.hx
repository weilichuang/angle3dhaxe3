package com.bulletphysics.collision.shapes;

/**
 * ...
 
 */
interface NodeOverlapCallback
{
	function processNode(subPart:Int, triangleIndex:Int):Void;
}