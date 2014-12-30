package org.angle3d.material.sgsl.utils;
import haxe.ds.StringMap;
import org.angle3d.manager.ShaderManager;
import org.angle3d.material.sgsl.node.FunctionNode;

/**
 * ...
 * @author weilichuang
 */
class SgslUtils
{
	public static var TEPM_VAR_COUNT:Int = 0;

	public static function getTempName(name:String):String
	{
		return name + (TEPM_VAR_COUNT++);
	}
	
	public static function getFunctionDataType(funcName:String, paramTypes:Array<String>, customMap:StringMap<FunctionNode>):String
	{
		if (ShaderManager.instance.isNativeFunction(funcName))
		{
			return ShaderManager.instance.getNativeFunctionDataType(funcName);
		}
		
		var result:String = funcName;
		if (paramTypes.length > 0)
		{
			for (i in 0...paramTypes.length)
			{
				result += "_" + paramTypes[i];
			}
		}
		
		var node:FunctionNode = customMap.get(result);
		if (node != null)
			return node.dataType;
		
		return null;
	}
}