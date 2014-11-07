package org.angle3d.terrain.noise.filter ;
import flash.Vector;

class OptimizedErode extends AbstractFilter 
{

	private var talus:Float;
	private var radius:Int;

	public function setRadius(radius:Int):OptimizedErode
	{
		this.radius = radius;
		return this;
	}

	public function getRadius():Int
	{
		return this.radius;
	}

	public function setTalus(talus:Float):OptimizedErode 
	{
		this.talus = talus;
		return this;
	}

	public function getTalus():Float
	{
		return this.talus;
	}

	override public function getMargin(size:Int, margin:Int):Int
	{
		return super.getMargin(size, margin) + this.radius;
	}

	override public function filter(sx:Float, sy:Float, base:Float, buffer:Vector<Float>, size:Int):Vector<Float>
	{
		var tmp:Vector<Float> = buffer;
		var retval:Vector<Float> = new Vector<Float>(tmp.length);

		for (y in (this.radius + 1)...(size - this.radius))
		{
			for (x in (this.radius + 1)...(size - this.radius))
			{
				var idx:Int = y * size + x;
				var h:Float = tmp[idx];

				var horizAvg:Float = 0;
				var horizCount:Int = 0;
				var vertAvg:Float = 0;
				var vertCount:Int = 0;

				var horizT:Bool = false;
				var vertT:Bool = false;

				var i:Int = 0;
				while (i >= -this.radius)
				{
					var idxV:Int = (y + i) * size + x;
					var idxVL:Int = (y + i - 1) * size + x;
					var idxH:Int = y * size + x + i;
					var idxHL:Int = y * size + x + i - 1;
					var hV:Float = tmp[idxV];
					var hH:Float = tmp[idxH];

					if (Math.abs(h - hV) > this.talus && Math.abs(h - tmp[idxVL]) > this.talus || vertT) 
					{
						vertT = true;
					}
					else 
					{
						if (Math.abs(h - hV) <= this.talus) 
						{
							vertAvg += hV;
							vertCount++;
						}
					}

					if (Math.abs(h - hH) > this.talus && Math.abs(h - tmp[idxHL]) > this.talus || horizT) 
					{
						horizT = true;
					}
					else 
					{
						if (Math.abs(h - hH) <= this.talus) 
						{
							horizAvg += hH;
							horizCount++;
						}
					}
					
					i--;
				}

				retval[idx] = 0.5 * (vertAvg / (vertCount > 0 ? vertCount : 1) + horizAvg / (horizCount > 0 ? horizCount : 1));
			}
		}
		return retval;
	}

}
