package org.angle3d.material.sgsl.node;

import org.angle3d.ds.FastStringMap;
import org.angle3d.material.sgsl.node.reg.RegNode;

class AtomNode extends LeafNode
{
	public function new(name:String)
	{
		super(name);
		this.type = NodeType.IDENTIFIER;
	}
	
	override public function checkDataType(programNode:ProgramNode, paramMap:FastStringMap<String> = null):Void
	{
		if (this.type == NodeType.NUMBER)
		{
			_dataType = "float";
		}
		else if (this.name == "output" || this.name == "output1" || this.name == "output2" || this.name == "output3" || this.name == "depth")
		{
			_dataType = "vec4";
		}
		else
		{
			var node:RegNode = programNode.getRegNode(this.name);
			if (node != null)
				this._dataType = node.dataType;
			else if (paramMap != null && paramMap.exists(this.name))
			{
				this._dataType = paramMap.get(this.name);
			}
			else
			{
				throw 'this node $name does not define';
			}
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
	
	override public function replaceParamNode(paramMap:FastStringMap<LeafNode>):Void
	{
		var node:AtomNode = Std.downcast(paramMap.get(this.name), AtomNode);
		if (node != null)
		{
			this.name = node.name;
			if (node.mask.length > 0)
			{
				this.mask = node.mask;
			}
		}
	}

	override public function clone(result:LeafNode = null):LeafNode
	{
		if (result == null)
			result = new AtomNode(this.name);
			
		super.clone(result);
		
		return result;
	}

	override public function toString(level:Int = 0):String
	{
		return (mask != "") ? (name + "." + mask) : name;
	}
}

