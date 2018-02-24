package examples.sgsl;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;

import angle3d.app.SimpleApplication;
import angle3d.math.Matrix4f;
import angle3d.math.Vector4f;

/**
 * ...
 
 */
class PackUnPackTest extends BasicExample
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
		
		var matrix:Matrix3D = new Matrix3D();
		matrix.position = new Vector3D(4, 5, 6);
		trace(matrix.rawData);
		
		var matrix4f:Matrix4f = new Matrix4f();
		matrix4f.setTo(-0.09828165322598402,
							2.7755575615628915E-18,
							-0.018458511293368934,
							0.08820332661299202,
							-0.014870918660108473,
							0.05924051605556477,
							0.07917965038868771,
							-0.07785527461438099,
							-0.014831888802153496,
							-0.10927531892759756,
							0.0789718373693155,
							0.42600317654216197,
							0,
							0,
							0,
							1);
							
							
		var vec0:Vector4f = new Vector4f( -1.3, -0.3, -1.3, 1);
		var vec1:Vector4f = new Vector4f( 1.3, -0.3, -1.3, 1);
		var vec2:Vector4f = new Vector4f( 1.3, 0.3, -1.3, 1);
		var vec3:Vector4f = new Vector4f( -1.3, 0.3, -1.3, 1);
		var vec4:Vector4f = new Vector4f( -1000.3, 0.3, -10000.3, 1);
		
		trace("transformVec0:" + matrix4f.multVec4(vec0));
		trace("transformVec1:" + matrix4f.multVec4(vec1));
		trace("transformVec2:" + matrix4f.multVec4(vec2));
		trace("transformVec3:" + matrix4f.multVec4(vec3));
		trace("transformVec4:" + matrix4f.multVec4(vec4));
	}
	
	private function pack(value:Float):Vector4f
	{
		var bitSh:Array<Float>	= [255 * 255 * 255, 255 * 255,   255,  1];
		var bitMsk:Array<Float>	= [ 0,  1.0 / 255.0,  1.0 / 255.0,  1.0 / 255.0];

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
		var bitShifts:Vector4f = new Vector4f(1.0 / (255.0 * 255.0 * 255.0), 1.0 / (255.0 * 255.0), 1.0 / 255.0, 1);
		return vec.dot(bitShifts);
	}
}