package org.angle3d.material.shader;
import org.angle3d.material.MatParam;
import org.angle3d.material.TechniqueDef;
import org.angle3d.math.FastMath;
import org.angle3d.utils.Cloneable;
import org.angle3d.utils.FastStringMap;

class DefineList implements Cloneable
{
	private var compiled:Bool = false;
	private var defines:FastStringMap<Float>;
	private var defineList:Array<String>;

	public function new() 
	{
		defines = new FastStringMap<Float>();
		defineList = new Array<String>();
	}
	
	public function clone():DefineList
	{
		var result:DefineList = new DefineList();
		result.compiled = false;
		
		var otherDefines:FastStringMap<Float> = this.defines;
		for (key in otherDefines.keys())
		{
			result.defines.set(key, otherDefines.get(key));
		}
		
		return result;
	}
	
	public function equals(other:DefineList):Bool
	{
		if (this.defines.size() != other.defines.size())
		{
			return false;
		}
		
		var keys = defines.keys();
		for (key in keys)
		{
			if (defines.get(key) != other.get(key))
			{
				return false;
			}
		}
		return true;
	}
	
	public function clear():Void
	{
		compiled = false;
		defines.clear();
		untyped defineList.length = 0;
	}
	
	public inline function get(key:String):Float
	{
		return defines.get(key);
	}
	
	public function set(key:String, varType:String, value:Dynamic):Bool
	{
		if (varType == VarType.FLOAT || varType == VarType.INT)
		{
			if (FastMath.isNaN(value))
			{
				compiled = false;
				defines.remove(key);
				return true;
			}
		}
		
		if (value == null)
		{
			compiled = false;
			defines.remove(key);
			return true;
		}
		
		switch(varType)
		{
			case VarType.BOOL:
				if (cast(value, Bool) == true)
				{
					if (defines.get(key) != 1)
					{
						defines.set(key, 1);
						compiled = false;
						return true;
					}
				}
				else if (defines.exists(key))
				{
					defines.remove(key);
					compiled = false;
					return true;
				}
			case VarType.FLOAT,VarType.INT:
				if (value != defines.get(key))
				{
					defines.set(key, value);
					compiled = false;
					return true;
				}
			default:
				if (defines.get(key) != 1)
				{
					defines.set(key, 1);
					compiled = false;
					return true;
				}	
		}
		
		return false;
	}
	
	public function remove(key:String):Bool
	{
		if (defines.remove(key))
		{
			compiled = false;
			return true;
		}
		return false;
	}
	
	public function addFrom(other:DefineList):Void
	{
		if (other == null)
			return;
			
		compiled = false;
		var otherDefines:FastStringMap<Float> = other.defines;
		for (key in otherDefines.keys())
		{
			defines.set(key, otherDefines.get(key));
		}
	}
	
	public function getDefines():Array<String>
	{
		if (!compiled)
		{
			defineList = new Array<String>();
			for (key in defines.keys())
			{
				defineList.push(key);
			}
			compiled = true;
		}
		return defineList;
	}
	
	/**
     * Update defines if the define list changed based on material parameters.
     * @param params
     * @param def
     * @return true if defines was updated
     */
	public function update(params:FastStringMap<MatParam>, def:TechniqueDef):Bool
	{
		if (equalsParams(params, def))
		{
			return false;
		}
		
		// Defines were changed, update define list
		clear();
		
		var keys = params.keys();
		for (paramName in keys)
		{
			var param:MatParam = params.get(paramName);
			var defineName:String = def.getShaderParamDefine(paramName);
			if (defineName != null)
			{
				set(defineName, param.type, param.value);
			}
		}
		return true;
	}
	
	private function equalsParams(params:FastStringMap<MatParam>, def:TechniqueDef):Bool
	{
		var size:Int = 0;
		
		var keys = params.keys();
		for (paramName in keys)
		{
			var param:MatParam = params.get(paramName);
			var key:String = def.getShaderParamDefine(paramName);
			if (key != null)
			{
				var value:Dynamic = param.value;
						
				switch(param.type)
				{
					case VarType.BOOL:
						if (!defines.exists(key))
						{
							if (value == true)
								return false;
						}
						else
						{
							if (defines.get(key) != (value ? 1 : 0))
							{
								return false;
							}
							size++;
						}
					case VarType.FLOAT, VarType.INT:
						if (!defines.exists(key))
						{
							if (!FastMath.isNaN(cast value))
								return false;
						}
						else 
						{
							if (value != defines.get(key))
							{
								return false;
							}
							size++;
						}
					default:
						if (!defines.exists(key))
						{
							return false;
						}
						size++;
				}
			}
		}
		
		if (size != defines.size())
		{
			return false;
		}
		
		return true;
	}
	
	public function toString():String
	{
		var result:String = "";
		for (key in defines.keys())
		{
			result += key + ":" + defines.get(key) + " ";
		}
		return result;
	}
}