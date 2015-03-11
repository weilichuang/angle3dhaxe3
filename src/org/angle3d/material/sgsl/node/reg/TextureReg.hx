package org.angle3d.material.sgsl.node.reg;

import org.angle3d.material.sgsl.RegType;
import org.angle3d.material.sgsl.node.LeafNode;

class TextureReg extends RegNode
{
	public function new(dataType:String, name:String)
	{
		super(RegType.UNIFORM, dataType, name);
	}
	
	override public function clone(result:LeafNode = null):LeafNode
	{
		if (result == null)
			result = new TextureReg(dataType, name);
			
		return super.clone(result);
	}
}


