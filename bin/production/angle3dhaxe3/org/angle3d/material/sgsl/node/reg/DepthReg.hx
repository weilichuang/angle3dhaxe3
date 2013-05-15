package org.angle3d.material.sgsl.node.reg;

import org.angle3d.material.sgsl.DataType;
import org.angle3d.material.sgsl.RegType;
import org.angle3d.material.sgsl.node.LeafNode;

/**
 * fragment depth output
 * @author andy
 */
//需要测试是否正确可用
class DepthReg extends RegNode
{
	public function new(index:Int = 0)
	{
		super(RegType.DEPTH, DataType.VEC4, "");

		this.index = index;
		this.name = "depth";
		if (this.index > 0)
		{
			this.name += index + "";
		}
	}

	override public function clone():LeafNode
	{
		return new DepthReg(this.index);
	}
}


