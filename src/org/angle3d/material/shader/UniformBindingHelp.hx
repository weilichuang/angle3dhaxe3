package org.angle3d.material.shader;

/**
 * andy
 * @author andy
 */
class UniformBindingHelp
{
	public var shaderType:ShaderType;

	public var name:String;

	public var bindType:UniformBinding;

	public function new(shaderType:ShaderType, name:String, bindType:UniformBinding)
	{
		this.shaderType = shaderType;
		this.name = name;
		this.bindType = bindType;
	}
}
