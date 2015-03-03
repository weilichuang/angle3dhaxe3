package org.angle3d.asset.cache;
import haxe.ds.ObjectMap;
import org.angle3d.asset.AssetKey;

/**
 * SimpleAssetCache is an asset cache
 * that caches assets without any automatic removal policy. The user
 * is expected to manually call {@link #deleteFromCache(com.jme3.asset.AssetKey) }
 * to delete any assets.
 * 
 * @author Kirill Vainer
 */
@:generic
class SimpleAssetCache<T> implements AssetCache<T>
{
	private var keyList:Array<AssetKey>;
	private var assetList:Array<T>;

	public function new() 
	{
		keyList = [];
		assetList = [];
	}
	
	/* INTERFACE org.angle3d.asset.cache.AssetCache.AssetCache<T> */
	
	//keyList里面只保存最先存入的key
	public function addToCache(key:AssetKey, obj:T):Void 
	{
		for (i in 0...keyList.length)
		{
			if (keyList[i].equals(key))
			{
				assetList[i] = obj;
				return;
			}
		}
		keyList.push(key);
		assetList.push(obj);
	}
	
	public function registerAssetClone(key:AssetKey, clone:T):Void 
	{
		
	}
	
	public function notifyNoAssetClone():Void 
	{
		
	}
	
	public function getFromCache(key:AssetKey):T 
	{
		for (i in 0...keyList.length)
		{
			if (keyList[i].equals(key))
			{
				return assetList[i];
			}
		}
		
		var value:Null<T> = null;
		return value;
	}
	
	public function deleteFromCache(key:AssetKey):Bool 
	{
		var i:Int = 0;
		while (i < keyList.length)
		{
			if (keyList[i].equals(key))
			{
				keyList.splice(i, 1);
				assetList.splice(i, 1);
				return true;
			}
			i++;
		}
		return false;
	}
	
	public function clearCache():Void 
	{
		keyList = [];
		assetList = [];
	}
	
}