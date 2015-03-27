package org.angle3d.material.shader;

import flash.Vector;

class UniformList extends ShaderParamList
{
	public var bindList:Vector<Uniform>;
	
	public var numbers:Vector<Float>;
	
	public var numberSize:Int;
	
	public var needUploadNumber:Bool;

	public function new()
	{
		super();
		
		bindList = new Vector<Uniform>();
	}

	public function getUniforms():Vector<ShaderParam>
	{
		return params;
	}

	public inline function getUniformAt(i:Int):Uniform
	{
		return cast params[i];
	}

	/**
	 * 需要偏移常数数组的长度
	 */
	override public function updateLocations():Void
	{
		var offset:Int = numbers != null ? Std.int(numbers.length / 4) : 0;
		var vLength:Int = params.length;
		for (i in 0...vLength)
		{
			var sv:Uniform = cast params[i];
			if (sv.binding != null)
			{
				bindList.push(sv);
			}
			sv.location = offset;
			offset += sv.size;
		}
		
		needUploadNumber = numbers != null && numbers.length > 0;
		
		numberSize = numbers == null ? 0 : Math.ceil(numbers.length / 4);
	}
}

