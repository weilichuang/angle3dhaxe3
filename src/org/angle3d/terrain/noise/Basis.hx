package org.angle3d.terrain.noise ;

import flash.Vector;
import org.angle3d.terrain.noise.basis.ImprovedNoise;
import org.angle3d.terrain.noise.modulator.Modulator;

/**
 * Interface for - basically 3D - noise generation algorithms, based on the
 * book: Texturing &amp; Modeling - A Procedural Approach
 * 
 * The main concept is to look at noise as a basis for generating fractals.
 * Basis can be anything, like a simple:
 * 
 * `
 * float value(float x, float y, float z) {
 * 		return 0; // a flat noise with 0 value everywhere
 * }
 * `
 * 
 * or a more complex perlin noise ({ImprovedNoise}
 * 
 * Fractals use these functions to generate a more complex result based on some
 * frequency, roughness, etc values.
 * 
 * Fractals themselves are implementing the Basis interface as well, opening
 * an infinite range of results.
 * 
 */
interface Basis 
{
	function init():Void;

	function setScale(scale:Float):Basis;

	function getScale():Float;

	function addModulator(modulator:Modulator):Basis;

	function value(x:Float, y:Float, z:Float):Float;

	function getBuffer(sx:Float, sy:Float, base:Float, size:Int):Vector<Float>;

}
