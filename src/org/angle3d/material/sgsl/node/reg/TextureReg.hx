package org.angle3d.material.sgsl.node.reg;

import org.angle3d.material.sgsl.RegType;
import org.angle3d.material.sgsl.node.LeafNode;

/**
 * andy
 * @author weilichuang
 */
class TextureReg extends RegNode
{
	public function new(dataType:String, name:String)
	{
		super(RegType.UNIFORM, dataType, name);
	}

	override public function clone():LeafNode
	{
		return new TextureReg(dataType, name);
	}
}


