package org.angle3d.material.sgsl.node;

import haxe.ds.StringMap;

class AtomNode extends LeafNode
{
	public function new(name:String = "")
	{
		super(name);
		mask = "";
	}

	override public function replaceLeafNode(paramMap:StringMap<LeafNode>):Void
	{
		var node:AtomNode = Std.instance(paramMap.get(this.name), AtomNode);
		if (node != null)
		{
			this.name = node.name;
			if (node.mask.length > 0)
			{
				this.mask = node.mask;
			}
		}
	}

	public function isRelative():Bool
	{
		return false;
	}

	override public function clone():LeafNode
	{
		var node:AtomNode = new AtomNode(this.name);
		node.mask = mask;
		return node;
	}

	override public function toString(level:Int = 0):String
	{
		return (mask != "") ? (name + "." + mask) : name;
	}
}

