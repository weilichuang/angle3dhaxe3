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
package de.polygonal.core.es;

import de.polygonal.core.util.Assert.assert;

/**
	Entities communicate through messages.
	
	A message object stores the message content.
**/
@:build(de.polygonal.core.es.EntityMessageMacro.addMeta())
@:build(de.polygonal.core.macro.IntConsts.build([I, F, B, S, O, USED], true, false))
@:allow(de.polygonal.core.es.EntityMessageQue)
class EntityMessage
{
	/**
		Resolves the name of the given message `type`. Useful for debugging purposes.
	**/
	#if debug
	public static function name(type:Int):String
	{
		var meta = haxe.rtti.Meta.getType(EntityMessage);
		if (meta.names.length == 0) return 'unknown type ($type)';
		var names = meta.names[0];
		if (type < 0 || type > names.length - 1) return 'unknown type ($type)';
		return meta.names[0][type];
	}
	#end
	
	/**
		The total number of message types (application-wide).
	**/
	public static function countTotalMessages():Int
	{
		var meta = haxe.rtti.Meta.getType(EntityMessage);
		return Std.parseInt(meta.count[0]);
	}
	
	@:noCompletion var mInt:Int;
	@:noCompletion var mFloat:Float;
	@:noCompletion var mBool:Bool;
	@:noCompletion var mString:String;
	@:noCompletion var mObject:Dynamic;
	
	@:noCompletion var mBits:Int;
	
	/**
		Integer value. Only valid if hasInt() is true.
	**/
	public var i(get_i, set_i):Int;
	@:noCompletion inline function get_i():Int
	{
		assert(mBits & I > 0, "no int stored");
		
		return mInt;
	}
	@:noCompletion inline function set_i(value:Int):Int
	{
		assert(mBits & USED == 0);
		
		mBits |= I;
		mInt = value;
		return value;
	}
	
	/**
		Float value. Only valid if hasFloat() is true.
	**/
	public var f(get_f, set_f):Float;
	@:noCompletion inline function get_f():Float
	{
		assert(mBits & F > 0, "no float stored");
		
		return mFloat;
	}
	@:noCompletion inline function set_f(value:Float):Float
	{
		assert(mBits & USED == 0);
		
		mBits |= F;
		mFloat = value;
		return value;
	}
	
	/**
		Boolean value. Only valid if hasBool() is true.
	**/
	public var b(get_b, set_b):Bool;
	@:noCompletion inline function get_b():Bool
	{
		assert(mBits & B > 0, "no bool stored");
		
		return mBool;
	}
	@:noCompletion inline function set_b(value:Bool):Bool
	{
		assert(mBits & USED == 0);
		
		mBits |= B;
		mBool = value;
		return value;
	}
	
	/**
		String value. Only valid if hasString() is true.
	**/
	public var s(get_s, set_s):String;
	@:noCompletion inline function get_s():String
	{
		assert(mBits & S > 0, "no string stored");
		
		return mString;
	}
	@:noCompletion inline function set_s(value:String):String
	{
		assert(mBits & USED == 0);
		
		mBits |= S;
		mString = value;
		return value;
	}
	
	/**
		Dynamic value. Only valid if hasObject() == true.
	**/
	public var o(get_o, set_o):Dynamic;
	@:noCompletion inline function get_o():Dynamic
	{
		assert(mBits & O > 0, "no object stored");
		
		return mObject;
	}
	
	@:noCompletion inline function set_o(value:Dynamic):Dynamic
	{
		assert(mBits & USED == 0);
		
		mBits |= O;
		mObject = value;
		return value;
	}
	
	/**
		True if the message stores an integer value.
	**/
	inline public function hasInt() return mBits & I > 0;
	
	/**
		True if the message stores a float value.
	**/
	inline public function hasFloat() return mBits & F > 0;
	
	/**
		True if the message stores an integer value.
	**/
	inline public function hasBool() return mBits & B > 0;
	
	/**
		True if the message stores a string value.
	**/
	inline public function hasString() return mBits & S > 0;
	
	/**
		Trhe if the message stores an object.
	**/
	inline public function hasObject() return mBits & O > 0;
	
	function new() {}
	
	@:noCompletion function toString():String
	{
		var a = [];
		if (mBits & I > 0) a.push('i=$mInt');
		if (mBits & F > 0) a.push('f=$mFloat');
		if (mBits & B > 0) a.push('b=$mBool');
		if (mBits & S > 0) a.push('s=$mString');
		if (mBits & O > 0) a.push('o=$mObject');
		if (a.length > 0) return '{ EntityMessage a.join(", ") }';
		
		return "{ EntityMessage }";
	}
}