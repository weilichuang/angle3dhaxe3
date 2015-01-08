package org.angle3d.material.sgsl.node;
import org.angle3d.material.sgsl.node.reg.RegFactory;
import org.angle3d.material.sgsl.node.reg.RegNode;
import org.angle3d.material.sgsl.utils.SgslUtils;

//TODO check children[0] must be float
class ArrayAccessNode extends SgslNode
{
	public var offset:Int = 0;

	public function new(name:String)
	{
		super(NodeType.ARRAYACCESS, name);
	}
	
	override public function flat(programNode:ProgramNode, functionNode:FunctionNode, result:Array<LeafNode>):Void
	{
		super.flat(programNode, functionNode, result);
	}

	override public function isRelative():Bool
	{
		return mChildren[0] != null;
	}

	override public function clone():LeafNode
	{
		var node:ArrayAccessNode = new ArrayAccessNode(name);
		if (mChildren.length == 1)
		{
			node.mChildren[0] = mChildren[0].clone();
		}
		node.offset = offset;
		node.mask = mask;
		return node;
	}

	override public function toString(level:Int = 0):String
	{
		var out:String = this.name + "[";

		if (mChildren[0] != null)
		{
			out += mChildren[0].toString(level);
		}

		if (offset >= 0)
		{
			if (mChildren[0] != null)
			{
				out += " + ";
			}
			out += offset + "";
		}

		out += "]";

		if (mask != "")
		{
			out += "." + mask;
		}

		return out;
	}
}

