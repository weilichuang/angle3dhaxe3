package org.angle3d.terrain.noise.basis ;

import org.angle3d.terrain.noise.Basis;

/**
 * A simple aggregator basis. Takes two basis functions and a rate and return
 * some mixed values
 * 
 * @author Anthyon
 * 
 */
class NoiseAggregator extends Noise 
{

	private var rate:Float;
	private var a:Basis;
	private var b:Basis;

	public function new(a:Basis, b:Basis, rate:Float)
	{
		this.a = a;
		this.b = b;
		this.rate = rate;
	}

	override public function init():Void
	{
		this.a.init();
		this.b.init();
	}

	override public function value(x:Float, y:Float, z:Float):Float
	{
		return this.a.value(x, y, z) * (1 - this.rate) + this.rate * this.b.value(x, y, z);
	}

}
