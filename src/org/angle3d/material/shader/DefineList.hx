package org.angle3d.material.shader;
import org.angle3d.error.Assert;
import flash.Vector;
import org.angle3d.material.MatParam;
import org.angle3d.material.TechniqueDef;
import org.angle3d.material.VarType;
import org.angle3d.math.FastMath;
import org.angle3d.utils.Cloneable;
import org.angle3d.ds.FastStringMap;

/**
 * The new define list.
 * 
 */
class DefineList implements Cloneable
{
	public static inline var MAX_DEFINES:Int = 32;

	
	private var _hash:Int;
	private var _hashCode:Int;
	
	private var _numValues:Int;
	private var vals:Vector<Float>;
	
	public var hash(get, set):Int;
	
	public function new(numValues:Int) 
	{
		#if debug
		Assert.assert(numValues >= 0 && numValues <= MAX_DEFINES,'numValues must be between 0 and $MAX_DEFINES');
		#end
	 
		_numValues = numValues;
		vals = new Vector<Float>(_numValues, true);
	}
	
	public function copyFrom(other:DefineList):Void
	{
		this.hash = other.hash;
		
		this.vals.fixed = false;
		this.vals.length = other._numValues;
		this.vals.fixed = true;
		for (i in 0...other.vals.length)
		{
			this.vals[i] = other.vals[i];
		}
	}
	
	public function clone():DefineList
	{
		var result:DefineList = new DefineList(_numValues);
		result.copyFrom(this);
		return result;
	}
	
	public inline function hashCode():Int
	{
        return _hashCode;
    }
	
	private inline function get_hash():Int
	{
		return this._hash;
	}
	
	private inline function set_hash(value:Int):Int
	{
		this._hash = value;
		computeHashCode();
		return this._hash;
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
			set(i, other.vals[i]);
        }
	}
	
	public inline function clear():Void
	{
		hash = 0;
		vals.fixed = false;
		vals.length = 0;
		vals.length = _numValues;
		vals.fixed = true;
	}
	
	public inline function getBoolean(id:Int):Bool
	{
		return vals[id] != 0;
	}
	
	public inline function getFloat(id:Int):Float
	{
		return vals[id];
	}
	
	public inline function getInt(id:Int):Int
	{
		return Std.int(vals[id]);
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
			}
			return true;
		}
		return false;
	}
	
	public function generateSource(defineNames:Vector<String>, defineTypes:Vector<VarType>):String
	{
		var result:String = "";
		for (i in 0...vals.length)
		{
			if (vals[i] != 0 && !Math.isNaN(vals[i]))
			{
				var name:String = defineNames[i];
				result += "#define " + name + " " + vals[i] + "\n";
			}
		}
		return result;
	}
}