package org.angle3d.material.sgsl.node;

import haxe.ds.StringMap;

/**
 *
 * @author andy
 *
 */
class AtomNode extends LeafNode
{
	public var mask:String;

	public function new(name:String = "")
	{
		super(name);
		mask = "";
	}

	//TODO 这个可能会有问题
	override public function replaceLeafNode(paramMap:StringMap<LeafNode>):Void
	{
		var node:AtomNode = cast(paramMap.get(this.name), AtomNode);
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

