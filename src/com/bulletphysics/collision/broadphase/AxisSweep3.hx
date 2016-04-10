package com.bulletphysics.collision.broadphase;
import com.bulletphysics.collision.broadphase.AxisSweep3Internal.EdgeArray;
import com.bulletphysics.collision.broadphase.AxisSweep3Internal.Handle;
import de.polygonal.ds.error.Assert;
import org.angle3d.math.Vector3f;
import flash.Vector;

/**
 * AxisSweep3 is an efficient implementation of the 3D axis sweep and prune broadphase.<p>
 * <p/>
 * It uses arrays rather then lists for storage of the 3 axis. Also it operates using 16 bit
 * integer coordinates instead of floats. For large worlds and many objects, use {AxisSweep3_32}
 * instead. AxisSweep3_32 has higher precision and allows more than 16384 objects at the cost
 * of more memory and bit of performance.
 
 */
class AxisSweep3 extends AxisSweep3Internal
{

	public function new(worldAabbMin:Vector3f, worldAabbMax:Vector3f, maxHandles:Int = 16384, pairCache:OverlappingPairCache = null)
	{
		super(worldAabbMin, worldAabbMax, 0xfffe, 0xffff, maxHandles, pairCache);
		// 1 handle is reserved as sentinel
        Assert.assert (maxHandles > 1 && maxHandles < 32767);
	}
	
	override function createEdgeArray(size:Int):EdgeArray 
	{
		return new EdgeArrayImpl(size);
	}
	
	override function createHandle():Handle 
	{
		return new HandleImpl(null, 0, 0, null);
	}
	
	override private function getMask():Int
	{
		return 0xFFFF;
	}
}

class EdgeArrayImpl extends EdgeArray
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
		return pos[index] & 0xFFFF;
	}
	
	override public function setPos(index:Int, value:Int):Void
	{
		pos[index] = value;
	}
	
	override public function getHandle(index:Int):Int
	{
		return handle[index] & 0xFFFF;
	}
	
	override public function setHandle(index:Int, value:Int):Void
	{
		handle[index] = value;
	}
}


class HandleImpl extends Handle
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
				return minEdges0 & 0xFFFF;
			case 1:
				return minEdges1 & 0xFFFF;
			case 2:
				return minEdges2 & 0xFFFF;
			default:
				return minEdges0 & 0xFFFF;
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
				return maxEdges0 & 0xFFFF;
			case 1:
				return maxEdges1 & 0xFFFF;
			case 2:
				return maxEdges2 & 0xFFFF;
			default:
				return maxEdges0 & 0xFFFF;
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