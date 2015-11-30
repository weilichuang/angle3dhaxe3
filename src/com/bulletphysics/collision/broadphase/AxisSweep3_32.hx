package com.bulletphysics.collision.broadphase;
import com.bulletphysics.collision.broadphase.AxisSweep3Internal.EdgeArray;
import com.bulletphysics.collision.broadphase.AxisSweep3Internal.Handle;
import de.polygonal.ds.error.Assert;
import org.angle3d.math.Vector3f;
import flash.Vector;

/**
 * AxisSweep3_32 allows higher precision quantization and more objects compared
 * to the {AxisSweep3} sweep and prune. This comes at the cost of more memory
 * per handle, and a bit slower performance.
 * @author weilichuang
 */
class AxisSweep3_32 extends AxisSweep3Internal
{

	public function new(worldAabbMin:Vector3f, worldAabbMax:Vector3f, maxHandles:Int = 1500000, pairCache:OverlappingPairCache = null)
	{
		super(worldAabbMin, worldAabbMax, 0xfffffffe, 0x7fffffff, maxHandles, pairCache);
		// 1 handle is reserved as sentinel
        Assert.assert (maxHandles > 1 && maxHandles < 2147483647);
	}
	
	override function createEdgeArray(size:Int):EdgeArray 
	{
		return new EdgeArrayImpl32(size);
	}
	
	override function createHandle():Handle 
	{
		return new HandleImpl32(null, 0, 0, null);
	}
	
	override private function getMask():Int
	{
		return 0xFFFFFFFF;
	}
}

class EdgeArrayImpl32 extends EdgeArray
{
	private var pos:Vector<Int>;
	private var handle:Vector<Int>;
	
	public function new(size:Int)
	{
		this.pos = new Vector<Int>(size);
		this.handle = new Vector<Int>(size);
	}
	
	override public function swap(idx1:Int, idx2:Int):Void
	{
		var tmpPos:Int = pos[idx1];
		var tmpHandle:Int = handle[idx1];
		
		pos[idx1] = pos[idx2];
		handle[idx1] = handle[idx2];

		pos[idx2] = tmpPos;
		handle[idx2] = tmpHandle;
	}
	
	override public function set(dest:Int, src:Int):Void
	{
		pos[dest] = pos[src];
		handle[dest] = handle[src];
	}
	
	override public function getPos(index:Int):Int
	{
		return pos[index];
	}
	
	override public function setPos(index:Int, value:Int):Void
	{
		pos[index] = value;
	}
	
	override public function getHandle(index:Int):Int
	{
		return handle[index];
	}
	
	override public function setHandle(index:Int, value:Int):Void
	{
		handle[index] = value;
	}
}


class HandleImpl32 extends Handle
{
	private var minEdges0:Int;
	private var minEdges1:Int;
	private var minEdges2:Int;

	private var maxEdges0:Int;
	private var maxEdges1:Int;
	private var maxEdges2:Int;
	
	public function new(userPtr:Dynamic, collisionFilterGroup:Int, collisionFilterMask:Int, multiSapParentProxy:Dynamic = null)
	{
		super(userPtr, collisionFilterGroup, collisionFilterMask, multiSapParentProxy);
	}
	
	override public function getMinEdges(edgeIndex:Int):Int 
	{
		switch (edgeIndex)
		{
			case 0:
				return minEdges0;
			case 1:
				return minEdges1;
			case 2:
				return minEdges2;
			default:
				return minEdges0;
		}
	}
	
	override public function setMinEdges(edgeIndex:Int, value:Int):Void 
	{
		switch (edgeIndex)
		{
			case 0:
				minEdges0 = value;
			case 1:
				minEdges1 = value;
			case 2:
				minEdges2 = value;
		}
	}
	
	override public function getMaxEdges(edgeIndex:Int):Int 
	{
		switch (edgeIndex)
		{
			case 0:
				return maxEdges0;
			case 1:
				return maxEdges1;
			case 2:
				return maxEdges2;
			default:
				return maxEdges0;
		}
	}
	
	override public function setMaxEdges(edgeIndex:Int, value:Int):Void 
	{
		switch (edgeIndex) 
		{
			case 0:
				maxEdges0 = value;
			case 1:
				maxEdges1 = value;
			case 2:
				maxEdges2 = value;
		}
	}
}