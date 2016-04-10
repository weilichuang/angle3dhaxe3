package org.angle3d.terrain.noise ;
import flash.Vector;

/**
 * Helper class containing useful functions explained in the book:
 * Texturing &amp; Modeling - A Procedural Approach
 * 

 * 
 */
class ShaderUtils {

	public static function i2c(color:Int):Array<Float>
	{
		return [(color & 0x00ff0000) / 256, (color & 0x0000ff00) / 256, (color & 0x000000ff) / 256, (color & 0xff000000) / 256 ];
	}

	public static function c2i(color:Array<Float>):Int
	{
		return (color.length == 4 ? Std.int(color[3] * 256) : 0xff000000) | (Std.int(color[0] * 256) << 16) | (Std.int(color[1] * 256) << 8)
				| Std.int(color[2] * 256);
	}

	public static function mix(a:Float, b:Float, f:Float):Float 
	{
		return (1 - f) * a + f * b;
	}

	public static function mixInt(a:Int, b:Int, f:Int):Float 
	{
		return Std.int((1 - f) * a + f * b);
	}

	public static function mixArray(c1:Array<Float>, c2:Array<Float>, f:Float):Array<Float>
	{
		return [ShaderUtils.mix(c1[0], c2[0], f), ShaderUtils.mix(c1[1], c2[1], f), ShaderUtils.mix(c1[2], c2[2], f)];
	}

	public static function step( a:Float, x:Float):Float
	{
		return x < a ? 0 : 1;
	}

	public static function boxstep( a:Float,  b:Float, x:Float):Float
	{
		return ShaderUtils.clamp((x - a) / (b - a), 0, 1);
	}

	public static function pulse( a:Float,  b:Float, x:Float):Float
	{
		return ShaderUtils.step(a, x) - ShaderUtils.step(b, x);
	}

	public static function clamp(x:Float, a:Float, b:Float):Float 
	{
		return x < a ? a : x > b ? b : x;
	}

	public static function min( a:Float, b:Float):Float 
	{
		return a < b ? a : b;
	}

	public static function max( a:Float, b:Float):Float 
	{
		return a > b ? a : b;
	}

	public static function abs( x:Float):Float 
	{
		return x < 0 ? -x : x;
	}

	public static function smoothstep( a:Float, b:Float, x:Float):Float
	{
		if (x < a) 
		{
			return 0;
		} 
		else if (x > b)
		{
			return 1;
		}
		var xx:Float = (x - a) / (b - a);
		return xx * xx * (3 - 2 * xx);
	}

	public static function mod( a:Float, b:Float):Float 
	{
		var n:Int = Std.int(a / b);
		var aa:Float = a - n * b;
		if (aa < 0)
		{
			aa += b;
		}
		return aa;
	}

	public static function floor(x:Float):Int 
	{
		return x > 0 ? Std.int(x) : Std.int(x) - 1;
	}

	public static function ceil(x:Float):Int
	{
		return Std.int(x) + (x > 0 && x != Std.int(x) ? 1 : 0);
	}

	public static function spline(x:Float, knot:Vector<Float>):Float 
	{
		var CR00:Float = -0.5;
		var CR01:Float = 1.5;
		var CR02:Float = -1.5;
		var CR03:Float = 0.5;
		var CR10:Float = 1.0;
		var CR11:Float = -2.5;
		var CR12:Float = 2.0;
		var CR13:Float = -0.5;
		var CR20:Float = -0.5;
		var CR21:Float = 0.0;
		var CR22:Float = 0.5;
		var CR23:Float = 0.0;
		var CR30:Float = 0.0;
		var CR31:Float = 1.0;
		var CR32:Float = 0.0;
		var CR33:Float = 0.0;

		var span:Int;
		var nspans:Int = knot.length - 3;
		var c0:Float, c1:Float, c2:Float, c3:Float; /* coefficients of the cubic. */
		if (nspans < 1) /* illegal */
		{
			throw "Spline has too few knots.";
		}
		/* Find the appropriate 4-point span of the spline. */
		x = ShaderUtils.clamp(x, 0, 1) * nspans;
		span = Std.int(x);
		if (span >= knot.length - 3)
		{
			span = knot.length - 3;
		}
		x -= span;
		/* Evaluate the span cubic at x using Horner’s rule. */
		c3 = CR00 * knot[span + 0] + CR01 * knot[span + 1] + CR02 * knot[span + 2] + CR03 * knot[span + 3];
		c2 = CR10 * knot[span + 0] + CR11 * knot[span + 1] + CR12 * knot[span + 2] + CR13 * knot[span + 3];
		c1 = CR20 * knot[span + 0] + CR21 * knot[span + 1] + CR22 * knot[span + 2] + CR23 * knot[span + 3];
		c0 = CR30 * knot[span + 0] + CR31 * knot[span + 1] + CR32 * knot[span + 2] + CR33 * knot[span + 3];
		return ((c3 * x + c2) * x + c1) * x + c0;
	}

