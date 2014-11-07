package org.angle3d.terrain.noise.filter ;

import flash.Vector;
import org.angle3d.terrain.noise.Filter;

class IterativeFilter extends AbstractFilter 
{

	private var iterations:Int;

	private var preIterateFilters:Array<Filter> = new Array<Filter>();
	private var postIterateFilters:Array<Filter> = new Array<Filter>();
	private var _filter:Filter;

	override public function getMargin(size:Int, margin:Int):Int
	{
		if (!this.isEnabled())
		{
			return margin;
		}
		for (f in this.preIterateFilters)
		{
			margin = f.getMargin(size, margin);
		}
		margin = this._filter.getMargin(size, margin);
		for (f in this.postIterateFilters)
		{
			margin = f.getMargin(size, margin);
		}
		return this.iterations * margin + super.getMargin(size, margin);
	}

	public function setIterations( iterations:Int):Void
	{
		this.iterations = iterations;
	}

	public function getIterations():Int
	{
		return this.iterations;
	}

	public function addPostIterateFilter( filter:Filter):IterativeFilter
	{
		this.postIterateFilters.push(filter);
		return this;
	}

	public function addPreIterateFilter( filter:Filter):IterativeFilter 
	{
		this.preIterateFilters.push(filter);
		return this;
	}

	public function setFilter( filter:Filter):Void
	{
		this._filter = filter;
	}

	override public function filter(sx:Float, sy:Float, base:Float, buffer:Vector<Float>, size:Int):Vector<Float>
	{
		if (!this.isEnabled()) 
		{
			return buffer;
		}
		
		var retval:Vector<Float> = buffer;

		for (i in 0...this.iterations)
		{
			for (f in this.preIterateFilters)
			{
				retval = f.doFilter(sx, sy, base, retval, size);
			}
			retval = this._filter.doFilter(sx, sy, base, retval, size);
			for (f in this.postIterateFilters) 
			{
				retval = f.doFilter(sx, sy, base, retval, size);
			}
		}

		return retval;
	}
}
