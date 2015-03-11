package org.angle3d.material.sgsl.node;
import haxe.ds.UnsafeStringMap;

class ParameterNode extends LeafNode
{
	public function new(dataType:String, name:String)
	{
		super(name);
		this.type = NodeType.FUNCTIONPARAM;
		this.dataType = dataType;
	}
	
	override public function checkDataType(programNode:ProgramNode, paramMap:UnsafeStringMap<String> = null):Void
	{
		
	}
	
	override public function clone(result:LeafNode = null):LeafNode
	{
		if (result == null)
			result = new ParameterNode(dataType, name);
			
		return super.clone(result);
	}

	override public function toString(level:Int = 0):String
	{
		return dataType + " " + name;
	}
}

