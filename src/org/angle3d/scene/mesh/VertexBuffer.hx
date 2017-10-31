package org.angle3d.scene.mesh;

import org.angle3d.error.Assert;
import flash.utils.ByteArray;


class VertexBuffer
{
	public var components(get, null):Int;
	public var type(get, null):Int;
	public var dirty(get, set):Bool;
	
	private var mDirty:Bool;

	private var mType:Int;

	private var mData:Vector<Float>;

	private var mComponents:Int;
	
	private var mUsage:Usage = Usage.STATIC;
	
	public var byteArrayData:ByteArray;

	public function new(type:Int,numComponent:Int)
	{
		mType = type;
		mComponents = numComponent;
		mDirty = true;
		
		Assert.assert(mComponents >= 1 && mComponents <= 4, "components长度应该在1～4之间");
	}

	public function updateData(data:Vector<Float>):Void
	{
		#if debug
		if (mData != null && mData.length != 0)
		{
			Assert.assert(mData.length == data.length, "更新的数据长度和原来不一样");
		}
		#end
		
		mData = data;
		dirty = true;
	}

	public inline function getData():Vector<Float>
	{
		return mData;
	}
	
	public function setUsage(usage:Usage):Void
	{
		if (this.mUsage != usage)
		{
			this.mUsage = usage;
			this.dirty = true;
		}
	}
	
	public inline function getUsage():Usage
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
	
	private function get_type():Int
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
	
	public function getNumElements():Int
	{
		if (mData == null)
			return 0;
			
		return Std.int(mData.length / mComponents);
	}
}
