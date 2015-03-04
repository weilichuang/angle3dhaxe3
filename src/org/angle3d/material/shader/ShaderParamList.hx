package org.angle3d.material.shader;

import flash.Vector;

class ShaderParamList
{
	public var params:Vector<ShaderParam>;

	public function new()
	{
		params = new Vector<ShaderParam>();
	}

	public function addParam(value:ShaderParam):Void
	{
		params.push(value);
	}

	/**
	 * 添加所有变量后，设置每个变量的位置
	 */
	public function updateLocations():Void
	{
		//默认是按照在数组中的顺序来设置location
		var length:Int = params.length;
		for (i in 0...length)
		{
			params[i].location = i;
		}
	}

	public inline function getParamAt(index:Int):ShaderParam
	{
		return params[index];
	}

	public function getParam(name:String):ShaderParam
	{
		for (param in params)
		{
			if (param.name == name)
			{
				return param;
			}
		}
		return null;
	}
}

