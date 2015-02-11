package org.angle3d.material.shader;
import flash.Vector;
import haxe.ds.StringMap;
import org.angle3d.material.MatParam;
import org.angle3d.material.TechniqueDef;

class DefineList
{
	private var compiled:Bool = false;
	private var defines:StringMap<String>;
	private var defineList:Vector<String>;

	public function new() 
	{
		defines = new StringMap<String>();
		defineList = new Vector<String>();
	}
	
	public function clear():Void
	{
		compiled = false;
		defines = new StringMap<String>();
		defineList = new Vector<String>();
	}
	
	public function get(key:String):Null<String>
	{
		return defines.get(key);
	}
	
	public function set(key:String, varType:String, value:Dynamic):Bool
	{
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
		var otherDefines:StringMap<String> = other.defines;
		for (key in otherDefines.keys())
		{
			defines.set(key, otherDefines.get(key));
		}
	}
	
	public function getDefines():Vector<String>
	{
		if (!compiled)
		{
			defineList = new Vector<String>();
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
	public function update(params:StringMap<MatParam>, def:TechniqueDef):Bool
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
	
	private function equalsParams(params:StringMap<MatParam>, def:TechniqueDef):Bool
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