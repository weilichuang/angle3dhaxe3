package org.angle3d.material.sgsl.node.reg;

import org.angle3d.material.sgsl.RegType;
import org.angle3d.material.sgsl.node.LeafNode;

class TextureReg extends RegNode
{
	public var flags:Array<String>;
	
	public function new(dataType:String, name:String, flags:Array<String>)
	{
		super(RegType.UNIFORM, dataType, name);
		this.flags = flags != null ? flags : [];
	}
	
	override public function clone(result:LeafNode = null):LeafNode
	{
		if (result == null)
			result = new TextureReg(dataType, name, flags);
			
		return super.clone(result);
	}
	
	override public function toString(level:Int = 0):String
	{
		if (flags != null && flags.length > 0)
		{
			return getSpace(level) + regType + " " + dataType + " " + name + "<" + flags.join(",") + ">;\n";
		}
		else
		{
			return getSpace(level) + regType + " " + dataType + " " + name + ";\n";
		}
	}
}


