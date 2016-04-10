package org.angle3d.terrain.noise.fractal ;

import org.angle3d.terrain.noise.Basis;
import org.angle3d.terrain.noise.fractal.Fractal;
import org.angle3d.terrain.noise.basis.ImprovedNoise;
import org.angle3d.terrain.noise.basis.Noise;

/**
 * FractalSum is the simplest form of fractal functions summing up a few octaves
 * of the noise value with an ever decreasing (0 < roughness < 1) amplitude
 * 
 * lacunarity = 2.0f is the classical octave distance
 * 
 * Note: though noise basis functions are generally designed to return value
 * between -1..1, there sum can easily be made to extend out of this range. To
 * handle this is up to the user.
 * 

 * 
 */
class FractalSum extends Noise implements Fractal
{

	private var basis:Basis;
	private var lacunarity:Float;
	private var amplitude:Float;
	private var roughness:Float;
	private var frequency:Float;
	private var octaves:Float;
	private var maxFreq:Int;

	public function new()
	{
		this.basis = new ImprovedNoise();
		this.lacunarity = 2.124367;
		this.amplitude = 1.0;
		this.roughness = 0.6;
		this.frequency = 1;
		this.setOctaves(1);
	}

	override public function value(x:Float, y:Float, z:Float):Float
	{
		var total:Float = 0;

		var f:Float = this.frequency;
		var a:Float = this.amplitude;
		while (f < this.maxFreq)
		{
			total += this.basis.value(this.scale * x * f, this.scale * y * f, this.scale * z * f) * a;
			
			f *= this.lacunarity;
			a *= this.roughness;
		}

		return ShaderUtils.clamp(total, -1, 1);
	}

	public function addBasis(basis:Basis):Fractal
	{
		this.basis = basis;
		return this;
	}

	public function getOctaves():Float
	{
		return this.octaves;
	}

	public function setOctaves(octaves:Float):Fractal
	{
		this.octaves = octaves;
		this.maxFreq = 1 << Std.int(octaves);
		return this;
	}

	public function getFrequency():Float
	{
		return this.frequency;
	}

	public function setFrequency(frequency:Float):Fractal
	{
		this.frequency = frequency;
		return this;
	}

	public function getRoughness():Float
	{
		return this.roughness;
	}

	public function setRoughness(roughness:Float):Fractal
	{
		this.roughness = roughness;
		return this;
	}

	public function getAmplitude():Float
	{
		return this.amplitude;
	}

	public function setAmplitude(amplitude:Float):Fractal
	{
		this.amplitude = amplitude;
		return this;
	}

	public function getLacunarity():Float
	{
		return this.lacunarity;
	}

	public function setLacunarity(lacunarity:Float):Fractal
	{
		this.lacunarity = lacunarity;
		return this;
	}

}
