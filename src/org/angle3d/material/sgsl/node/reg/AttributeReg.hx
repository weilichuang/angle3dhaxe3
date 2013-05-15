package org.angle3d.material.sgsl.node.reg;

import org.angle3d.material.sgsl.RegType;
import org.angle3d.material.sgsl.node.LeafNode;

/**
 * andy
 * @author andy
 */
class AttributeReg extends RegNode
{
	public function new(dataType:String, name:String)
	{
		super(RegType.ATTRIBUTE, dataType, name);
	}

	override public function clone():LeafNode
	{
		return new AttributeReg(dataType, name);
	}
}

