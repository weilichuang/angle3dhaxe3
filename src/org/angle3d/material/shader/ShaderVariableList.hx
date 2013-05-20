package org.angle3d.material.shader;

import flash.Vector;
/**
 * ShaderVariable List
 * @author
 */
class ShaderVariableList
{
	private var _variables:Vector<ShaderVariable>;

	public function new()
	{
		_variables = new Vector<ShaderVariable>();
	}

	public function addVariable(value:ShaderVariable):Void
	{
		_variables.push(value);
	}

	/**
	 * read only
	 * @return
	 */
	public inline function getVariables():Vector<ShaderVariable>
	{
		return _variables;
	}

	/**
	 * 添加所有变量后，设置每个变量的位置
	 */
	public function build():Void
	{
		//默认是按照在数组中的顺序来设置location
		var vLength:Int = _variables.length;
		for (i in 0...vLength)
		{
			_variables[i].location = i;
		}
	}

	public inline function getVariableAt(index:Int):ShaderVariable
	{
		return _variables[index];
	}

	public function getVariable(name:String):ShaderVariable
	{
		var length:Int = _variables.length;
		for (i in 0...length)
		{
			if (_variables[i].name == name)
			{
				return _variables[i];
			}
		}
		return null;
	}
}

