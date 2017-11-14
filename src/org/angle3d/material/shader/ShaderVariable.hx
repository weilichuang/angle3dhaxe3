package org.angle3d.material.shader;
import js.html.webgl.UniformLocation;

class ShaderVariable
{
	/**
     * Name of the uniform as was declared in the shader.
     * E.g name = "g_WorldMatrix" if the declaration was
     * "uniform mat4 g_WorldMatrix;".
     */
	public var name:String;

	public var location:UniformLocation;

	/**
     * True if the shader value was changed.
     */
	public var updateNeeded:Bool = true;

	public inline function new()
	{
	}
}

