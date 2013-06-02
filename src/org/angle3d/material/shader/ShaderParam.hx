package org.angle3d.material.shader;


/**
 * andy
 * @author
 */
class ShaderParam
{
	public var name:String;

	public var location:Int;

	public var size:Int;

	public function new(name:String, size:Int)
	{
		this.name = name;
		this.size = size;
		location = -1;
	}
}

