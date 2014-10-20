package com.bulletphysics.util;
import haxe.ds.Vector;

/**
 * Stack-based object pool for arbitrary objects, returning not supported.
 * @author weilichuang
 */
class ObjectStackList<T>
{
	//private var list:ObjectArrayList<T> = new ObjectArrayList<T>();
	
	private var list:Array<T> = [];
	private var listSize:Int = 0;
	
	private var stack:Vector<Int> = new Vector<Int>(512);
	private var stackCount:Int = 0;
	private var pos:Int;

	private var cls:Class<T>;
	public function new(cls:Class<T>) 
	{
		this.cls = cls;
	}
	
	/**
     * Pushes the stack.
     */
	public inline function push():Void
	{
		stack[stackCount++] = pos;
	}
	
	/**
     * Pops the stack.
     */
	public inline function pop():Void
	{
		pos = stack[--stackCount];
	}
	
	public inline function get():T
	{
		if (pos == listSize) 
		{
            expand();
        }

        return list[pos++];
	}
	
	private inline function create():T
	{
		return Type.createInstance(cls,[]);
	}
	
	public inline function expand():Void
	{
		list.push(create());
		listSize++;
	}
	
}