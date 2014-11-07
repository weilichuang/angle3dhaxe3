package org.angle3d.terrain.noise.modulator ;

import flash.Vector;
import haxe.ds.IntMap;
import org.angle3d.terrain.noise.ShaderUtils;

class CatRom2 implements Modulator
{

	private var sampleRate:Int = 100;

	private var table:Vector<Float>;

	private static var instances:IntMap<CatRom2> = new IntMap<CatRom2>();

	public function new(sampleRate:Int)
	{
		this.sampleRate = sampleRate;
		this.table = new Vector<Float>(4 * sampleRate + 1);
		for (i in 0...(4 * sampleRate + 1))
		{
			var x:Float = i / sampleRate;
			x = Math.sqrt(x);
			if (x < 1)
			{
				this.table[i] = 0.5 * (2 + x * x * (-5 + x * 3));
			} 
			else
			{
				this.table[i] = 0.5 * (4 + x * (-8 + x * (5 - x)));
			}
		}
	}

	public static function getInstance(sampleRate:Int):CatRom2
	{
		if (!instances.exists(sampleRate))
		{
			instances.set(sampleRate, new CatRom2(sampleRate));
		}
		return instances.get(sampleRate);
	}

	public function value(ins:Array<Float>):Float
	{
		if (ins[0] >= 4)
		{
			return 0;
		}
		ins[0] = ins[0] * this.sampleRate + 0.5;
		var i:Int = ShaderUtils.floor(ins[0]);
		if (i >= 4 * this.sampleRate + 1) 
		{
			return 0;
		}
		return this.table[i];
	}
}
