package com.bulletphysics.collision.shapes;
import com.vecmath.FastMath;
import haxe.ds.Vector;

//TODO 此类实现可能有问题，使用的是长整形，有些平台不支持
//修改为整形，试试？
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
 * @author weilichuang
 */
class QuantizedBvhNodes
{
	private static inline var STRIDE:Int = 4;//8 bytes

	private var buf:Vector<Int>;
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
		var oldBuff:Vector<Int> = buf;
		
		buf = new Vector<Int>(num * STRIDE);
		if (oldBuff != null)
		{
			Vector.blit(oldBuff, 0, buf, 0, FastMath.imin(oldBuff.length, buf.length));
		}
	}
	
	public static function getNodeSize():Int
	{
		return STRIDE * 4;
	}
	
	public function set(destId:Int, srcNodes:QuantizedBvhNodes, srcId:Int):Void
	{
		var srcBuf:Vector<Int> = srcNodes.buf;
		
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
                return (buf[nodeId * STRIDE + 0]) & 0xFF;
            case 1:
                return (buf[nodeId * STRIDE + 0] >>> 16) & 0xFF;
            case 2:
                return (buf[nodeId * STRIDE + 1]) & 0xFF;
        }
		return 0;
	}
	
	public function getQuantizedAabbMin(nodeId:Int):Int
	{
		return (buf[nodeId * STRIDE + 0] & 0xFFFF) | ((buf[nodeId * STRIDE + 1] & 0xFF) << 16);
	}
	
	public function setQuantizedAabbMin(nodeId:Int, value:Int):Void
	{
		buf[nodeId * STRIDE + 0] = value;
        setQuantizedAabbMinAt(nodeId, 2, ((value & 0xFF0000) >>> 16));
	}
	
	public function setQuantizedAabbMax(nodeId:Int, value:Int):Void
	{
		setQuantizedAabbMaxAt(nodeId, 0, value);
        buf[nodeId * STRIDE + 2] = (value >>> 8);
	}
	
	public function setQuantizedAabbMinAt(nodeId:Int, index:Int, value:Int):Void
	{
        switch (index)
		{
            case 0:
                buf[nodeId * STRIDE + 0] = (buf[nodeId * STRIDE + 0] & 0xFF00) | (value & 0xFF);
            case 1:
                buf[nodeId * STRIDE + 0] = (buf[nodeId * STRIDE + 0] & 0x00FF) | ((value & 0xFF) << 8);
            case 2:
                buf[nodeId * STRIDE + 1] = (buf[nodeId * STRIDE + 1] & 0xFF00) | (value & 0xFF);
        }
    }

    public function getQuantizedAabbMaxAt(nodeId:Int, index:Int):Int
	{
        switch (index) 
		{
            default:
            case 0:
                return (buf[nodeId * STRIDE + 1] >>> 8) & 0xFF;
            case 1:
                return (buf[nodeId * STRIDE + 2]) & 0xFF;
            case 2:
                return (buf[nodeId * STRIDE + 2] >>> 8) & 0xFF;
        }
		return 0;
    }

    public function getQuantizedAabbMax(nodeId:Int):Int
	{
        return ((buf[nodeId * STRIDE + 1] & 0xFF00) >>> 8) | ((buf[nodeId * STRIDE + 2] & 0xFFFF) << 8);
    }

    public function setQuantizedAabbMaxAt(nodeId:Int, index:Int, value:Int):Void 
	{
        switch (index)
		{
            case 0:
                buf[nodeId * STRIDE + 1] = (buf[nodeId * STRIDE + 1] & 0x00FF) | ((value & 0xFF) << 8);
            case 1:
                buf[nodeId * STRIDE + 2] = (buf[nodeId * STRIDE + 2] & 0xFF00) | (value & 0xFF);
            case 2:
                buf[nodeId * STRIDE + 2] = (buf[nodeId * STRIDE + 2] & 0x00FF) | ((value & 0xFF) << 8);
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
        switch (index) 
		{
            case 0:
                return ((vec & 0x0000FF)) & 0xFF;
            case 1:
                return ((vec & 0x00FF00) >>> 8) & 0xFF;
            case 2:
                return ((vec & 0xFF0000) >>> 16) & 0xFF;
			default:
				return ((vec & 0x0000FF)) & 0xFF;
        }
		return 0;
    }
}