package org.angle3d.asset;
import haxe.ds.StringMap;

class WaitInfo 
{
	public var isCache:Bool = true;
	public var url : String;
	public var timeCount : Int; //超时次数，大于maxTimeoutCount次超时就干掉
	public var priority : Int = Priority.STANDARD;
	public var type : String;
	public var itemMap : StringMap<LoadingItemInfo>;

	public function new() 
	{
		itemMap = new StringMap<LoadingItemInfo>();
	}

	public function dispose() : Void 
	{
		var keys = itemMap.keys();
		for (i in 0...keys.length)
		{
			var item:LoadingItemInfo = itemMap.get(keys[i]);
			item.dispose();
		}
		itemMap = new StringMap<LoadingItemInfo>();
	}
}
