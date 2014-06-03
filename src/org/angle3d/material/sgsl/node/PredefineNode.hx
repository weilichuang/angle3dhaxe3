package org.angle3d.material.sgsl.node;

import flash.Vector;

/**
 * 预定义条件
 * 可能包含多个部分，比如ifdef(...){...},elseif(...){...},else{...}等
 */
class PredefineNode extends BranchNode
{
	public function new()
	{
		super();
	}

	override public function clone():LeafNode
	{
		var node:PredefineNode = new PredefineNode();
		cloneChildren(node);
		return node;
	}

	/**
	 * 符合预定义条件
	 */
	public function isMatch(defines:Array<String>):Bool
	{
		var subNode:PredefineSubNode;
		var cLength:Int = mChildren.length;
		for (i in 0...cLength)
		{
			subNode = Std.instance(mChildren[i], PredefineSubNode);
			if (subNode.isMatch(defines))
			{
				return true;
			}
		}
		return false;
	}

	/**
	 * 返回符合条件的AstNode数组
	 * @param defines
	 * @return
	 *
	 */
	public function getMatchChildren(defines:Array<String>):Array<LeafNode>
	{
		var subNode:PredefineSubNode;
		var cLength:Int = mChildren.length;
		for (i in 0...cLength)
		{
			subNode = Std.instance(mChildren[i], PredefineSubNode);
			//只执行最先符合条件的
			if (subNode.isMatch(defines))
			{
				subNode.filter(defines);
				return subNode.children.slice(0);
			}
		}

		return null;
	}

	override public function toString(level:Int = 0):String
	{
		var result:String = "";
		result += getChildrenString(level - 1);
		return result;
	}
}

