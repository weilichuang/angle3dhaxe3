package org.angle3d.material.sgsl.node.reg;

import org.angle3d.material.sgsl.DataType;
import org.angle3d.material.sgsl.RegType;
import org.angle3d.material.sgsl.node.LeafNode;

/**
 * output position|color
 
 */
class OutputReg extends RegNode
{
	public function new(index:Int)
	{
		super(RegType.OUTPUT, DataType.VEC4, "");

		this.index = index;
		this.name = "output";
		if (this.index > 0)
		{
			this.name += index + "";
		}
	}
	
	override public function clone(result:LeafNode = null):LeafNode
	{
		if (result == null)
			result = new OutputReg(this.index);
			
		return super.clone(result);
	}
}

