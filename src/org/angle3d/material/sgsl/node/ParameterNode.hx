package org.angle3d.material.sgsl.node;
import haxe.ds.StringMap;

class ParameterNode extends LeafNode
{
	public function new(dataType:String, name:String)
	{
		super(name);
		this.type = NodeType.FUNCTIONPARAM;
		this.dataType = dataType;
	}
	
	override public function checkDataType(programNode:ProgramNode, paramMap:StringMap<String> = null):Void
	{
		
	}

	override public function clone():LeafNode
	{
		return new ParameterNode(dataType, name);
	}

	override public function toString(level:Int = 0):String
	{
		return dataType + " " + name;
	}
}

