package com.bulletphysics.collision.gimpact ;

import org.angle3d.utils.VectorUtil;
/**
 
 */
class PairSet 
{

    private var array:Array<Pair>;
    private var _size:Int = 0;

    public function new() 
	{
        array = new Array<Pair>(32);
        for (i in 0...array.length)
		{
            array[i] = new Pair();
        }
    }

    public function clear():Void
	{
        _size = 0;
    }

    public function size():Int
	{
        return _size;
    }

    public function get(index:Int):Pair
	{
        return array[index];
    }

    private function expand():Void
	{
        var newArray:Array<Pair> = new Array<Pair>(array.length << 1);
        for (i in array.length...newArray.length)
		{
            newArray[i] = new Pair();
        }
		VectorUtil.blit(array, 0, newArray, 0, array.length);
        array = newArray;
    }

    public function push_pair(index1:Int, index2:Int):Void
	{
        if (_size == array.length)
		{
            expand();
        }
        array[_size].index1 = index1;
        array[_size].index2 = index2;
        _size++;
    }

    public function push_pair_inv(index1:Int, index2:Int):Void
	{
        if (_size == array.length)
		{
            expand();
        }
        array[_size].index1 = index2;
        array[_size].index2 = index1;
        _size++;
    }

}
