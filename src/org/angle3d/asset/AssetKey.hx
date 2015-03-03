package org.angle3d.asset;
import org.angle3d.utils.Cloneable;

/**
 * AssetKey is a key that is used to
 * look up a resource from a cache. 
 */
class AssetKey implements Cloneable
{

	public function new() 
	{
		
	}
	
	public function clone():AssetKey
	{
		return new AssetKey();
	}
	
	public function equals(other:AssetKey):Bool
	{
		return false;
	}
	
}