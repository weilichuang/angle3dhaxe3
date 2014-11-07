package org.angle3d.terrain.noise.filter ;

import flash.Vector;
import org.angle3d.terrain.noise.Filter;

class AbstractFilter implements Filter 
{
	private var preFilters:Array<Filter> = new Array<Filter>();
	private var postFilters:Array<Filter> = new Array<Filter>();

	private var enabled:Bool = true;

	public function addPreFilter(filter:Filter):Filter
	{
		this.preFilters.push(filter);
		return this;
	}

	public function addPostFilter(filter:Filter):Filter
	{
		this.postFilters.push(filter);
		return this;
	}

	public function doFilter(sx:Float, sy:Float, base:Float, data:Vector<Float>, size:Int):Vector<Float>
	{
		if (!this.isEnabled())
		{
			return data;
		}
		var retval:Vector<Float> = data;
		for ( f in this.preFilters)
		{
			retval = f.doFilter(sx, sy, base, retval, size);
		}
		retval = this.filter(sx, sy, base, retval, size);
		for (f in this.postFilters)
		{
			retval = f.doFilter(sx, sy, base, retval, size);
		}
		return retval;
	}

	public function filter(sx:Float, sy:Float, base:Float, data:Vector<Float>, size:Int):Vector<Float>
	{
		return null;
	}

	public function getMargin(size:Int, margin:Int):Int
	{
		// TODO sums up all the margins from filters... maybe there's a more
		// efficient algorithm
		if (!this.isEnabled())
		{
			return margin;
		}
		for (f in this.preFilters)
		{
			margin = f.getMargin(size, margin);
		}
		for (f in this.postFilters)
		{
			margin = f.getMargin(size, margin);
		}
		return margin;
	}

	public function isEnabled():Bool
	{
		return this.enabled;
	}

	public function setEnabled(enabled:Bool):Void 
	{
		this.enabled = enabled;
	}

}
