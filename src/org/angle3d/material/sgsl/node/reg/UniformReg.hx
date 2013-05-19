package org.angle3d.material.sgsl.node.reg;

import org.angle3d.material.sgsl.DataType;
import org.angle3d.material.sgsl.RegType;
import org.angle3d.material.sgsl.node.LeafNode;

/**
 * UniformReg
 * @author andy
 */
class UniformReg extends RegNode
{
	/**
	 * 数组大小
	 */
	public var arraySize:Int;
	
	public var uniformBind:String;

	public function new(dataType:String, name:String, uniformBind:String = "", arraySize:Int = 1)
	{
		super(RegType.UNIFORM, dataType, name);
		this.uniformBind = uniformBind;
		this.arraySize = arraySize;
	}

	override public function clone():LeafNode
	{
		return new UniformReg(dataType, name, uniformBind, arraySize);
	}

	override private function get_size():Int
	{
		return arraySize * DataType.getSize(dataType);
	}
}

