package com.bulletphysics.util;
import haxe.ds.Vector;

/**
 * Stack-based object pool for arbitrary objects, returning not supported.
 * @author weilichuang
 */
class ObjectStackList<T>
{
	private var list:ObjectArrayList<T> = new ObjectArrayList<T>();
	
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
	public function push():Void
	{
		stack[stackCount++] = pos;
	}
	
	/**
     * Pops the stack.
     */
	public function pop():Void
	{
		pos = stack[--stackCount];
	}
	
	public function get():T
	{
		if (pos == list.size()) 
		{
            expand();
        }

        return list.getQuick(pos++);
	}
	
	private function create():T
	{
		return Type.createInstance(cls,[]);
	}
	
	public function expand():Void
	{
		list.add(create());
	}
	
}