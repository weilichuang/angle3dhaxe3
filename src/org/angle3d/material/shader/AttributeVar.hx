package org.angle3d.material.shader;
import flash.display3D.Context3DVertexBufferFormat;


/**
 * An attribute is a shader variable mapping to a VertexBuffer data
 * on the CPU.
 *
 * @author Andy
 */
class AttributeVar extends ShaderVariable
{
	public var index:Int;

	public var format:Context3DVertexBufferFormat;

	public function new(name:String, size:Int)
	{
		super(name, size);
	}
}


