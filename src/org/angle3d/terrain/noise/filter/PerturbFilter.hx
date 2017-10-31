package org.angle3d.terrain.noise.filter ;


import org.angle3d.terrain.noise.ShaderUtils;
import org.angle3d.terrain.noise.fractal.FractalSum;
import org.angle3d.utils.Logger;

class PerturbFilter extends AbstractFilter 
{

	private var magnitude:Float;

	override public function getMargin(size:Int, margin:Int):Int
	{
		margin = super.getMargin(size, margin);
		return Math.floor(this.magnitude * (margin + size) + margin);
	}

	public function setMagnitude(magnitude:Float):Void
	{
		this.magnitude = magnitude;
	}

	public function getMagnitude():Float
	{
		return this.magnitude;
	}

	override public function filter(sx:Float, sy:Float, base:Float, data:Vector<Float>, workSize:Int):Vector<Float>
	{
		
		var arr:Vector<Float> = data;
		var origSize:Int = Math.ceil(workSize / (2 * this.magnitude + 1));
		var offset:Int = Std.int((workSize - origSize) / 2);
		
		Logger.log("Found origSize : " + origSize + " and offset: " + offset + " for workSize : " + workSize + " and magnitude : "
						+ this.magnitude);
						
		var retval:Vector<Float> = new Vector<Float>(workSize * workSize);
		var perturbx:Vector<Float> = new FractalSum().setOctaves(8).setScale(5).getBuffer(sx, sy, base, workSize);
		var perturby:Vector<Float> = new FractalSum().setOctaves(8).setScale(5).getBuffer(sx, sy, base + 1, workSize);
		for (y in 0...workSize)
		{
			for (x in 0...workSize) 
			{
				// Perturb our coordinates
				var noisex:Float = perturbx[y * workSize + x];
				var noisey:Float = perturby[y * workSize + x];

				var px:Int = Std.int(origSize * noisex * this.magnitude);
				var py:Int = Std.int(origSize * noisey * this.magnitude);

				var c00:Float = arr[this.wrap(y - py, workSize) * workSize + this.wrap(x - px, workSize)];
				var c01:Float = arr[this.wrap(y - py, workSize) * workSize + this.wrap(x + px, workSize)];
				var c10:Float = arr[this.wrap(y + py, workSize) * workSize + this.wrap(x - px, workSize)];
				var c11:Float = arr[this.wrap(y + py, workSize) * workSize + this.wrap(x + px, workSize)];

				var c0:Float = ShaderUtils.mix(c00, c01, noisex);
				var c1:Float = ShaderUtils.mix(c10, c11, noisex);
				retval[y * workSize + x] = ShaderUtils.mix(c0, c1, noisey);
			}
		}
		return retval;
	}

	private function wrap(v:Int, size:Int):Int
	{
		if (v < 0) {
			return v + size - 1;
		} else if (v >= size) {
			return v - size;
		} else {
			return v;
		}
	}
}
