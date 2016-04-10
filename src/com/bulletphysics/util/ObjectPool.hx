package com.bulletphysics.util;
import haxe.ds.ObjectMap;

/**
 * ...
 
 */
class ObjectPool<T>
{
	private var cls:Class<T>;
	private var list:Array<T>;
	private var size:Int = 0;
	
	private static var tmpParams:Array<Dynamic> = [];

	public function new(cls:Class<T>) 
	{
		this.cls = cls;
		this.list = [];
	}
	
	public inline function get():T
	{
		if (size > 0)
		{
			size--;
			return list[size];
		}
		else
		{
			return Type.createInstance(cls, tmpParams);
		}
	}
	
	public inline function release(obj:T):Void
	{
		list[size] = obj;
		size++;
	}
	
	private static var map:ObjectMap<Dynamic,Dynamic> = new ObjectMap<Dynamic,Dynamic>();
	public static function getPool<T>(cls:Class<T>):ObjectPool<T>
	{
		if (map.exists(cls))
		{
			return map.get(cls);
		}
		else
		{
			var pool:ObjectPool<T> = new ObjectPool<T>(cls);
			map.set(cls, pool);
			return pool;
		}
	}
	
	public static function cleanPools():Void
	{
		map = new ObjectMap<Dynamic,Dynamic>();
	}
}