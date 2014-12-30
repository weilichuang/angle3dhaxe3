package org.angle3d.material.sgsl.node;

import haxe.ds.StringMap;
import org.angle3d.material.sgsl.node.agal.AgalLine;

class LeafNode
{
	public var type:NodeType;
	public var name:String;
	
	public var mask:String = "";
	
	public var depth:Int = 0;

	public function new(name:String = "")
	{
		this.name = name;
	}
	
	/**
	 * 检查合法性
	 */
	public function checkValid():Void
	{
		
	}
	
	public function getDataType():String
	{
		return "";
	}
	
	public function flat(node:SgslNode):Void
	{
		
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


