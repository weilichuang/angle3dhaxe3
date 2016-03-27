package org.angle3d.material.sgsl.node.reg;

import org.angle3d.material.sgsl.DataType;
import org.angle3d.material.sgsl.node.LeafNode;
import org.angle3d.material.sgsl.RegType;

/**
 * SGSL中的变量
 * @author weilichuang
 */
class RegNode extends LeafNode
{
	public var regType:RegType;

	//注册地址
	public var index:Int;

	public function new(regType:RegType, dataType:String, name:String)
	{
		super(name);

		this.type = NodeType.SHADERVAR;
		this.regType = regType;
		this.dataType = dataType;

		index = -1;
	}
	
	override public function clone(result:LeafNode = null):LeafNode
	{
		if (result == null)
			result = new RegNode(regType, dataType, name);
			
		var reg:RegNode = cast result;
		reg.regType = regType;
		reg.index = index;
			
		return super.clone(result);
	}

	override public function toString(level:Int = 0):String
	{
		return getSpace(level) + RegType.getRegNameBy(regType) + " " + dataType + " " + name + ";\n";
	}

	public var registered(get, null):Bool;
	private inline function get_registered():Bool
	{
		return index > -1;
	}

	/**
	 * 在寄存器中的大小
	 */
	public var size(get, null):Int;
	private function get_size():Int
	{
		return DataType.getSize(dataType);
	}
}

