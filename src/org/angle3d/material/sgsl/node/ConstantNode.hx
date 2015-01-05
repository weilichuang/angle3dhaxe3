package org.angle3d.material.sgsl.node;
import haxe.ds.StringMap;
import org.angle3d.material.sgsl.node.reg.RegNode;

class ConstantNode extends AtomNode
{
	public var value:Float;

	public function new(value:Float)
	{
		super(value + "");
		this.type = NodeType.CONST;
		this.value = value;
		this.dataType = DataType.FLOAT;
	}
	
	override public function checkDataType(programNode:ProgramNode, paramMap:StringMap<String> = null):Void
	{
		
	}

	override public function clone():LeafNode
	{
		return new ConstantNode(this.value);
	}

	override public function toString(level:Int = 0):String
	{
		var out:String = value + "";

		return out;
	}
}

