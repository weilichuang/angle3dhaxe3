package org.angle3d.material.shader;
import de.polygonal.core.util.Assert;
import flash.Vector;
import org.angle3d.material.MatParam;
import org.angle3d.material.TechniqueDef;
import org.angle3d.material.VarType;
import org.angle3d.math.FastMath;
import org.angle3d.utils.Cloneable;
import org.angle3d.utils.FastStringMap;

/**
 * The new define list.
 * 
 */
class DefineList implements Cloneable
{
	public static inline var MAX_DEFINES:Int = 32;

	private var _hash:Int;
	private var _hashCode:Int;
	private var vals:Vector<Float>;
	
	public var hash(get, set):Int;
	
	public function new(numValues:Int) 
	{
		#if debug
		Assert.assert(numValues >= 0 && numValues <= MAX_DEFINES,"numValues must be between 0 and 64");
		#end
		
		vals = new Vector<Float>(numValues, true);
	}
	
	public inline function hashCode():Int
	{
        return _hashCode;
    }
	
	private inline function get_hash():Int
	{
		return this._hash;
	}
	
	private inline function set_hash(value:Int):Void
	{
		this._hash = vals;
		computeHashCode();
	}
	
	private inline function computeHashCode():Void
	{
		_hashCode = ((_hash >> 32) ^ _hash);
	}
	
	public function set(id:Int, value:Float):Void
	{
		#if debug
		Assert.assert(0 <= id && id < MAX_DEFINES);
		#end
		
        if (value != 0)
		{
            hash |= (1 << id);
        } 
		else 
		{
            hash &= ~(1 << id);
        }

        vals[id] = value;
	}
	
	public inline function setBool(id:Int, value:Bool):Void
	{
		set(id, value ? 1 : 0);
	}
	
	public inline function setDynamic(id:Int, type:VarType, value:Dynamic):Void
	{
		if (value == null)
		{
			set(id, 0);
			return;
		}
		
		switch(type)
		{
			case VarType.INT, VarType.FLOAT:
				set(id, cast value);
			case VarType.BOOL:
				setBool(id, cast value);
			default:
				set(id, 1);
		}
	}
	
	public function setAll(other:DefineList):Void
	{
		for (i in 0...other.vals.length)
		{
            if (other.vals[i] != 0)
			{
                vals[i] = other.vals[i];
            }
        }
	}
	
	public function clear():Void
	{
		hash = 0;
		for (i in 0...vals.length)
			vals[i] = 0;
	}
	
	public function getBoolean(id:Int):Bool
	{
		return vals[id] != 0;
	}
	
	public function getFloat(id:Int):Float
	{
		return vals[id];
	}
	
	public function getInt(id:Int):Int
	{
		return Std.int(vals[id]);
	}
	
	public function deepClone():DefineList
	{
		var list:DefineList = new DefineList(this.vals.length);
		for (i in 0...vals.length)
		{
			list.vals[i] = vals[i];
		}
		list.hash = this.hash;
		return list;
	}
	
	public function equals(other:DefineList):Bool
	{
		if (other.hash == this.hash)
		{
			for (i in 0...vals.length)
			{
				if (other.vals[i] != vals[i])
				{
					return false;
				}
				return true;
			}
		}
		else
		{
			return false;
		}
	}
	
	public function generateSource(defineNames:Vector<String>, defineTypes:Vector<VarType>):Void
	{
		var result:String = "";
		for (i in 0...vals.length)
		{
			if (vals[i] != 0)
			{
				var name:String = defineNames[i];
			}
		}
	}
}