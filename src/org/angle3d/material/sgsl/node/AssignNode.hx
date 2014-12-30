package org.angle3d.material.sgsl.node;
import de.polygonal.core.util.Assert;
import org.angle3d.material.sgsl.node.reg.RegFactory;
import org.angle3d.material.sgsl.node.reg.RegNode;
import org.angle3d.material.sgsl.utils.SgslUtils;

class AssignNode extends SgslNode
{
	public function new() 
	{
		super(NodeType.ASSIGNMENT, "=");
	}
	
	override public function checkValid():Void
	{
		Assert.assert(mChildren[0].type == NodeType.IDENTIFIER);
		Assert.assert(mChildren.length == 2);
	}
	
	//前提，所有自定义函数已替换
	override public function flat(node:SgslNode):Void
	{
		if (Std.is(mChildren[1], SgslNode))
		{
			mChildren[1].flat(node);
			
			node.addChild(this.clone());
		}
		else
		{
			node.addChild(this.clone());
		}
	}
	
	override public function clone():LeafNode
	{
		var node:AssignNode = new AssignNode();
		cloneChildren(node);
		return node;
	}
	
	override public function toString(level:Int = 0):String
	{
		var result:String = getSpace(level) + mChildren[0].toString(0) +" = " + mChildren[1].toString(0) + ";\n";

		return result;
	}
}