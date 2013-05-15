package org.angle3d.material.sgsl.node.reg;

import org.angle3d.material.sgsl.RegType;
import org.angle3d.material.sgsl.node.LeafNode;


/**
 * andy
 * @author andy
 */
class VaryingReg extends RegNode
{
	public function new(dataType:String, name:String)
	{
		super(RegType.VARYING, dataType, name);
	}

	override public function clone():LeafNode
	{
		return new VaryingReg(dataType, name);
	}
}

