package org.angle3d.terrain.noise.fractal ;

import org.angle3d.terrain.noise.Basis;

/**
 * Interface for a general fractal basis.
 * 
 * Takes any number of basis funcions to work with and a few common parameters
 * for noise fractals
 * 

 * 
 */
interface Fractal extends Basis
{

	function setOctaves(octaves:Float):Fractal;

	function setFrequency(frequency:Float):Fractal;

	function setRoughness(roughness:Float):Fractal;

	function setAmplitude(amplitude:Float):Fractal;

	function setLacunarity(lacunarity:Float):Fractal;

	function addBasis(basis:Basis):Fractal;

}
