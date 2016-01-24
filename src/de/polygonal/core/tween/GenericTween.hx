/*
Copyright (c) 2012-2014 Michael Baczynski, http://www.polygonal.de

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
package de.polygonal.core.tween;

import de.polygonal.core.tween.ease.Ease;
import de.polygonal.ds.ArrayUtil;

using Reflect;

/**
	Supports tweening of any field of any object
**/
class GenericTween extends Tween implements TweenTarget
{
	var _object:Dynamic;
	var _fields:Array<String>;
	
	public function new(key:String = null, object:Dynamic, field:Dynamic, ease:Ease, to:Float, duration:Float, interpolateState = false)
	{
		_object = object;
		if (Std.is(field, String))
			_fields = cast [field];
		else
		if (Std.is(field, Array))
		{
			_fields = ArrayUtil.alloc(field.length);
			_fields = ArrayUtil.copy(field, _fields);
		}
		else
			throw "invalid/unsupported field";
		
		super(key, this, ease, to, duration, interpolateState);
	}
	
	override public function free()
	{
		super.free();
		_object = null;
		_fields = null;
	}
	
	public function set(x:Float)
	{
		for (field in _fields)
		{
			if (Reflect.hasField(_object, field))
				Reflect.setField(_object, field, x);
			else
				Reflect.setProperty(_object, field, x);
		}
	}
	
	public function get():Float
	{
		return
		if (Reflect.hasField(_object, _fields[0]))
			Reflect.field(_object, _fields[0]);
		else
			Reflect.getProperty(_object, _fields[0]);
	}
}