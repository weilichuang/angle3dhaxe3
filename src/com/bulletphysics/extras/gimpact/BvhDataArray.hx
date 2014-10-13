package com.bulletphysics.extras.gimpact;
import com.bulletphysics.extras.gimpact.BoxCollision.AABB;
import vecmath.Vector3f;

/**
 * ...
 * @author weilichuang
 */
class BvhDataArray
{
	private var _size:Int = 0;

    public var bound:Array<Float> = [];
    public var data:Array<Int> = [];

    public function size():Int
	{
        return _size;
    }

    public function resize(newSize:Int):Void
	{
        var newBound:Array<Float> = [];
        var newData:Array<Int> = [];
		
		for (i in 0...(newSize * 6))
		{
			newBound[i] = 0;
		}
		
		for (i in 0...(_size * 6))
		{
			newBound[i] = bound[i];
		}
		
		for (i in 0...newSize)
		{
			newData[i] = 0;
		}
		for (i in 0..._size)
		{
			newData[i] = data[i];
		}

        bound = newBound;
        data = newData;

        _size = newSize;
    }

    public function swap(idx1:Int, idx2:Int):Void
	{
        var pos1:Int = idx1 * 6;
        var pos2:Int = idx2 * 6;

        var b0:Float = bound[pos1 + 0];
        var b1:Float = bound[pos1 + 1];
        var b2:Float = bound[pos1 + 2];
        var b3:Float = bound[pos1 + 3];
        var b4:Float = bound[pos1 + 4];
        var b5:Float = bound[pos1 + 5];
        var d:Int = data[idx1];

        bound[pos1 + 0] = bound[pos2 + 0];
        bound[pos1 + 1] = bound[pos2 + 1];
        bound[pos1 + 2] = bound[pos2 + 2];
        bound[pos1 + 3] = bound[pos2 + 3];
        bound[pos1 + 4] = bound[pos2 + 4];
        bound[pos1 + 5] = bound[pos2 + 5];
        data[idx1] = data[idx2];

        bound[pos2 + 0] = b0;
        bound[pos2 + 1] = b1;
        bound[pos2 + 2] = b2;
        bound[pos2 + 3] = b3;
        bound[pos2 + 4] = b4;
        bound[pos2 + 5] = b5;
        data[idx2] = d;
    }

    public function getBound(idx:Int, out:AABB):AABB
	{
        var pos:Int = idx * 6;
        out.min.setTo(bound[pos + 0], bound[pos + 1], bound[pos + 2]);
        out.max.setTo(bound[pos + 3], bound[pos + 4], bound[pos + 5]);
        return out;
    }

    public function getBoundMin(idx:Int, out:Vector3f):Vector3f 
	{
        var pos:Int = idx * 6;
        out.setTo(bound[pos + 0], bound[pos + 1], bound[pos + 2]);
        return out;
    }

    public function getBoundMax(idx:Int, out:Vector3f):Vector3f 
	{
        var pos:Int = idx * 6;
        out.setTo(bound[pos + 3], bound[pos + 4], bound[pos + 5]);
        return out;
    }

    public function setBound(idx:Int, aabb:AABB):Void 
	{
        var pos:Int = idx * 6;
        bound[pos + 0] = aabb.min.x;
        bound[pos + 1] = aabb.min.y;
        bound[pos + 2] = aabb.min.z;
        bound[pos + 3] = aabb.max.x;
        bound[pos + 4] = aabb.max.y;
        bound[pos + 5] = aabb.max.z;
    }

    public function getData(idx:Int):Int
	{
        return data[idx];
    }

    public function setData(idx:Int, value:Int):Void 
	{
        data[idx] = value;
    }
}