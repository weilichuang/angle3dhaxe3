package org.angle3d.io.parser.ang;

/**
 * ...
 * @author 
 */
@:enum abstract AngFlag(Int)
{
	var UV = value(0);
	var COLOR = value(1);
	var NORMAL = value(2);
	var TANGENT = value(3);
	
	static inline function value(index:Int) return 1 << index;

	inline public function new(v:Int)
        this = v;

    inline public function toInt():Int
    	return this;
	
	inline public function remove(mask:AngFlag):AngFlag
	{
		return new AngFlag(this & ~mask.toInt());
	}
    
	inline public function add(mask:AngFlag):AngFlag
	{
		return new AngFlag(this | mask.toInt());
	}
    
	inline public function contains(mask:AngFlag):Bool
	{
		return this & mask.toInt() != 0;
	}
	
}