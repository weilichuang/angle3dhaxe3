package com.bulletphysics.util;
import haxe.ds.ObjectMap;

/**
 * ...
 * @author weilichuang
 */
class ObjectPool<T>
{
	private var cls:Class<T>;
	private var list:Array<T>;
	private var size:Int = 0;

	public function new(cls:Class<T>) 
	{
		this.cls = cls;
		this.list = [];
	}
	
	public function get():T
	{
		if (size > 0)
		{
			size--;
			return list[size];
		}
		else
		{
			return Type.createInstance(cls, []);
		}
	}
	
	public function release(obj:T):Void
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