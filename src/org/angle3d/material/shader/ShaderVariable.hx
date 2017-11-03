package org.angle3d.material.shader;
import js.html.webgl.UniformLocation;

class ShaderVariable
{
	public var name:String;

	public var location:UniformLocation;

	public var size:Int;

	public inline function new(name:String, size:Int)
	{
		this.name = name;
		this.size = size;
		location = null;
	}
}

