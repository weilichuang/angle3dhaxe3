package examples.sgsl;
import flash.Lib;
import org.angle3d.app.SimpleApplication;
import org.angle3d.math.Vector4f;

/**
 * ...
 * @author weilichuang
 */
class PackUnPackTest extends SimpleApplication
{
	public static function main()
	{       
        Lib.current.addChild(new PackUnPackTest());
    }

	public function new() 
	{
		super();
	}
	
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);
		
		for (i in 0...20)
		{
			var value:Float = Math.random();
			trace("value:" + value);
			var vec:Vector4f = pack(value);
			trace("pack:" + vec);
			trace("unpack:" + unpack(vec));
		}
		
		trace("value:" + 0.999);
		var vec:Vector4f = pack(0.999);
		trace("pack:" + vec);
		trace("unpack:" + unpack(vec));
		
		trace("value:" + 1);
		var vec:Vector4f = pack(1);
		trace("pack:" + vec);
		trace("unpack:" + unpack(vec));
		
		trace("value:" + 0);
		var vec:Vector4f = pack(0);
		trace("pack:" + vec);
		trace("unpack:" + unpack(vec));
	}
	
	private function pack(value:Float):Vector4f
	{
		var bitSh:Array<Float>	= [256 * 256 * 256, 256 * 256,   256,  1];
		var bitMsk:Array<Float>	= [ 0,  1.0 / 256.0,  1.0 / 256.0,  1.0 / 256.0];

		var comp:Vector4f = new Vector4f();
		comp.x = value * bitSh[0];
		comp.y = value * bitSh[1];
		comp.z = value * bitSh[2];
		comp.w = value * bitSh[3];
		
		comp.x = comp.x - Math.floor(comp.x);
		comp.y = comp.y - Math.floor(comp.y);
		comp.z = comp.z - Math.floor(comp.z);
		comp.w = comp.w - Math.floor(comp.w);
		
		var result:Vector4f = new Vector4f();
		result.x = comp.x - comp.x * bitMsk[0];
		result.y = comp.y - comp.x * bitMsk[1];
		result.z = comp.z - comp.y * bitMsk[2];
		result.w = comp.w - comp.z * bitMsk[3];
		
		return result;
	}
	
	private function unpack(vec:Vector4f):Float
	{
		var bitShifts:Vector4f = new Vector4f(1.0 / (256.0 * 256.0 * 256.0), 1.0 / (256.0 * 256.0), 1.0 / 256.0, 1);
		return vec.dot(bitShifts);
	}
}