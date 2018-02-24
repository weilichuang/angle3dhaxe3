package angle3d.terrain.noise.filter ;


class SmoothFilter extends AbstractFilter 
{

	private var radius:Int;
	private var effect:Float;

	public function setRadius(radius:Int):Void
	{
		this.radius = radius;
	}

	public function getRadius():Int
	{
		return this.radius;
	}

	public function setEffect(effect:Float):Void
	{
		this.effect = effect;
	}

	public function getEffect():Float
	{
		return this.effect;
	}

	override public function getMargin(size:Int, margin:Int):Int
	{
		return super.getMargin(size, margin) + this.radius;
	}

	override public function filter(sx:Float, sy:Float, base:Float, buffer:Array<Float>, size:Int):Array<Float>
	{
		var data:Array<Float> = buffer;
		var retval:Array<Float> = new Array<Float>(data.length);
		
		for (y in this.radius...(size - this.radius))
		{
			for (x in this.radius...(size - this.radius))
			{
				var idx:Int = y * size + x;
				var n:Float = 0;
				for (i in (-this.radius)...(this.radius + 1))
				{
					for (j in ( -this.radius)...(this.radius + 1))
					{
						n += data[(y + i) * size + x + j];
					}
				}
				retval[idx] = this.effect * n / (4 * this.radius * (this.radius + 1) + 1) + (1 - this.effect) * data[idx];
			}
		}

		return retval;
	}
}
