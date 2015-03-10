package org.angle3d.material.shader;
import flash.Vector;
import haxe.ds.UnsafeStringMap;
import org.angle3d.material.MatParam;
import org.angle3d.material.TechniqueDef;
import org.angle3d.utils.Cloneable;
import org.angle3d.utils.MapUtil;

class DefineList implements Cloneable
{
	private var compiled:Bool = false;
	private var defines:UnsafeStringMap<String>;
	private var defineList:Array<String>;

	public function new() 
	{
		defines = new UnsafeStringMap<String>();
		defineList = new Array<String>();
	}
	
	public function clone():DefineList
	{
		var result:DefineList = new DefineList();
		
		result.compiled = false;
		var otherDefines:UnsafeStringMap<String> = this.defines;
		for (key in otherDefines.keys())
		{
			result.defines.set(key, otherDefines.get(key));
		}
		
		return result;
	}
	
	public function equals(other:DefineList):Bool
	{
		if (MapUtil.getSize(this.defines) != MapUtil.getSize(other.defines))
		{
			return false;
		}
		
		for (key in defines.keys())
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
		defines = new UnsafeStringMap<String>();
		defineList = new Array<String>();
	}
	
	public function get(key:String):Null<String>
	{
		return defines.get(key);
	}
	
	public function set(key:String, varType:String, value:Dynamic):Bool
	{
		if (varType == VarType.FLOAT || varType == VarType.INT)
		{
			if (Math.isNaN(value))
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
				if (cast(value, Bool))
				{
					if (defines.get(key) != "1")
					{
						defines.set(key, "1");
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
			case VarType.FLOAT:
				var newValue:String = Std.string(value);
				var original:String = defines.get(key);
				if (newValue != original)
				{
					defines.set(key, newValue);
					compiled = false;
					return true;
				}
			case VarType.INT:
				var newValue:String = Std.string(value);
				var original:String = defines.get(key);
				if (newValue != original)
				{
					defines.set(key, newValue);
					compiled = false;
					return true;
				}
			default:
				if (defines.get(key) != "1")
				{
					defines.set(key, "1");
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
		var otherDefines:UnsafeStringMap<String> = other.defines;
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
	public function update(params:UnsafeStringMap<MatParam>, def:TechniqueDef):Bool
	{
		if (equalsParams(params, def))
		{
			return false;
		}
		
		// Defines were changed, update define list
		clear();
		for (param in params)
		{
			var defineName:String = def.getShaderParamDefine(param.name);
			if (defineName != null)
			{
				set(defineName, param.type, param.value);
			}
		}
		return true;
	}
	
	private function equalsParams(params:UnsafeStringMap<MatParam>, def:TechniqueDef):Bool
	{
		var size:Int = 0;
		for (param in params)
		{
			var key:String = def.getShaderParamDefine(param.name);
			if (key != null)
			{
				var value:Dynamic = param.value;
				if (value != null)
				{
					switch(param.type)
					{
						case VarType.BOOL:
							var current:String = defines.get(key);
							if (cast(value, Bool))
							{
								if (current == null || current != "1")
								{
									return false;
								}
								size++;
							}
							else
							{
								if (current != null)
								{
									return false;
								}
							}
						case VarType.FLOAT:
							var newValue:String = Std.string(value);
							var current:String = defines.get(key);
							if (newValue != current)
							{
								return false;
							}
							size++;
						case VarType.INT:
							var newValue:String = Std.string(value);
							var current:String = defines.get(key);
							if (newValue != current)
							{
								return false;
							}
							size++;
						default:
							if (!defines.exists(key))
							{
								return false;
							}
							size++;
					}
				}
			}
		}
		
		if (size != defineList.length)
		{
			return false;
		}
		
		return true;
	}
}