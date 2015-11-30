package org.angle3d.material.sgsl.node.reg;

import org.angle3d.material.sgsl.RegType;
import org.angle3d.material.sgsl.node.LeafNode;
import org.angle3d.scene.mesh.BufferType;

class AttributeReg extends RegNode
{
	public var bufferType:Int = -1;
	
	public function new(dataType:String, name:String, bufferTypeName:String)
	{
		super(RegType.ATTRIBUTE, dataType, name);
		this.bufferType = BufferType.getBufferType(bufferTypeName);
	}
	
	override public function clone(result:LeafNode = null):LeafNode
	{
		if (result == null)
			result = new AttributeReg(dataType, name, BufferType.getBufferTypeName(bufferType));
		
		var reg:AttributeReg = cast result;
		reg.bufferType = bufferType;
			
		return super.clone(reg);
	}
	
	override public function toString(level:Int = 0):String
	{
		if (bufferType != -1)
		{
			return getSpace(level) + regType + " " + dataType + " " + name + "(" + BufferType.getBufferTypeName(bufferType) + ");\n";
		}
		return getSpace(level) + regType + " " + dataType + " " + name + ";\n";
	}
}

