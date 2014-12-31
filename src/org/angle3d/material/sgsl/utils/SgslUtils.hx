package org.angle3d.material.sgsl.utils;
import haxe.ds.StringMap;
import org.angle3d.manager.ShaderManager;
import org.angle3d.material.sgsl.node.FunctionNode;

class SgslUtils
{
	public static var TEPM_VAR_COUNT:Int = 0;

	public static function getTempName(name:String):String
	{
		return name + (TEPM_VAR_COUNT++);
	}
}