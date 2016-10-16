package org.angle3d.asset;
import org.angle3d.ds.FastHashMap;

class WaitInfo 
{
	public var isCache:Bool = true;
	public var url : String;
	public var timeCount : Int; //超时次数，大于maxTimeoutCount次超时就干掉
	public var priority : Int = Priority.STANDARD;
	public var type : String;
	public var itemMap : FastHashMap<LoadingItemInfo>;

	public function new() 
	{
		itemMap = new FastHashMap<LoadingItemInfo>();
	}

	public function dispose() : Void 
	{
		var keys = itemMap.keys();
		for (i in 0...keys.length)
		{
			var item:LoadingItemInfo = itemMap.get(keys[i]);
			item.dispose();
		}
		itemMap = new FastHashMap<LoadingItemInfo>();
	}
}
