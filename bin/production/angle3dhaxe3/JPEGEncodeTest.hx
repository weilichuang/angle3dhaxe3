package ;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.Lib;
import de.polygonal.gl.codec.JPEGEncode;
import flash.utils.ByteArray;
/**
 * ...
 * @author 
 */
class JPEGEncodeTest extends Sprite
{
	static function main()
	{
		Lib.current.addChild(new JPEGEncodeTest());
	}

	public function new() 
	{
		super();
		
		var bitmapData:BitmapData = new EmbedPositiveZ(0, 0);
		
		var byteArray:ByteArray = JPEGEncode.encode(bitmapData, bitmapData.width, bitmapData.height);
	}
	
}

@:bitmap("embed/sky/positiveZ.png") class EmbedPositiveZ extends flash.display.BitmapData { }
