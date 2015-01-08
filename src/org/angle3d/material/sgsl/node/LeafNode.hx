package org.angle3d.material.sgsl.node;

import haxe.ds.StringMap;

class LeafNode
{
	public var isFlat:Bool = false;
	
	public var type:NodeType;
	public var name:String;
	
	public var mask:String = "";
	
	public var parent:SgslNode;
	
	public var dataType(get, set):Null<String>;
	
	private var _dataType:String;

	public function new(name:String = "")
	{
		this.name = name;
		dataType = null;
	}
	
	public function isRelative():Bool
	{
		return false;
	}
	
	public function checkDataType(programNode:ProgramNode,paramMap:StringMap<String> = null):Void
	{
		
	}
	
	/**
	 * 检查合法性
	 */
	public function checkValid():Void
	{
		
	}
	
	private function get_dataType():Null<String>
	{
		return _dataType;
	}
	
	private function set_dataType(value:Null<String>):Null<String>
	{
		return _dataType = value;
	}
	
	public function flat(programNode:ProgramNode, functionNode:FunctionNode, result:Array<LeafNode>):Void
	{
		if (this.parent == functionNode)
		{
			result.push(this);
		}
	}

	public function renameLeafNode(map:StringMap<String>):Void
	{
		if (map.exists(this.name))
		{
			this.name = map.get(this.name);
		}
	}

	public function replaceLeafNode(paramMap:StringMap<LeafNode>):Void
	{

	}

	public function clone():LeafNode
	{
		return new LeafNode(name);
	}

	public function toString(level:Int = 0):String
	{
		return name;
	}

	private function getSpace(level:Int):String
	{
		var space:String = "";
		for (i in 0...level)
			space += "   ";
		return space;
	}
}


