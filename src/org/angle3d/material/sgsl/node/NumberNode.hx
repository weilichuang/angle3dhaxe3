package org.angle3d.material.sgsl.node;
import org.angle3d.ds.FastStringMap;
import org.angle3d.material.sgsl.node.reg.RegNode;

class NumberNode extends AtomNode
{
	public var value:Float;

	public function new(value:Float)
	{
		super(value + "");
		this.type = NodeType.NUMBER;
		this.value = value;
		this.dataType = DataType.FLOAT;
	}
	
	override public function checkDataType(programNode:ProgramNode, paramMap:FastStringMap<String> = null):Void
	{
		
	}
	
	override public function clone(result:LeafNode = null):LeafNode
	{
		if (result == null)
			result = new NumberNode(this.value);
			
		var numberNode:NumberNode = cast result;
		numberNode.value = this.value;
			
		return super.clone(result);
	}

	override public function toString(level:Int = 0):String
	{
		var out:String = value + "";

		return out;
	}
}

