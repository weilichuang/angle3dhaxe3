package com.bulletphysics.linearmath.convexhull;
import com.bulletphysics.util.IntArrayList;
import com.bulletphysics.util.ObjectArrayList;
import vecmath.Vector3f;

/**
 * ...
 * @author weilichuang
 */
class PHullResult
{
	public var vcount:Int = 0;
    public var indexCount:Int = 0;
    public var faceCount:Int = 0;
    public var vertices:ObjectArrayList<Vector3f> = null;
    public var indices:IntArrayList = new IntArrayList();

	public function new() 
	{
		
	}
	
}