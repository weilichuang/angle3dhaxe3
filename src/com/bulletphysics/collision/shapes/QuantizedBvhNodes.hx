package com.bulletphysics.collision.shapes;
import org.angle3d.math.FastMath;

import org.angle3d.utils.VectorUtil;

//TODO 需要修改，flash不支持长整形，需要换一种方式实现
/**
 * QuantizedBvhNodes is array of compressed AABB nodes, each of 8 bytes.
 * Node can be used for leaf node or internal node. Leaf nodes can point to 16-bit
 * triangle index (non-negative range).<p>
 * <p/>
 * <i>Implementation note:</i> the nodes are internally stored in int[] array
 * and bit packed. The actual structure is:
 * <p/>
 * <pre>
 * unsigned short  quantizedAabbMin[3]
 * unsigned short  quantizedAabbMax[3]
 * signed   int    escapeIndexOrTriangleIndex
 * </pre>
 
 */
class QuantizedBvhNodes
{
	private static inline var STRIDE:Int = 4;//16 bytes

	private var buf:Array<Int>;
	private var _size:Int = 0;
	
	public function new() 
	{
		resize(16);
	}
	
	public function add():Int
	{
		while (_size + 1 >= capacity())
		{
			resize(capacity() * 2);
		}
		return _size++;
	}
	
	public function size():Int
	{
		return _size;
	}
	
	public function capacity():Int
	{
		return Std.int(buf.length / STRIDE);
	}
	
	public function clear():Void
	{
		_size = 0;
	}
	
	public function resize(num:Int):Void
	{
		var oldBuff:Array<Int> = buf;
		
		buf = new Array<Int>(num * STRIDE);
		if (oldBuff != null)
		{
			VectorUtil.blit(oldBuff, 0, buf, 0, FastMath.minInt(oldBuff.length, buf.length));
		}
	}
	
	public static function getNodeSize():Int
	{
		return STRIDE * 4;
	}
	
	public function set(destId:Int, srcNodes:QuantizedBvhNodes, srcId:Int):Void
	{
		var srcBuf:Array<Int> = srcNodes.buf;
		
		buf[destId * STRIDE + 0] = srcBuf[srcId * STRIDE + 0];
        buf[destId * STRIDE + 1] = srcBuf[srcId * STRIDE + 1];
        buf[destId * STRIDE + 2] = srcBuf[srcId * STRIDE + 2];
        buf[destId * STRIDE + 3] = srcBuf[srcId * STRIDE + 3];
	}
	
	public function swap(id1:Int, id2:Int):Void
	{
		var temp0:Int = buf[id1 * STRIDE + 0];
        var temp1:Int = buf[id1 * STRIDE + 1];
        var temp2:Int = buf[id1 * STRIDE + 2];
        var temp3:Int = buf[id1 * STRIDE + 3];

        buf[id1 * STRIDE + 0] = buf[id2 * STRIDE + 0];
        buf[id1 * STRIDE + 1] = buf[id2 * STRIDE + 1];
        buf[id1 * STRIDE + 2] = buf[id2 * STRIDE + 2];
        buf[id1 * STRIDE + 3] = buf[id2 * STRIDE + 3];

        buf[id2 * STRIDE + 0] = temp0;
        buf[id2 * STRIDE + 1] = temp1;
        buf[id2 * STRIDE + 2] = temp2;
        buf[id2 * STRIDE + 3] = temp3;
	}
	
	public function getQuantizedAabbMinAt(nodeId:Int, index:Int):Int
	{
		switch (index)
		{
            default:
            case 0:
                return (buf[nodeId * STRIDE + 0]) & 0xFFFF;
            case 1:
                return (buf[nodeId * STRIDE + 0] >>> 16) & 0xFFFF;
            case 2:
                return (buf[nodeId * STRIDE + 1]) & 0xFFFF;
        }
		return 0;
	}
	
	public function getQuantizedAabbMin(nodeId:Int):Int
	{
		return 0;
		//return (buf[nodeId * STRIDE + 0] & 0xFFFFFFFF) | ((buf[nodeId * STRIDE + 1] & 0xFFFF) << 32);
	}
	
	public function setQuantizedAabbMin(nodeId:Int, value:Int):Void
	{
		buf[nodeId * STRIDE + 0] = value;
        //setQuantizedAabbMinAt(nodeId, 2, ((value & 0xFFFF00000000) >>> 32));
	}
	
