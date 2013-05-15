package org.angle3d.material.sgsl.node.reg;

import org.angle3d.material.sgsl.DataType;
import org.angle3d.material.sgsl.RegType;
import org.angle3d.material.sgsl.node.LeafNode;

/**
 * output position|color
 * @author andy
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

	override public function clone():LeafNode
	{
		return new OutputReg(this.index);
	}
}

