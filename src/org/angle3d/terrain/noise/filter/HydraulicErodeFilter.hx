package org.angle3d.terrain.noise.filter ;


import org.angle3d.terrain.noise.Basis;

class HydraulicErodeFilter extends AbstractFilter 
{
	private var waterMap:Basis;
	private var sedimentMap:Basis;
	private var Kr:Float;
	private var Ks:Float;
	private var Ke:Float;
	private var Kc:Float;
	private var T:Float;

	public function setKc( kc:Float):Void 
	{
		this.Kc = kc;
	}

	public function setKe( ke:Float):Void
	{
		this.Ke = ke;
	}

	public function setKr( kr:Float):Void
	{
		this.Kr = kr;
	}

	public function setKs( ks:Float):Void
	{
		this.Ks = ks;
	}

	public function setSedimentMap( sedimentMap:Basis):Void
	{
		this.sedimentMap = sedimentMap;
	}

	public function setT( t:Float):Void
	{
		this.T = t;
	}

	public function setWaterMap(waterMap:Basis):Void
	{
		this.waterMap = waterMap;
	}

	override public function getMargin(size:Int, margin:Int):Int
	{
		return super.getMargin(size, margin) + 1;
	}

	override public function filter(sx:Float, sy:Float, base:Float, buffer:Vector<Float>, workSize:Int):Vector<Float>
	{
		var ga:Vector<Float> = buffer;
		// float[] wa = this.waterMap.getBuffer(sx, sy, base, workSize).array();
		// float[] sa = this.sedimentMap.getBuffer(sx, sy, base,
		// workSize).array();
		var wt:Vector<Float>  = new Vector<Float>(workSize * workSize);
		var st:Vector<Float>  = new Vector<Float>(workSize * workSize);

		var idxrel:Vector<Int> = Vector.ofArray([ -workSize - 1, -workSize + 1, workSize - 1, workSize + 1 ]);

		// step 1. water arrives and step 2. captures material
		for (y in 0...workSize)
		{
			for (x in 0...workSize)
			{
				var idx:Int = y * workSize + x;
				var wtemp:Float = this.Kr; // * wa[idx];
				var stemp:Float = this.Ks; // * sa[idx];
				if (wtemp > 0)
				{
					wt[idx] += wtemp;
					if (stemp > 0) 
					{
						ga[idx] -= stemp * wt[idx];
						st[idx] += stemp * wt[idx];
					}
				}

				// step 3. water is transported to it's neighbours
				var a:Float = ga[idx] + wt[idx];
				// float[] aj = new float[idxrel.length];
				var amax:Float = 0;
				var amaxidx:Int = -1;
				var ac:Float = 0;
				var dtotal:Float = 0;

				for (j in 0...idxrel.length)
				{
					if (idx + idxrel[j] > 0 && idx + idxrel[j] < workSize)
					{
						var at:Float = ga[idx + idxrel[j]] + wt[idx + idxrel[j]];
						if (a - at > a - amax)
						{
							dtotal += at;
							amax = at;
							amaxidx = j;
							ac++;
						}
					}
				}

				var aa:Float = (dtotal + a) / (ac + 1);
				// for (int j = 0; j < idxrel.length; j++) {
				// if (idx + idxrel[j] > 0 && idx + idxrel[j] < workSize && a -
				// aj[j] > 0) {
				if (amaxidx > -1)
				{
					var dwj:Float = Math.min(wt[idx], a - aa) * (a - amax) / dtotal;
					var dsj:Float = st[idx] * dwj / wt[idx];
					wt[idx] -= dwj;
					st[idx] -= dsj;
					wt[idx + idxrel[amaxidx]] += dwj;
					st[idx + idxrel[amaxidx]] += dsj;
				}
				// }

				// step 4. water evaporates and deposits material
				wt[idx] = wt[idx] * (1 - this.Ke);
				if (wt[idx] < this.T) 
				{
					wt[idx] = 0;
				}
				var smax:Float = this.Kc * wt[idx];
				if (st[idx] > smax)
				{
					ga[idx] += st[idx] - smax;
					st[idx] -= st[idx] - smax;
				}
			}
		}

		return buffer;
	}

}
