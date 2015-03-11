package org.angle3d.material.sgsl.node.reg;

import org.angle3d.material.sgsl.RegType;
import org.angle3d.material.sgsl.node.LeafNode;

class AttributeReg extends RegNode
{
	public var bufferType:String;
	
	public function new(dataType:String, name:String, bufferType:String)
	{
		super(RegType.ATTRIBUTE, dataType, name);
		this.bufferType = bufferType;
	}
	
	override public function clone(result:LeafNode = null):LeafNode
	{
		if (result == null)
			result = new AttributeReg(dataType, name, bufferType);
		
		var reg:AttributeReg = cast result;
		reg.bufferType = bufferType;
			
		return super.clone(reg);
	}
	
	override public function toString(level:Int = 0):String
	{
		if (bufferType != null && bufferType != "")
		{
			return getSpace(level) + regType + " " + dataType + " " + name + "(" + bufferType + ");\n";
		}
		return getSpace(level) + regType + " " + dataType + " " + name + ";\n";
	}
}

