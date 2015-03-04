package org.angle3d.material.shader;

import flash.Vector;

class UniformList extends ShaderParamList
{
	public var bindList:Vector<Uniform>;
	
	public var constants:Vector<Float>;
	
	public var needUploadConstant:Bool;

	public function new()
	{
		super();
		
		bindList = new Vector<Uniform>();
	}

	public function getUniforms():Vector<ShaderParam>
	{
		return params;
	}

	public function getUniformAt(i:Int):Uniform
	{
		return cast params[i];
	}

	/**
	 * 需要偏移常数数组的长度
	 */
	override public function updateLocations():Void
	{
		var offset:Int = constants != null ? Std.int(constants.length / 4) : 0;
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
		
		needUploadConstant = constants != null && constants.length > 0;
	}
}

