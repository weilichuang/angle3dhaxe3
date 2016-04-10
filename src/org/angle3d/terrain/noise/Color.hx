package org.angle3d.terrain.noise ;
import flash.Vector;

/**
 * Helper class for working with colors and gradients
 * 

 * 
 */
class Color 
{
	private var rgba:Vector<Float> = new Vector<Float>(4);

	public function new(r:Float = 0, g:Float = 0, b:Float = 0, a:Float = 1)
	{
		this.rgba[0] = ShaderUtils.clamp(r, 0, 1);
		this.rgba[1] = ShaderUtils.clamp(g, 0, 1);
		this.rgba[2] = ShaderUtils.clamp(b, 0, 1);
		this.rgba[3] = ShaderUtils.clamp(a, 0, 1);
	}

	public function fromHSB(h:Int, s:Float, b:Float, a:Float = 1):Void
	{
		this.rgba[3] = a;
		if (s == 0) 
		{
			// achromatic ( grey )
			this.rgba[0] = b;
			this.rgba[1] = b;
			this.rgba[2] = b;
			return;
		}

		var hh:Float = h / 60.0;
		var i:Int = ShaderUtils.floor(hh);
		var f:Float = hh - i;
		var p:Float = b * (1 - s);
		var q:Float = b * (1 - s * f);
		var t:Float = b * (1 - s * (1 - f));

		if (i == 0)
		{
			this.rgba[0] = b;
			this.rgba[1] = t;
			this.rgba[2] = p;
		} 
		else if (i == 1) 
		{
			this.rgba[0] = q;
			this.rgba[1] = b;
			this.rgba[2] = p;
		} 
		else if (i == 2)
		{
			this.rgba[0] = p;
			this.rgba[1] = b;
			this.rgba[2] = t;
		} 
		else if (i == 3)
		{
			this.rgba[0] = p;
			this.rgba[1] = q;
			this.rgba[2] = b;
		} 
		else if (i == 4)
		{
			this.rgba[0] = t;
			this.rgba[1] = p;
			this.rgba[2] = b;
		}
		else 
		{
			this.rgba[0] = b;
			this.rgba[1] = p;
			this.rgba[2] = q;
		}
	}
	
	public function toInteger():Int
	{
		return Std.int(this.rgba[3] * 256) << 24 | 
			   Std.int(this.rgba[0] * 256) << 16 | 
			   Std.int(this.rgba[1] * 256) << 8 | 
			   Std.int(this.rgba[2] * 256);
	}

	public function toGrayscale():Color 
	{
		var v:Float = (this.rgba[0] + this.rgba[1] + this.rgba[2]) / 3;
		return new Color(v, v, v, this.rgba[3]);
	}

	public function toSepia():Color 
	{
		var r:Float = ShaderUtils.clamp(this.rgba[0] * 0.393 + this.rgba[1] * 0.769 + this.rgba[2] * 0.189, 0, 1);
		var g:Float = ShaderUtils.clamp(this.rgba[0] * 0.349 + this.rgba[1] * 0.686 + this.rgba[2] * 0.168, 0, 1);
		var b:Float = ShaderUtils.clamp(this.rgba[0] * 0.272 + this.rgba[1] * 0.534 + this.rgba[2] * 0.131, 0, 1);
		return new Color(r, g, b, this.rgba[3]);
	}
}
