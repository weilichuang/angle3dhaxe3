package org.angle3d.material.shader;


import haxe.ds.StringMap;

class ShaderParamList
{
	public var params:Array<ShaderParam>;
	private var paramsMap:StringMap<ShaderParam>;

	public function new()
	{
		params = new Array<ShaderParam>();
		paramsMap = new StringMap<ShaderParam>();
	}

	public function addParam(value:ShaderParam):Void
	{
		params.push(value);
		paramsMap.set(value.name, value);
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

	public inline function getParam(name:String):ShaderParam
	{
		return paramsMap.get(name);
	}
}

