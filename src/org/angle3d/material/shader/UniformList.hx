package org.angle3d.material.shader;

import flash.Vector;

class UniformList extends ShaderVariableList
{
	public var bindList:Vector<Uniform>;
	
	private var _constants:Vector<Float>;

	public function new()
	{
		super();
		
		_constants = new Vector<Float>();
		
		bindList = new Vector<Uniform>();
	}

	public function setConstants(value:Vector<Float>):Void
	{
		_constants = value;
	}

	public function getConstants():Vector<Float>
	{
		return _constants;
	}

	public function getUniforms():Vector<ShaderVariable>
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
		var offset:Int = _constants != null ? Std.int(_constants.length / 4) : 0;
		var vLength:Int = _variables.length;
		for (i in 0...vLength)
		{
			var sv:Uniform = cast(_variables[i], Uniform);
			if (sv.binding != null)
			{
				bindList.push(sv);
			}
			sv.location = offset;
			offset+= sv.size;
		}
	}
}

