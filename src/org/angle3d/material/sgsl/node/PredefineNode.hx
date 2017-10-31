package org.angle3d.material.sgsl.node;



/**
 * 预定义条件
 * 可能包含多个部分，比如ifdef(...){...},elseif(...){...},else{...}等
 */
class PredefineNode extends SgslNode
{
	public function new()
	{
		super(NodeType.PREPROCESOR);
	}
	
	override public function clone(result:LeafNode = null):LeafNode
	{
		if (result == null)
			result = new PredefineNode();
			
		return super.clone(result);
	}
	
	/**
	 * 符合预定义条件
	 */
	public function isMatch(defines:Vector<String>):Bool
	{
		var subNode:PredefineSubNode;
		var cLength:Int = mChildren.length;
		for (i in 0...cLength)
		{
			subNode = cast(mChildren[i], PredefineSubNode);
			if (subNode.isMatch(defines))
			{
				return true;
			}
		}
		return false;
	}

	/**
	 * 返回符合条件的LeafNode数组
	 * @param defines
	 * @return
	 *
	 */
	public function getMatchChildren(defines:Vector<String>):Vector<LeafNode>
	{
		var subNode:PredefineSubNode;
		var cLength:Int = mChildren.length;
		for (i in 0...cLength)
		{
			subNode = cast(mChildren[i], PredefineSubNode);
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

