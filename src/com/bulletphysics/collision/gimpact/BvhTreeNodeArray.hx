package com.bulletphysics.collision.gimpact ;
import com.bulletphysics.collision.gimpact.BoxCollision.AABB;

/**
 * ...
 * @author weilichuang
 */
class BvhTreeNodeArray
{

	private var size:Int = 0;

    private var  bound:Array<Float> = [];
    private var escapeIndexOrDataIndex:Array<Int> = [];
	
	public function new()
	{
		
	}

    public function clear():Void
	{
        size = 0;
    }

    public function resize(newSize:Int):Void
	{
		var newBound:Array<Float> = [];
        var newEIODI:Array<Int> = [];
		
		for (i in 0...(newSize * 6))
		{
			newBound[i] = 0;
		}
		
		for (i in 0...(size * 6))
		{
			newBound[i] = bound[i];
		}
		
		for (i in 0...newSize)
		{
			newEIODI[i] = 0;
		}
		for (i in 0...size)
		{
			newEIODI[i] = escapeIndexOrDataIndex[i];
		}

        bound = newBound;
        escapeIndexOrDataIndex = newEIODI;

        size = newSize;
    }

    public function setTreeNodeArray(destIdx:Int, array:BvhTreeNodeArray, srcIdx:Int):Void
	{
        var dpos:Int = destIdx * 6;
        var spos:Int = srcIdx * 6;

        bound[dpos + 0] = array.bound[spos + 0];
        bound[dpos + 1] = array.bound[spos + 1];
        bound[dpos + 2] = array.bound[spos + 2];
        bound[dpos + 3] = array.bound[spos + 3];
        bound[dpos + 4] = array.bound[spos + 4];
        bound[dpos + 5] = array.bound[spos + 5];
        escapeIndexOrDataIndex[destIdx] = array.escapeIndexOrDataIndex[srcIdx];
    }

    public function setDataArray(destIdx:Int, array:BvhDataArray, srcIdx:Int):Void 
	{
        var dpos:Int = destIdx * 6;
        var spos:Int = srcIdx * 6;

        bound[dpos + 0] = array.bound[spos + 0];
        bound[dpos + 1] = array.bound[spos + 1];
        bound[dpos + 2] = array.bound[spos + 2];
        bound[dpos + 3] = array.bound[spos + 3];
        bound[dpos + 4] = array.bound[spos + 4];
        bound[dpos + 5] = array.bound[spos + 5];
        escapeIndexOrDataIndex[destIdx] = array.data[srcIdx];
    }

    public function getBound(nodeIndex:Int, out:AABB):AABB
	{
        var pos:Int = nodeIndex * 6;
        out.min.setTo(bound[pos + 0], bound[pos + 1], bound[pos + 2]);
        out.max.setTo(bound[pos + 3], bound[pos + 4], bound[pos + 5]);
        return out;
    }

    public function setBound(nodeIndex:Int, aabb:AABB):Void
	{
        var pos:Int = nodeIndex * 6;
        bound[pos + 0] = aabb.min.x;
        bound[pos + 1] = aabb.min.y;
        bound[pos + 2] = aabb.min.z;
        bound[pos + 3] = aabb.max.x;
        bound[pos + 4] = aabb.max.y;
        bound[pos + 5] = aabb.max.z;
    }

    public function isLeafNode(nodeIndex:Int):Bool
	{
        // skipindex is negative (internal node), triangleindex >=0 (leafnode)
        return (escapeIndexOrDataIndex[nodeIndex] >= 0);
    }

    public function getEscapeIndex(nodeIndex:Int):Int 
	{
        //btAssert(m_escapeIndexOrDataIndex < 0);
        return -escapeIndexOrDataIndex[nodeIndex];
    }

    public function setEscapeIndex(nodeIndex:Int, index:Int):Void 
	{
        escapeIndexOrDataIndex[nodeIndex] = -index;
    }

    public function getDataIndex(nodeIndex:Int):Int 
	{
        //btAssert(m_escapeIndexOrDataIndex >= 0);
        return escapeIndexOrDataIndex[nodeIndex];
    }

    public function setDataIndex(nodeIndex:Int, index:Int):Void 
	{
        escapeIndexOrDataIndex[nodeIndex] = index;
    }
	
}