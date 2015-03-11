package org.angle3d.material.sgsl.node.reg;

import org.angle3d.material.sgsl.DataType;
import org.angle3d.material.sgsl.RegType;
import org.angle3d.material.sgsl.node.LeafNode;

/**
 * UniformReg
 * @author weilichuang
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
	
	override public function clone(result:LeafNode = null):LeafNode
	{
		if (result == null)
			result = new UniformReg(dataType, name, uniformBind, arraySize);
		
		var reg:UniformReg = cast result;
		reg.uniformBind = uniformBind;
		reg.arraySize = arraySize;
			
		return super.clone(reg);
	}

	override private function get_size():Int
	{
		return arraySize * DataType.getSize(dataType);
	}
	
	override public function toString(level:Int = 0):String
	{
		var result:String = getSpace(level) + regType + " " + dataType + " " + name;
		
		if (uniformBind != null && uniformBind != "")
		{
			result += "(" + uniformBind + ")";
		}
		
		if (arraySize > 1)
		{
			result += "[" + arraySize + "]";
		}
		
		result += ";\n";
		
		return result;
	}
}

