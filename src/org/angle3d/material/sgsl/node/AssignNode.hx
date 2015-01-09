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
	
	override private function get_dataType():String
	{
		return DataType.VOID;
	}
	
	override public function checkValid():Void
	{
		Assert.assert(mChildren[0].type == NodeType.IDENTIFIER);
		Assert.assert(mChildren.length == 2);
	}
	
	override public function flat(programNode:ProgramNode, functionNode:FunctionNode, result:Array<LeafNode>):Void
	{
		if (Std.is(mChildren[1], SgslNode))
		{
			var node:SgslNode = cast mChildren[1];
			
			node.flat(programNode, functionNode, result);
			
			if (node.mask != null && node.mask.length > 0)
			{
				var tmpVar:RegNode = RegFactory.create(SgslUtils.getTempName("t_local"), RegType.TEMP, node.dataType);
					
				programNode.addReg(tmpVar);
			
				var destNode:AtomNode = new AtomNode(tmpVar.name);
				destNode.dataType = node.dataType;
				
				var newAssignNode:AssignNode = new AssignNode();
				newAssignNode.addChild(destNode);
				
				newAssignNode.addChild(node.clone());
				
				mChildren[1] = destNode.clone();
				mChildren[1].mask = node.mask;
				mChildren[1].parent = this;

				result.push(newAssignNode);
			}
		}
		
		if (this.parent == functionNode)
		{
			result.push(this);
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