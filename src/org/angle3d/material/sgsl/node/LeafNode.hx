package org.angle3d.material.sgsl.node;

import haxe.ds.StringMap;

class LeafNode
{
	public var type:NodeType;
	public var name:String;

	public function new(name:String = "")
	{
		this.name = name;
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


