package org.angle3d.material.sgsl.node.reg;

import org.angle3d.material.sgsl.RegType;
import org.angle3d.material.sgsl.TexFlag;
import org.angle3d.material.sgsl.node.LeafNode;

class TextureReg extends RegNode
{
	public var texFlag:TexFlag;
	
	public function new(dataType:String, name:String, flags:Array<String> = null)
	{
		super(RegType.UNIFORM, dataType, name);
		this.texFlag = new TexFlag();
		if (flags != null)
			this.texFlag.parseFlags(flags);
	}
	
	override public function clone(result:LeafNode = null):LeafNode
	{
		if (result == null)
			result = new TextureReg(dataType, name);
		cast(result, TextureReg).texFlag.copyFrom(this.texFlag);
		return super.clone(result);
	}
	
	override public function toString(level:Int = 0):String
	{
		return getSpace(level) + regType + " " + dataType + " " + name + "<" + texFlag.toString() + ">;\n";
	}
}


