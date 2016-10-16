package examples.asset;

import examples.BasicExample;
import org.angle3d.Angle3D;
import org.angle3d.asset.AssetInfo;
import org.angle3d.asset.AssetManager;
import org.angle3d.asset.LoaderType;
import org.angle3d.asset.caches.NormalCache;
import org.angle3d.asset.parsers.TextParser;

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