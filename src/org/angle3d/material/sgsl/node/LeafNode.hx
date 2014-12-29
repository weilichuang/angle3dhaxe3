package org.angle3d.material.sgsl.node;

import haxe.ds.StringMap;
import org.angle3d.material.sgsl.node.agal.AgalLine;
import org.angle3d.material.sgsl.node.agal.FlatInfo;

//TODO 需要知道LeafNode的数据类型
class LeafNode
{
	public static var FLAT_ID:Int = 0;
	
	public var type:NodeType;
	public var name:String;
	
	public var mask:String;
	
	public var depth:Int = 0;

	public function new(name:String = "")
	{
		this.name = name;
	}
	
	public function getDataType():String
	{
		return "";
	}
	
	public function needFlat():Bool
	{
		return false;
	}
	
	public function flat(result:Array<LeafNode>):Void
	{
		
	}
	
	public function calDepth(depth:Int):Void
	{
		this.depth = depth + 1;
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


