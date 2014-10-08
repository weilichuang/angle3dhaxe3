package com.bulletphysics.collision.shapes;
import com.bulletphysics.linearmath.VectorUtil;
import com.vecmath.Vector3f;

/**
 * ...
 * @author weilichuang
 */
class VertexData
{

	public function new() 
	{
		
	}
	
	public function getVertexCount():Int
	{
		return 0;
	}
	
	public function getIndexCount():Int
	{
		return 0;
	}
	
	public function getVertex(idx:Int, out: { x:Float, y:Float, z:Float } ): { x:Float, y:Float, z:Float }
	{
		return null;
	}
	
	public function setVertex(idx:Int, x:Float, y:Float, z:Float):Void
	{
		
	}
	
	public function getIndex(idx:Int):Int
	{
		return 0;
	}
	
	public function getTriangle(firstIndex:Int, scale:Vector3f, triangle:Array<Vector3f>):Void
	{
		for (i in 0...3)
		{
            getVertex(getIndex(firstIndex + i), triangle[i]);
            VectorUtil.mul(triangle[i], triangle[i], scale);
        }
	}
	
}