package org.angle3d.material.sgsl.node.reg;

import org.angle3d.material.sgsl.RegType;
import org.angle3d.material.sgsl.node.LeafNode;

/**
 * andy
 * @author andy
 */
class AttributeReg extends RegNode
{
	public var bufferType:String;
	
	public function new(dataType:String, name:String, bufferType:String)
	{
		super(RegType.ATTRIBUTE, dataType, name);
		this.bufferType = bufferType;
	}

	override public function clone():LeafNode
	{
		return new AttributeReg(dataType, name, bufferType);
	}
}

