package examples.io;
import flash.display.Sprite;
import flash.Lib;
import flash.utils.ByteArray;
import org.angle3d.io.parser.material.MaterialParser;
import org.angle3d.material.Material2;
import org.angle3d.material.MaterialDef;

class JsonParseTest extends Sprite
{
	static function main()
	{
		Lib.current.addChild(new JsonParseTest());
	}

	public function new() 
	{
		super();
		
		var fb:ByteArray = new JSON_FILE();
		var str:String = fb.readUTFBytes(fb.length);

		var def:MaterialDef = MaterialParser.parse(str);
		var mat:Material2 = new Material2(def);
	}
	
}

@:file("embed/unshaded.mat") class JSON_FILE extends ByteArray { }