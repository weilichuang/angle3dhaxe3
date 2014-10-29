package com.bulletphysics.collision.shapes;

/**
 * ...
 * @author weilichuang
 */
interface NodeOverlapCallback
{
	function processNode(subPart:Int, triangleIndex:Int):Void;
}