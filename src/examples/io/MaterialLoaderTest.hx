package examples.io;
import flash.display.Sprite;
import flash.Lib;
import flash.utils.ByteArray;
import hu.vpmedia.assets.AssetLoader;
import hu.vpmedia.assets.AssetLoaderVO;
import org.angle3d.io.parser.material.MaterialParser;
import org.angle3d.material.MaterialDef;

class MaterialLoaderTest extends Sprite
{
	static function main()
	{
		Lib.current.addChild(new MaterialLoaderTest());
	}

	public function new() 
	{
		super();
		
		var assetLoader:AssetLoader = new AssetLoader();
		assetLoader.signalSet.completed.add(_loadComplete);
		assetLoader.add("assets/material/unshaded.mat");

		assetLoader.execute();
		
		
	}
	
	private function _loadComplete(loader:AssetLoader):Void
	{
		var assetLoaderVO1:AssetLoaderVO = loader.get("assets/material/unshaded.mat");
		
		var byteArray:ByteArray = assetLoaderVO1.data;
		byteArray.position = 0;
		
		var def:MaterialDef = MaterialParser.parse(byteArray.readUTFBytes(byteArray.length));
	}
	
}