package examples.io;
import flash.display.Sprite;
import flash.Lib;
import flash.utils.ByteArray;
import hu.vpmedia.assets.AssetLoader;
import hu.vpmedia.assets.AssetLoaderVO;
import hu.vpmedia.assets.loaders.AssetLoaderType;
import hu.vpmedia.assets.parsers.AssetParserType;
import org.angle3d.io.parser.material.MaterialParser;
import org.angle3d.material.Material;
import org.angle3d.material.MaterialDef;
import org.angle3d.material.shader.DefineList;
import org.angle3d.material.VarType;

class MaterialLoaderTest extends Sprite
{
	static function main()
	{
		Lib.current.addChild(new MaterialLoaderTest());
	}

	public function new() 
	{
		super();
		
		var mat:Material = new Material();
		mat.load("assets/material/unshaded.mat");
	}
}