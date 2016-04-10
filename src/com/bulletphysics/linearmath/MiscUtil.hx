package com.bulletphysics.linearmath;
import com.bulletphysics.util.FloatArrayList;
import com.bulletphysics.util.IntArrayList;
import com.bulletphysics.util.ObjectArrayList;

/**
 * ...
 
 */
class MiscUtil
{
	/**
     * Ensures valid index in provided list by filling list with provided values
     * until the index is valid.
     */
	public static function ensureIndex<T>(list:ObjectArrayList<T>, index:Int, value:T):Void
	{
		while (list.size() <= index)
		{
            list.add(value);
        }
	}
	
	public static function resizeIntArrayList(list:IntArrayList, size:Int, value:Int):Void
	{
		while (list.size() < size)
		{
			list.add(value);
		}
		
		while (list.size() > size)
		{
			list.remove(list.size() - 1);
		}
	}
	
	public static function resizeFloatArrayList(list:FloatArrayList, size:Int, value:Float):Void
	{
		while (list.size() < size)
		{
			list.add(value);
		}
		
		while (list.size() > size)
		{
			list.remove(list.size() - 1);
		}
	}
	
	public static function GEN_clamped(a:Float, min:Float, max:Float):Float
	{
		return a < min ? min : (max < a ? max : a);
	}
	
	public function new() 
	{
		
	}
	
}