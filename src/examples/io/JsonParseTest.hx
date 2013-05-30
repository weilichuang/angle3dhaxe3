package examples.io;

import flash.display.Sprite;
import flash.Lib;
import flash.utils.ByteArray;
import haxe.Json;
import org.angle3d.io.MaterialParser;
import org.angle3d.material.MaterialDef;

@:file("embed/unshaded.json") class JSON_FILE extends ByteArray { }
/**
 * ...
 * @author 
 */
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
	}
	
}