	public function setQuantizedAabbMax(nodeId:Int, value:Int):Void
	{
		setQuantizedAabbMaxAt(nodeId, 0, value);
        buf[nodeId * STRIDE + 2] = (value >>> 16);
	}
	
	public function setQuantizedAabbMinAt(nodeId:Int, index:Int, value:Int):Void
	{
        switch (index)
		{
            case 0:
                buf[nodeId * STRIDE + 0] = (buf[nodeId * STRIDE + 0] & 0xFFFF0000) | (value & 0xFFFF);
            case 1:
                buf[nodeId * STRIDE + 0] = (buf[nodeId * STRIDE + 0] & 0x0000FFFF) | ((value & 0xFFFF) << 8);
            case 2:
                buf[nodeId * STRIDE + 1] = (buf[nodeId * STRIDE + 1] & 0xFFFF0000) | (value & 0xFFFF);
        }
    }

    public function getQuantizedAabbMaxAt(nodeId:Int, index:Int):Int
	{
        switch (index) 
		{
            default:
            case 0:
                return (buf[nodeId * STRIDE + 1] >>> 16) & 0xFFFF;
            case 1:
                return (buf[nodeId * STRIDE + 2]) & 0xFFFF;
            case 2:
                return (buf[nodeId * STRIDE + 2] >>> 16) & 0xFFFF;
        }
		return 0;
    }

    public function getQuantizedAabbMax(nodeId:Int):Int
	{
        return ((buf[nodeId * STRIDE + 1] & 0xFFFF0000) >>> 8) | ((buf[nodeId * STRIDE + 2] & 0xFFFFFFFF) << 8);
    }

    public function setQuantizedAabbMaxAt(nodeId:Int, index:Int, value:Int):Void 
	{
        switch (index)
		{
            case 0:
                buf[nodeId * STRIDE + 1] = (buf[nodeId * STRIDE + 1] & 0x0000FFFF) | ((value & 0xFFFF) << 16);
            case 1:
                buf[nodeId * STRIDE + 2] = (buf[nodeId * STRIDE + 2] & 0xFFFF0000) | (value & 0xFFFF);
            case 2:
                buf[nodeId * STRIDE + 2] = (buf[nodeId * STRIDE + 2] & 0x0000FFFF) | ((value & 0xFFFF) << 16);
        }
    }

    public function getEscapeIndexOrTriangleIndex(nodeId:Int):Int
	{
        return buf[nodeId * STRIDE + 3];
    }

    public function setEscapeIndexOrTriangleIndex(nodeId:Int, value:Int):Void
	{
        buf[nodeId * STRIDE + 3] = value;
    }

    public function isLeafNode(nodeId:Int):Bool
	{
        // skipindex is negative (internal node), triangleindex >=0 (leafnode)
        return (getEscapeIndexOrTriangleIndex(nodeId) >= 0);
    }

    public function getEscapeIndex(nodeId:Int):Int
	{
        //assert (!isLeafNode(nodeId));
        return -getEscapeIndexOrTriangleIndex(nodeId);
    }

    public function getTriangleIndex(nodeId:Int):Int
	{
        //assert (isLeafNode(nodeId));
        // Get only the lower bits where the triangle index is stored
        return (getEscapeIndexOrTriangleIndex(nodeId) & ~((~0) << (31 - OptimizedBvh.MAX_NUM_PARTS_IN_BITS)));
    }

    public function getPartId(nodeId:Int):Int
	{
        //assert (isLeafNode(nodeId));
        // Get only the highest bits where the part index is stored
        return (getEscapeIndexOrTriangleIndex(nodeId) >>> (31 - OptimizedBvh.MAX_NUM_PARTS_IN_BITS));
    }

    public static function getCoord(vec:Int, index:Int):Int
	{
        //switch (index) 
		//{
            //case 0:
                //return ((vec & 0x00000000FFFF)) & 0xFFFF;
            //case 1:
                //return ((vec & 0x0000FFFF0000) >>> 16) & 0xFFFF;
            //case 2:
                //return ((vec & 0xFFFF00000000) >>> 32) & 0xFFFF;
			//default:
				//return ((vec & 0x00000000FFFF)) & 0xFFFF;
        //}
		return 0;
    }
}