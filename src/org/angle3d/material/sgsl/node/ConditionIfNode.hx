package org.angle3d.material.sgsl.node;

import org.angle3d.material.sgsl.node.LeafNode;
import org.angle3d.material.sgsl.node.reg.RegFactory;
import org.angle3d.material.sgsl.node.reg.RegNode;
import org.angle3d.material.sgsl.utils.SgslUtils;

class ConditionIfNode extends SgslNode
{
	public var compareMethod:String;
	
	public function new()
	{
		super(NodeType.CONDITION, "if");
	}
	
	override private function get_dataType():String
	{
		return DataType.VOID;
	}
	
	//先处理两个对比表达式，然后处理自身，最后处理内部内容
	override public function flat(programNode:ProgramNode, functionNode:FunctionNode, result:Array<LeafNode>):Void
	{
		var newIfNode:ConditionIfNode = new ConditionIfNode();
		newIfNode.isFlat = true;
		newIfNode.compareMethod = this.compareMethod;
		
		var child:LeafNode;
		for (i in 0...2)
		{
			child = mChildren[i];
			
			if (Std.is(child, SgslNode))
			{
				child.flat(programNode, functionNode, result);
				
				if (Std.is(child, OpNode) || Std.is(child, NegNode) || Std.is(child, FunctionCallNode))
				{	
					var tmpVar:RegNode = RegFactory.create(SgslUtils.getTempName("t_local"), RegType.TEMP, child.dataType);
					
					if (child.dataType == null)
					{
						throw '${child.name}.dataType cant be null';
					}
					
					programNode.addReg(tmpVar);
				
					var destNode:AtomNode = new AtomNode(tmpVar.name);
					destNode.dataType = child.dataType;
					
					var newAssignNode:AssignNode = new AssignNode();
					newAssignNode.addChild(destNode);
					
					newAssignNode.addChild(child.clone());
					
					result.push(newAssignNode);
					
					var newChild:LeafNode = destNode.clone();
					newChild.mask = child.mask;
					newIfNode.addChild(newChild);
				}
				else
				{
					newIfNode.addChild(child);
				}
			}
			else
			{
				newIfNode.addChild(child);
			}
		}
		
		result.push(newIfNode);
		
		for (i in 2...mChildren.length)
		{
			child = mChildren[i];
			
			child.flat(programNode, functionNode, result);
			
			if (child.type != NodeType.CONDITION)
			{
				result.push(child);
			}
		}
	}

	override public function clone():LeafNode
	{
		var node:ConditionIfNode = new ConditionIfNode();
		node.compareMethod = this.compareMethod;
		cloneChildren(node);
		return node;
	}

	override public function toString(level:Int = 0):String
	{
		var space:String = getSpace(level++);

		var text:String = space + this.name + "(" + mChildren[0].toString(0) + " " + this.compareMethod + " " + mChildren[1].toString(0) + ")\n";
		
		if (!isFlat)
		{
			text += space + "{\n";
			
			var length:Int = mChildren.length;
			for (i in 2...length)
			{
				var m:LeafNode = mChildren[i];
				text += m.toString(level + 1);
			}
			text += "\n" + space + "}\n";
		}
		
		return text;
	}

}
