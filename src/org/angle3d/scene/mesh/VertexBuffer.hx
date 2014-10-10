package org.angle3d.scene.mesh;

import org.angle3d.utils.Assert;
import flash.Vector;

class VertexBuffer
{
	public var components(get, null):Int;
	public var count(get, null):Int;
	public var type(get, null):String;
	public var dirty(get, set):Bool;
	
	private var mCount:Int;

	private var mDirty:Bool;

	private var mType:String;

	private var mData:Vector<Float>;

	private var mComponents:Int;
	
	private var mUsage:Usage = Usage.STATIC;

	public function new(type:String)
	{
		mType = type;

		mCount = 0;
		mDirty = true;
	}

	/**
	 *
	 * @param	data
	 * @param	components
	 */
	public function setData(data:Vector<Float>, components:Int):Void
	{
		mData = data;

		mComponents = components;
		
		Assert.assert(mComponents >= 1 && mComponents <= 4, "components长度应该在1～4之间");

		mCount = Std.int(mData.length / mComponents);

		dirty = true;
	}

	public function updateData(data:Vector<Float>):Void
	{
		mData = data;

		Assert.assert(Std.int(mData.length / mComponents) == mCount, "更新的数组长度应该和之前相同");

		dirty = true;
	}

	public inline function getData():Vector<Float>
	{
		return mData;
	}
	
	public function setUsage(usage:Usage):Void
	{
		this.mUsage = usage;
	}
	
	public function getUsage():Usage
	{
		return this.mUsage;
	}

	public function clean():Void
	{
		dirty = true;
		mData = null;
	}

	/**
	 * 销毁
	 */
	public function destroy():Void
	{
		mData = null;
	}

	private function get_components():Int
	{
		return mComponents;
	}
	
	private function get_count():Int
	{
		return mCount;
	}

	
	private function get_type():String
	{
		return mType;
	}

	
	private function get_dirty():Bool
	{
		return mDirty;
	}

	/**
	 * Internal use only. Indicates that the object has changed
	 * and its state needs to be updated.
	 */
	private function set_dirty(value:Bool):Bool
	{
		mDirty = value;
		return mDirty;
	}
}
