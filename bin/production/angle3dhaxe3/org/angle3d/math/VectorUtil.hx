package org.angle3d.math;

import flash.Vector;

class VectorUtil
{
	public static function fillFloat(target:Vector<Float>, value:Float):Void
	{
		var length:Int = target.length;
		for (i in 0...length)
		{
			target[i] = value;
		}
	}

	public static function fillInt(target:Vector<Int>, value:Int):Void
	{
		var length:Int = target.length;
		for (i in 0...length)
		{
			target[i] = value;
		}
	}

	//public static function insert(target:Vector<Float>, position:Int, inserts:Vector<Float>):Void
	//{
		//var lefts:Vector<Float> = target.splice(position, target.length - position);
		//
		//var length:Int = inserts.length;
		//for (i in 0...length)
		//{
			//target.push(inserts[i]);
		//}
//
		//length = lefts.length;
		//for (i in 0...length)
		//{
			//target.push(lefts[i]);
		//}
	//}
}


