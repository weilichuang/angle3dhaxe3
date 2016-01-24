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
	A min-widths representation of a rectangle in 2-dimensional space,
	whose sides are parallel to the coordinate axes.
**/
class Recti
{
	/**
		The x coordinate of the top-left corner of the rectangle.
	**/
	public var x:Int;
	
	/**
		The y coordinate of the top-left corner of the rectangle.
	**/
	public var y:Int;
	
	/**
		The width of the rectangle.
	**/
	public var w:Int;
	
	/**
		The height of the rectangle.
	**/
	public var h:Int;
	
	/**
		The x coordinate of the bottom-right corner of the rectangle.
	**/
	public var r(get_r, never):Float;
	inline function get_r():Float return x + w;
	
	/**
		The y coordinate of the bottom-right corner of the rectangle.
	**/
	public var b(get_b, never):Float;
	inline function get_b():Float return y + h;
	
	public function new(x:Int = 0, y:Int = 0, w:Int = 0, h:Int = 0)
	{
		this.x = x;
		this.y = y;
		this.w = w;
		this.h = h;
	}
	
	inline public function of(other:Recti)
	{
		x = other.x;
		y = other.y;
		w = other.w;
		h = other.h;
	}
	
	inline public function equals(other:Recti):Bool
	{
		return x == other.x && y == other.y && w == other.w && h == other.h;
	}
	
	public function clone():Recti
	{
		return new Recti(x, y, w, h);
	}
	
	public function toString():String
	{
		return '{ Rect x=$x y=$y w=$w h=$h }';
	}
}