	public static function splines(x:Float, knots:Vector<Vector<Float>>):Vector<Float>
	{
		var retval:Vector<Float> = new Vector<Float>(knots.length);
		for (i in 0...knots.length)
		{
			retval[i] = ShaderUtils.spline(x, knots[i]);
		}
		return retval;
	}

	public static function gammaCorrection( gamma:Float, x:Float):Float
	{
		return Math.pow(x, 1 / gamma);
	}

	public static function bias( b:Float, x:Float):Float 
	{
		return Math.pow(x, Math.log(b) / Math.log(0.5));
	}

	public static function gain( g:Float,  x:Float):Float 
	{
		return x < 0.5 ? ShaderUtils.bias(1 - g, 2 * x) / 2 : 1 - ShaderUtils.bias(1 - g, 2 - 2 * x) / 2;
	}

	public static function sinValue( s:Float,  minFreq:Float,  maxFreq:Float,  swidth:Float):Float
	{
		var value:Float = 0;
		var cutoff:Float = ShaderUtils.clamp(0.5 / swidth, 0, maxFreq);
		var f:Float = minFreq;
		while (f < 0.5 * cutoff)
		{
			value += Math.sin(2 * Math.PI * f * s) / f;
			f *= 2;
		}
		var fade:Float = ShaderUtils.clamp(2 * (cutoff - f) / cutoff, 0, 1);
		value += fade * Math.sin(2 * Math.PI * f * s) / f;
		return value;
	}

	public static function length(x:Float, y:Float, z:Float):Float 
	{
		return Math.sqrt(x * x + y * y + z * z);
	}

	public static function rotate(v:Array<Float>, m:Array<Array<Float>>):Array<Float>
	{
		var x:Float = v[0] * m[0][0] + v[1] * m[0][1] + v[2] * m[0][2];
		var y:Float = v[0] * m[1][0] + v[1] * m[1][1] + v[2] * m[1][2];
		var z:Float = v[0] * m[2][0] + v[1] * m[2][1] + v[2] * m[2][2];
		return [x, y, z ];
	}

	public static function calcRotationMatrix(ax:Float, ay:Float, az:Float):Array<Array<Float>>
	{
		var retval:Array<Array<Float>> = new Array<Array<Float>>();
		for (i in 0...3)
		{
			retval[i] = [];
		}
		var cax:Float = Math.cos(ax);
		var sax:Float = Math.sin(ax);
		var cay:Float = Math.cos(ay);
		var say:Float = Math.sin(ay);
		var caz:Float = Math.cos(az);
		var saz:Float = Math.sin(az);

		retval[0][0] = cay * caz;
		retval[0][1] = -cay * saz;
		retval[0][2] = say;
		retval[1][0] = sax * say * caz + cax * saz;
		retval[1][1] = -sax * say * saz + cax * caz;
		retval[1][2] = -sax * cay;
		retval[2][0] = -cax * say * caz + sax * saz;
		retval[2][1] = cax * say * saz + sax * caz;
		retval[2][2] = cax * cay;

		return retval;
	}

	public static function normalize(v:Vector<Float>):Vector<Float>
	{
		var l:Float = ShaderUtils.lengths(v);
		var r:Vector<Float> = new Vector<Float>(v.length);
		var i:Int = 0;
		for (vv in v)
		{
			r[i++] = vv / l;
		}
		return r;
	}

	public static function lengths(v:Vector<Float>):Float
	{
		var s:Float = 0;
		for (vv in v)
		{
			s += vv * vv;
		}
		return Math.sqrt(s);
	}

	//public static ByteBuffer getImageDataFromImage(BufferedImage bufferedImage) {
		//WritableRaster wr;
		//DataBuffer db;
//
		//BufferedImage bi = new BufferedImage(128, 64, BufferedImage.TYPE_INT_ARGB);
		//Graphics2D g = bi.createGraphics();
		//g.drawImage(bufferedImage, null, null);
		//bufferedImage = bi;
		//wr = bi.getRaster();
		//db = wr.getDataBuffer();
//
		//DataBufferInt dbi = (DataBufferInt) db;
		//int[] data = dbi.getData();
//
		//ByteBuffer byteBuffer = ByteBuffer.allocateDirect(data.length * 4);
		//byteBuffer.order(ByteOrder.LITTLE_ENDIAN);
		//byteBuffer.asIntBuffer().put(data);
		//byteBuffer.flip();
//
		//return byteBuffer;
	//}

	public static function frac(f:Float):Float 
	{
		return f - ShaderUtils.floor(f);
	}

	public static function floors(fs:Vector<Float>):Vector<Float>
	{
		var retval:Vector<Float> = new Vector<Float>(fs.length);
		for (i in 0...fs.length) 
		{
			retval[i] = ShaderUtils.floor(fs[i]);
		}
		return retval;
	}
}
