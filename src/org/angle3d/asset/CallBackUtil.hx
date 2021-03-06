package org.angle3d.asset;
import org.angle3d.ds.FastHashMap;
import org.angle3d.ds.FastStringMap;

class CallBackUtil
{
	public static function open( itemMap : FastHashMap<LoadingItemInfo>, url : String ) : Void
	{
		var keys = itemMap.keys();
		for (i in 0...keys.length)
		{
			var itemInfo:LoadingItemInfo = itemMap.get(keys[i]);
			if ( itemInfo.openHandler != null )
			{
				callBack( itemInfo.openHandler, url, itemInfo.data );
			}
		}
	}

	public static function progress( itemMap : FastHashMap<LoadingItemInfo>, bytesLoaded : Float, bytesTotal : Float ) : Void
	{
		var percent : Float = bytesLoaded / bytesTotal;
		var keys = itemMap.keys();
		for (i in 0...keys.length)
		{
			var itemInfo:LoadingItemInfo = itemMap.get(keys[i]);
			if ( itemInfo.progressHandler != null ) 
			{
				itemInfo.progressHandler( percent );
			}
		}
	}

	public static function error( itemMap : FastHashMap<LoadingItemInfo>, url : String ) : Void
	{
		var keys = itemMap.keys();
		for (i in 0...keys.length)
		{
			var itemInfo:LoadingItemInfo = itemMap.get(keys[i]);
			if ( itemInfo.errorHandler != null )
			{
				callBack( itemInfo.errorHandler, url, itemInfo.data );
			}
		}
	}

	public static function complete( itemMap : FastHashMap<LoadingItemInfo>, assetInfo : AssetInfo ) : Void 
	{
		var keys = itemMap.keys();
		for (i in 0...keys.length)
		{
			var itemInfo:LoadingItemInfo = itemMap.get(keys[i]);
			if ( itemInfo.ref != null )
				assetInfo.addOwner( itemInfo.ref );
			if ( itemInfo.completeHandler != null )
			{
				callBack( itemInfo.completeHandler, assetInfo, itemInfo.data );
			}
		}
	}

	public static function callBack( fun : Dynamic, o:Dynamic, data : Dynamic) : Void 
	{
		switch ( fun.length ) 
		{
			case 1:  
				fun( o );
			case 2: 
				fun( o, data );
			default:  
				throw "加载相关回调参数必须是1或2个";
		}
	}
}
