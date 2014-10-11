package org.angle3d.scene.mesh;

import org.angle3d.utils.Assert;
import flash.Vector;

class VertexBuffer
{
	public var components(get, null):Int;
	public var type(get, null):String;
	public var dirty(get, set):Bool;
	
	private var mDirty:Bool;

	private var mType:String;

	private var mData:Vector<Float>;

	private var mComponents:Int;
	
	private var mUsage:Usage = Usage.STATIC;

	public function new(type:String,numComponent:Int)
	{
		mType = type;
		mComponents = numComponent;
		mDirty = true;
		
		Assert.assert(mComponents >= 1 && mComponents <= 4, "components长度应该在1～4之间");
	}

	public function updateData(data:Vector<Float>):Void
	{
		//Assert.assert(mData != null && mData.length == data.length, "更新的数据长度和原来不一样");
		mData = data;
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
	
	private function get_type():String
	{
		return mType;
	}

	
	private inline function get_dirty():Bool
	{
		return mDirty;
	}

	/**
	 * Internal use only. Indicates that the object has changed
	 * and its state needs to be updated.
	 */
	private inline function set_dirty(value:Bool):Bool
	{
		return mDirty = value;
	}
}
