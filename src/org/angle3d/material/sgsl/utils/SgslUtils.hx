package org.angle3d.material.sgsl.utils;
import org.angle3d.manager.ShaderManager;
import org.angle3d.material.sgsl.node.FunctionCallNode;

class SgslUtils
{
	private static var TEPM_VAR_COUNT:Int = 0;

	public static inline function getTempName(name:String):String
	{
		return name + (TEPM_VAR_COUNT++);
	}
	
	/**
	 * 是否是自定义函数调用
	 */
	public static inline function isCustomFunctionCall(node:FunctionCallNode):Bool
	{
		return node != null && !ShaderManager.instance.isNativeFunction(node.name);
	}
}