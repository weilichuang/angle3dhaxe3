package org.angle3d.material.sgsl.node;

import haxe.ds.StringMap;
import org.angle3d.material.sgsl.node.reg.RegNode;

class AtomNode extends LeafNode
{
	public function new(name:String = "")
	{
		super(name);
		this.type = NodeType.IDENTIFIER;
	}
	
	override public function checkDataType(programNode:ProgramNode):Void
	{
		if (this.type == NodeType.CONST)
		{
			_dataType = "float";
		}
		else if (this.name == "output" || this.name == "depth")
		{
			_dataType = "vec4";
		}
		else
		{
			var node:RegNode = programNode.getRegNode(this.name);
			if (node != null)
				this._dataType = node.dataType;
		}

		if (this.mask != null && this.mask.length > 0)
		{
			switch(mask.length)
			{
				case 1:
					_dataType = "float";
				case 2:
					_dataType = "vec2";
				case 3:
					_dataType = "vec3";
				case 4:
					_dataType = "vec4";
			}
		}
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

