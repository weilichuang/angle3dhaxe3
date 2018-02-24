package examples.asset;

import examples.BasicExample;
import angle3d.Angle3D;
import angle3d.asset.AssetInfo;
import angle3d.asset.AssetManager;
import angle3d.asset.LoaderType;
import angle3d.asset.caches.NormalCache;
import angle3d.asset.parsers.TextParser;

/**
 * ...
 * @author 
 */
class AssetManagerTest extends BasicExample
{
	static function main()
	{
		flash.Lib.current.addChild(new AssetManagerTest());
	}

	public function new() 
	{
		super();
		
	}
	
	override function initialize(width:Int, height:Int):Void 
	{
		super.initialize(width, height);

		AssetManager.loadAsset(this, LoaderType.TEXT, Angle3D.materialFolder + "material/lighting.mat", onLoaded);
	}
	
	private function onLoaded(assetInfo:AssetInfo):Void
	{
		trace(assetInfo.url);
		trace(assetInfo.content);
	}
}