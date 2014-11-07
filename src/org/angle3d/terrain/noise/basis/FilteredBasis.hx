package org.angle3d.terrain.noise.basis ;

import flash.Vector;
import org.angle3d.terrain.noise.Basis;
import org.angle3d.terrain.noise.filter.AbstractFilter;
import org.angle3d.terrain.noise.modulator.Modulator;

class FilteredBasis extends AbstractFilter implements Basis 
{

	private var basis:Basis;
	private var modulators:Array<Modulator> = new Array<Modulator>();
	private var scale:Float;

	public function new(basis:Basis)
	{
		this.basis = basis;
	}

	public function getBasis():Basis
	{
		return this.basis;
	}

	public function setBasis(basis:Basis):Void
	{
		this.basis = basis;
	}

	override public function filter(fsx:Float, sy:Float, base:Float, data:Vector<Float>, size:Int):Vector<Float>
	{
		return data;
	}

	public function init():Void
	{
		this.basis.init();
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

	public function addModulator(modulator:Modulator):Basis
	{
		this.modulators.push(modulator);
		return this;
	}

	public function value(x:Float,y:Float,z:Float):Float
	{
		throw "Method value cannot be called on FilteredBasis and its descendants. Use getBuffer instead!";
	}

	public function getBuffer(sx:Float, sy:Float, base:Float, size:Int):Vector<Float>
	{
		var margin:Int = this.getMargin(size, 0);
		var workSize:Int = size + 2 * margin;
		var retval:Vector<Float> = this.basis.getBuffer(sx - margin, sy - margin, base, workSize);
		return this.clip(this.doFilter(sx, sy, base, retval, workSize), workSize, size, margin);
	}

	public function clip(buf:Vector<Float>, origSize:Int, newSize:Int, offset:Int):Vector<Float>
	{
		var result:Vector<Float> = new Vector<Float>(newSize * newSize);
		
		var orig:Vector<Float> = buf;

		var index:Int = 0;
		for (i in offset...(offset + newSize))
		{
			result[index++] = orig[i];
			result[index++] = i * origSize + offset;
			result[index++] = newSize;
		}

		return result;
	}
}
