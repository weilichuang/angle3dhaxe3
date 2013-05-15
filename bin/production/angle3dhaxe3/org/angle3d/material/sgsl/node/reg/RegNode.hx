package org.angle3d.material.sgsl.node.reg;

import org.angle3d.material.sgsl.DataType;
import org.angle3d.material.sgsl.node.LeafNode;
import org.angle3d.material.sgsl.RegType;


/**
 * SGSL中的变量
 * @author andy
 */
class RegNode extends LeafNode
{
	public var regType:String;

	public var dataType:String;

	//注册地址
	public var index:Int;

	public function new(regType:String, dataType:String, name:String)
	{
		super(name);

		this.regType = regType;
		this.dataType = dataType;

		index = -1;
	}

	override public function clone():LeafNode
	{
		return new RegNode(regType, dataType, name);
	}

	override public function toString(level:Int = 0):String
	{
		return getSpace(level) + regType + " " + dataType + " " + name + ";\n";
	}

	public var registered(get, null):Bool;
	private function get_registered():Bool
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

