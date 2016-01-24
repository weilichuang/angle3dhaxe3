/*
Copyright (c) 2014 Michael Baczynski, http://www.polygonal.de

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
package de.polygonal.core.math;

/**
	A 2d axis-aligned bounding box (AABB)
	
	- This is a rectangular four-sided box.
	- The face normals are parallel with the axes of the given coordinate system.
	- The class stores the minimum and maximum coordinate values along each axis (_min-max_ representation).
**/
class Aabb2
{
	/**
		Creates a box using a _min-widths_ representation.
		
		@param x the x coordinate of the top-left corner of the box.
		@param x the y coordinate of the top-left corner of the box.
		@param w the width of the box.
		@param h the height of the box.
	**/
	inline public static function ofMinWidths(x:Float, y:Float, w:Float, h:Float):Aabb2
	{
		return new Aabb2(x, y, x + w, y + h);
	}
	
	/**
		Creates a box using a _center-radius_ representation.
		
		@param cx the x coordinate of the center of the box.
		@param cy the y coordinate of the center of the box.
		@param rx the radius of the box along the x-axis (half width).
		@param ry the radius of the box along the y-axis (half height).
	**/
	inline public static function ofCenterRadius(cx:Float, cy:Float, rx:Float, ry:Float):Aabb2
	{
		return new Aabb2(cx - rx, cy - ry, cx + rx, cy + ry);
	}
	
	/**
		The x coordinate of the top-left corner of the box.
	**/
	public var minX:Float;
	
	/**
		The y coordinate of the top-left corner of the box.
	**/
	public var minY:Float;
	
	/**
		The x coordinate of the bottom-right corner of the box.
	**/
	public var maxX:Float;
	
	/**
		The y coordinate of the bottom-right corner of the box.
	**/
	public var maxY:Float;
	
	/**
		Creates a box using a min-max representation.
		
		If no arguments are specified this method constructs an empty box.
	**/
	public function new(minX:Float = 1, minY:Float = 1, maxX:Float = -1, maxY:Float = -1)
	{
		if (minX <= maxX && minY <= maxY)
		{
			this.minX = minX;
			this.minY = minY;
			this.maxX = maxX;
			this.maxY = maxY;
		}
		else
			empty();
	}
	
	/**
		Copies the values of `other` to this.
	**/
	inline public function of(other:Aabb2):Aabb2
	{
		minX = other.minX;
		minY = other.minY;
		maxX = other.maxX;
		maxY = other.maxY;
		return this;
	}
	
	/**
		Sets the min and max values.
		
		@param minX minimum position along the x-axis
		@param minY minimum position along the y-axis
		@param maxX maximum position along the x-axis
		@param maxY maximum position along the y-axis
	**/
	inline public function set(minX:Float, minY:Float, maxX:Float, maxY:Float):Aabb2
	{
		this.minX = minX;
		this.minY = minY;
		this.maxX = maxX;
		this.maxY = maxY;
		return this;
	}
	
	/**
		The x coordinate of the top-left corner of the box (_min_-widths representation).
		
		The value of `x` is equal to the value of `minX`.
		
		Changing this value has no effect on `w`, `rx`.
	**/
	public var x(get_x, set_x):Float;
	inline function get_x():Float
	{
		return minX;
	}
	inline function set_x(value:Float):Float
	{
		var t = w;
		minX = value;
		maxX = value + t;
		return value;
	}
	
	/**
		The y coordinate of the top-left corner of the box (_min_-widths representation).
		
		The value of `y` is equal to the value of `minY`.
		
		Changing this value has no effect on `h`, `ry`.
	**/
	public var y(get_y, set_y):Float;
	inline function get_y():Float
	{
		return minY;
	}
	inline function set_y(value:Float):Float
	{
		var t = h;
		minY = value;
		maxY = value + t;
		return value;
	}
	
	/**
		The width of the box (min-_widths_ representation).
		
		Changing this value has no effect on `minX`, `x`.
	**/
	public var w(get_w, set_w):Float;
	inline function get_w():Float
	{
		return maxX - minX;
	}
	inline function set_w(value:Float):Float
	{
		maxX = minX + value;
		return value;
	}
	
	/**
		The height of the box (min-_widths_ representation).
		
		Changing this value has no effect on `minY`, `y`.
	**/
	public var h(get_h, set_h):Float;
	inline function get_h():Float
	{
		return maxY - minY;
	}
	inline function set_h(value:Float):Float
	{
		maxY = minY + value;
		return value;
	}
	
