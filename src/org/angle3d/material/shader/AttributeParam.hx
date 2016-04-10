package org.angle3d.material.shader;
import flash.display3D.Context3DVertexBufferFormat;


/**
 * An attribute is a shader variable mapping to a VertexBuffer data
 * on the CPU.
 *
 
 */
class AttributeParam extends ShaderParam
{
	public var index:Int;

	public var format:Context3DVertexBufferFormat;
	
	public var bufferType:Int;

	public function new(name:String, size:Int, bufferType:Int)
	{
		super(name, size);
		this.bufferType = bufferType;
	}
}


