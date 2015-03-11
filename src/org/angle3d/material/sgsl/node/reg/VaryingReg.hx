package org.angle3d.material.sgsl.node.reg;

import org.angle3d.material.sgsl.RegType;
import org.angle3d.material.sgsl.node.LeafNode;

class VaryingReg extends RegNode
{
	public function new(dataType:String, name:String)
	{
		super(RegType.VARYING, dataType, name);
	}
	
	override public function clone(result:LeafNode = null):LeafNode
	{
		if (result == null)
			result = new VaryingReg(dataType, name);
			
		return super.clone(result);
	}
}

