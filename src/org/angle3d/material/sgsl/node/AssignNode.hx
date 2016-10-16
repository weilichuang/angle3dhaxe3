package org.angle3d.material.sgsl.node;
import org.angle3d.error.Assert;
import flash.Vector;
import org.angle3d.material.sgsl.node.reg.RegFactory;
import org.angle3d.material.sgsl.node.reg.RegNode;
import org.angle3d.material.sgsl.utils.SgslUtils;

class AssignNode extends SgslNode
{
	public function new() 
	{
		super(NodeType.ASSIGNMENT, "=");
	}
	
	override public function toAgalNode():AgalNode
	{
		var node:AgalNode = new AgalNode();
		node.dest = mChildren[0].clone();
		
		if (Std.is(mChildren[1], FunctionCallNode))
		{
			var funcCall:FunctionCallNode = cast mChildren[1];
			node.name = mChildren[1].name;
			
			if(funcCall.numChildren >= 1)
				node.source1 = funcCall.children[0].clone();
				
			if(funcCall.numChildren == 2)
				node.source2 = funcCall.children[1].clone();
		}
		else
		{
			node.name = "mov";
			node.source1 = mChildren[1].clone();
			node.source2 = null;
		}
		return node;
	}
	
	override private function get_dataType():String
	{
		return DataType.VOID;
	}
	
	override public function checkValid():Void
	{
		Assert.assert(mChildren.length == 2);
	}
	
	override public function flat(programNode:ProgramNode, functionNode:FunctionNode, result:Vector<LeafNode>):Void
	{
		if (Std.is(mChildren[1], SgslNode))
		{
			var node:SgslNode = cast mChildren[1];
			
			node.flat(programNode, functionNode, result);
			
			//临时添加ArrayAccessNode判断，flat函数需要整体重构
			if (!Std.is(node, ArrayAccessNode))
			{
				var mask:String = node.mask;
				if (mask != null && mask.length > 0)
				{
					var tmpVar:RegNode = RegFactory.create(SgslUtils.getTempName("t_local"), RegType.TEMP, node.dataType);
					programNode.addReg(tmpVar);
				
					var destNode:AtomNode = new AtomNode(tmpVar.name);
					destNode.dataType = node.dataType;
					
					var newAssignNode:AssignNode = new AssignNode();
					newAssignNode.addChild(destNode);
					
					var sourceNode:LeafNode = node.clone();
					sourceNode.mask = "";
					newAssignNode.addChild(sourceNode);
			
					var newNode:LeafNode = destNode.clone();
					newNode.mask = mask;
					setChildAt(newNode, 1);

					result.push(newAssignNode);
				}
			}
		}
		
		if (this.parent == functionNode)
		{
			result.push(this);
		}
	}
	
	override public function clone(result:LeafNode = null):LeafNode
	{
		if (result == null)
			result = new AssignNode();
			
		return super.clone(result);
	}
	
	override public function toString(level:Int = 0):String
	{
		var result:String = getSpace(level) + mChildren[0].toString(0) +" = " + mChildren[1].toString(0) + ";\n";

		return result;
	}
}