	/**
		The x-coordinate of the center of the box (_center_-radius representation).
		
		Changing this value has no effect on `w`, `rx`.
	**/
	public var cx(get_cx, set_cx):Float;
	inline function get_cx():Float
	{
		return minX + w * 0.5;
	}
	inline function set_cx(value:Float):Float
	{
		var t = w * .5;
		minX = value - t;
		maxX = value + t;
		return value;
	}
	
	/**
		The y-coordinate of the center of the box (_center_-radius representation).
		
		Changing this value has no effect on `h`, `ry`.
	**/
	public var cy(get_cy, set_cy):Float;
	inline function get_cy():Float
	{
		return minY + h * 0.5;
	}
	inline function set_cy(value:Float):Float
	{
		var t = h * .5;
		minY = value - t;
		maxY = value + t;
		return value;
	}
	
	/**
		The radius of the box along the x-axis (center-_radius_ representation).
		
		Changing this value has no effect on `cx`.
	**/
	public var rx(get_rx, set_rx):Float;
	inline function get_rx():Float
	{
		return w * 0.5;
	}
	inline function set_rx(value:Float):Float
	{
		var t = cx;
		minX = t - value;
		minX = t + value;
		return value;
	}
	
	/**
		The radius of the box along the y-axis (center-_radius_ representation).
		
		Changing this value has no effect on `cy`.
	**/
	public var ry(get_ry, set_ry):Float;
	inline function get_ry():Float
	{
		return h * 0.5;
	}
	inline function set_ry(value:Float):Float
	{
		var t = cy;
		minY = t - value;
		minY = t + value;
		return value;
	}
	
	/**
		The value of `right` is equal to the value of `maxX`.
		
		Changing this value has no effect on `w`, `rx`.
	**/
	public var right(get_right, set_right):Float;
	inline function get_right():Float
	{
		return maxX;
	}
	inline function set_right(value:Float):Float
	{
		var t = w;
		maxX = value;
		minX = value - t;
		return value;
	}
	
	/**
		The value of `right` is equal to the value of `maxY`.
		
		Changing this value has no effect on `h`, `ry`.
	**/
	public var bottom(get_bottom, set_bottom):Float;
	inline function get_bottom():Float
	{
		return maxY;
	}
	inline function set_bottom(value:Float):Float
	{
		var t = h;
		maxY = value;
		minY = value - t;
		return value;
	}
	
	/**
		Marks the box as empty (min > max).
	**/
	inline public function empty()
	{
		minX = minY = Math.POSITIVE_INFINITY;
		maxX = maxY = Math.NEGATIVE_INFINITY;
	}
	
	/**
		True if the box is empty (min > max)
	**/
	inline public function isEmpty():Bool
	{
		return (minX > maxX) || (minY > maxY);
	}
	
	/**
		Adds the point (`x`,`y`) to the box by expanding it if necessary.
	**/
	inline public function addPoint(x:Float, y:Float)
	{
		if (x < minX) minX = x;
		if (x > maxX) maxX = x;
		if (y < minY) minY = y;
		if (y > maxY) maxY = y;
	}
	
	/**
		Adds the `other` to the box by expanding it if necessary.
	**/
	inline public function addAABB(other:Aabb2):Aabb2
	{
		if (other.minX < minX) minX = other.minX;
		if (other.minY < minY) minY = other.minY;
		if (other.maxX > maxX) maxX = other.maxX;
		if (other.maxY > maxY) maxY = other.maxY;
		return this;
	}
	
	/**
		Returns true if `other` is inside this box (includes a touching contact).
	**/
	inline public function contains(other:Aabb2):Bool
	{
		if (other.minX < minX) return false;
		else
		if (other.maxX > maxX) return false;
		else
		if (other.minY < minY) return false;
		else
		if (other.maxY > maxY) return false;
		else
			return true;
	}
	
	/**
		Increases the size of the box by `dx`, `dy`.
	**/
	inline public function inflate(dx:Float, dy:Float):Aabb2
	{
		minX -= dx;
		minY -= dy;
		maxX += dx;
		maxY += dy;
		return this;
	}
	
	public function clone():Aabb2
	{
		return new Aabb2(minX, minY, maxX, maxY);
	}
	
	public function toString():String
	{
		return de.polygonal.Printf.format('{ Aabb2 minX=%-.4f minY=%-.4f maxX=%-.4f maxY=%-.4f }', [minX, minY, maxX, maxY]);
	}
}