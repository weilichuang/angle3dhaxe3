package org.angle3d.terrain.noise.basis ;

import flash.Vector;
import org.angle3d.terrain.noise.Basis;
import org.angle3d.terrain.noise.modulator.Modulator;
import org.angle3d.terrain.noise.modulator.NoiseModulator;

/**
 * Utility base class for Noise implementations
 * 
 * @author Anthyon
 * 
 */
class Noise implements Basis 
{

	private var modulators:Array<Modulator> = new Array<Modulator>();

	private var scale:Float = 1.0;
	
	public function init():Void
	{
		
	}

	public function toString():String
	{
		return Std.string(this);
	}

	public function getBuffer(sx:Float, sy:Float, base:Float, size:Int):Vector<Float> 
	{
		var retval:Vector<Float> = new Vector<Float>(size * size);
		for (y in 0...size) 
		{
			for (x in 0...size) 
			{
				retval.push(this.modulate((sx + x) / size, (sy + y) / size, base));
			}
		}
		return retval;
	}

	public function modulate(x:Float, y:Float, z:Float):Float
	{
		var retval:Float = this.value(x, y, z);
		for (m in this.modulators) 
		{
			if (Std.is(m, NoiseModulator))
			{
				retval = m.value([retval]);
			}
		}
		return retval;
	}

	public function addModulator(modulator:Modulator):Basis
	{
		this.modulators.push(modulator);
		return this;
	}

	public function setScale(scale:Float):Basis
	{
		this.scale = scale;
		return this;
	}

	public function getScale():Float 
	{
		return this.scale;
	}
	
	public function value(x:Float, y:Float, z:Float):Float
	{
		return 0;
	}
}
