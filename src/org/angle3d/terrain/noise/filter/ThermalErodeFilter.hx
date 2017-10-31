package org.angle3d.terrain.noise.filter ;


class ThermalErodeFilter extends AbstractFilter
{

	private var talus:Float;
	private var c:Float;

	public function setC(c:Float):ThermalErodeFilter
	{
		this.c = c;
		return this;
	}

	public function setTalus(talus:Float):ThermalErodeFilter
	{
		this.talus = talus;
		return this;
	}

	override public function getMargin(size:Int, margin:Int):Int
	{
		return super.getMargin(size, margin) + 1;
	}

	override public function filter(sx:Float, sy:Float, base:Float, buffer:Vector<Float>, workSize:Int):Vector<Float>
	{
		var ga:Vector<Float> = buffer;
		var sa:Vector<Float> = new Vector<Float>(workSize * workSize);

		var idxrel:Array<Int> = [ -workSize - 1, -workSize + 1, workSize - 1, workSize + 1 ];

		for (y in 0...workSize)
		{
			for (x in 0...workSize)
			{
				var idx:Int = y * workSize + x;
				ga[idx] += sa[idx];
				sa[idx] = 0;

				var deltas:Vector<Float> = new Vector<Float>(idxrel.length);
				var deltaMax:Float = this.talus;
				var deltaTotal:Float = 0;

				for (j in 0...idxrel.length)
				{
					if (idx + idxrel[j] > 0 && idx + idxrel[j] < ga.length)
					{
						var dj:Float = ga[idx] - ga[idx + idxrel[j]];
						if (dj > this.talus)
						{
							deltas[j] = dj;
							deltaTotal += dj;
							if (dj > deltaMax)
							{
								deltaMax = dj;
							}
						}
					}
				}

				for (j in 0...idxrel.length)
				{
					if (deltas[j] != 0)
					{
						var d:Float = this.c * (deltaMax - this.talus) * deltas[j] / deltaTotal;
						if (d > ga[idx] + sa[idx])
						{
							d = ga[idx] + sa[idx];
						}
						sa[idx] -= d;
						sa[idx + idxrel[j]] += d;
					}
					deltas[j] = 0;
				}
			}
		}

		return buffer;
	}

}
