package org.angle3d.material.shader;

class ShaderParam
{
	public var name:String;

	public var location:Int;

	public var size:Int;

	public inline function new(name:String, size:Int)
	{
		this.name = name;
		this.size = size;
		location = -1;
	}
}

