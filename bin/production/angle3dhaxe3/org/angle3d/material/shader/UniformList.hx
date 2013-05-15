package org.angle3d.material.shader;

import flash.Vector;

class UniformList extends ShaderVariableList
{
	private var _constants:Array<Array<Float>>;

	public function new()
	{
		super();
		_constants = new Array<Array<Float>>();
	}

	public function setConstants(value:Array<Array<Float>>):Void
	{
		_constants = value;
	}

	public function getConstants():Array<Array<Float>>
	{
		return _constants;
	}

	public function getUniforms():Array<ShaderVariable>
	{
		return _variables;
	}

	public function getUniformAt(i:Int):Uniform
	{
		return cast(_variables[i], Uniform);
	}

	/**
	 * 需要偏移常数数组的长度
	 */
	override public function build():Void
	{
		var offset:Int = _constants != null ? _constants.length : 0;
		var vLength:Int = _variables.length;
		for (i in 0...vLength)
		{
			var sv:ShaderVariable = _variables[i];
			sv.location = offset;
			offset+= sv.size;
		}
	}
}

