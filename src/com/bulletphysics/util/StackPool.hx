package com.bulletphysics.util;
import com.bulletphysics.linearmath.Transform;

import angle3d.math.Matrix3f;
import angle3d.math.Vector3f;
import angle3d.error.Assert;

class StackPool
{
	/**
	 * Allow X instances of TempVars.
	 */
	private static var STACK_SIZE:Int = 8;

	private static var currentIndex:Int = 0;

	private static var varStack:Array<StackPool> = new Array<StackPool>(8);

	public static function get():StackPool
	{
		Assert.assert(currentIndex <= STACK_SIZE - 1);

		var instance:StackPool = varStack[currentIndex];
		if (instance == null)
		{
			instance = new StackPool();
			varStack[currentIndex] = instance;
		}

		currentIndex++;

		instance.isUsed = true;

		return instance;
	}

	private var isUsed:Bool;

	/**
	 * General vectors.
	 */
	private var vecPool:Array<Vector3f>;
	private var vecIndex:Int = 0;

	private var matrix3fPool:Array<Matrix3f>;
	private var matrix3fIndex:Int = 0;
	
	private var transformPool:Array<Transform>;
	private var transformIndex:Int = 0;

	public function new()
	{
		isUsed = false;

		vecPool = [];
		matrix3fPool = [];
		transformPool = [];
		
		for (i in 0...15)
		{
			vecPool[i] = new Vector3f();
		}
		
		vecIndex = 0;
		matrix3fIndex = 0;
		transformIndex = 0;
	}
	
	public inline function getVector3f():Vector3f
	{
		return vecPool[vecIndex++];
	}
	
	public function getMatrix3f():Matrix3f
	{
		//数量不能太多
		Assert.assert(matrix3fIndex <= 10);
		
		var mat:Matrix3f = matrix3fPool[matrix3fIndex];
		if (mat == null)
		{
			mat = new Matrix3f();
			matrix3fPool[matrix3fIndex] = mat;
		}
		matrix3fIndex++;
		return mat;
	}
	
	public function getTransform():Transform
	{
		//数量不能太多
		Assert.assert(transformIndex <= 10);
		
		var trans:Transform = transformPool[transformIndex];
		if (trans == null)
		{
			trans = new Transform();
			transformPool[transformIndex] = trans;
		}
		transformIndex++;
		return trans;
	}

	public function release():Void
	{
		Assert.assert(isUsed);

		isUsed = false;
		
		vecIndex = 0;
		matrix3fIndex = 0;
		transformIndex = 0;

		currentIndex--;

		Assert.assert(varStack[currentIndex] == this);
	}
}