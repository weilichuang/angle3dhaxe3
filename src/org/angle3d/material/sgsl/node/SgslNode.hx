package org.angle3d.material.sgsl.node;

import haxe.ds.StringMap;
import org.angle3d.material.sgsl.node.reg.RegFactory;
import org.angle3d.material.sgsl.node.reg.RegNode;
import org.angle3d.material.sgsl.utils.SgslUtils;

using org.angle3d.utils.ArrayUtil;

class SgslNode extends LeafNode
{
	private var mChildren:Array<LeafNode>;

	public function new(type:NodeType, name:String = "")
	{
		super(name);

		this.type = type;
		
		mChildren = new Array<LeafNode>();
	}
	
	override public function flat(node:SgslNode):Void
	{
		for (i in 0...mChildren.length)
		{
			var child:LeafNode = mChildren[i];
			if (Std.is(child, SgslNode))
			{
				child.flat(node);
				
				if (Std.is(child, OpNode) || (Std.is(child, FunctionCallNode) && cast(child,FunctionCallNode).getDataType() != DataType.VOID))
				{
					var tmpVar:RegNode = RegFactory.create(SgslUtils.getTempName("t_local"), RegType.TEMP, child.getDataType());
				
					var destNode:AtomNode = new AtomNode(tmpVar.name);
					var newAssignNode:AssignNode = new AssignNode();
					newAssignNode.addChild(destNode);
					newAssignNode.addChild(child.clone());
					
					mChildren[i] = destNode.clone();
					
					node.addChild(tmpVar);
					node.addChild(newAssignNode);
				}
				//else
				//{
					//node.addChild(child);
				//}
			}
		}
	}

	public function addChild(node:LeafNode):Void
	{
		mChildren.push(node);
	}

	public function removeChild(node:LeafNode):Void
	{
		mChildren.remove(node);
	}

	public function addChildren(list:Array<LeafNode>):Void
	{
		var count:Int = list.length;
		for (i in 0...count)
		{
			addChild(list[i]);
		}
	}

	public var children(get, null):Array<LeafNode>;
	private inline function get_children():Array<LeafNode>
	{
		return mChildren;
	}

	public var numChildren(get, null):Int;
	private inline function get_numChildren():Int
	{
		return mChildren.length;
	}

	/**
	 * 筛选条件部分,符合条件的加入到children中，不符合的忽略
	 * @param SgslNode
	 * @param defines
	 *
	 */
	public function filter(defines:Array<String>):Void
	{
		if (defines == null)
		{
			defines = new Array<String>();
		}

		var results:Array<LeafNode> = new Array<LeafNode>();

		var child:LeafNode;
		var predefine:PredefineNode;
		var cLength:Int = mChildren.length;
		for (i in 0...cLength)
		{
			child = mChildren[i];

			//预定义条件
			if (Std.is(child,PredefineNode))
			{
				predefine = cast(child, PredefineNode);
				//符合条件则替换掉，否则忽略
				if (predefine.isMatch(defines))
				{
					var subList:Array<LeafNode> = predefine.getMatchChildren(defines);
					if (subList != null && subList.length > 0)
					{
						results = results.concat(subList);
					}
				}
			}
			else
			{
				//在自身内部filter
				if (Std.is(child,SgslNode))
				{
					cast(child, SgslNode).filter(defines);
				}
				results.push(child);
			}
		}

		mChildren = results;
	}

	/**
	 * 主要用于替换自定义变量的名称
	 */
	override public function renameLeafNode(map:StringMap<String>):Void
	{
		var length:Int = mChildren.length;
		for (i in 0...length)
		{
			mChildren[i].renameLeafNode(map);
		}
	}

	/**
	 * 如果LeafNode的名字在map中存在，则替换掉此LeafNode
	 * @param map
	 *
	 */
	override public function replaceLeafNode(paramMap:StringMap<LeafNode>):Void
	{
		var child:LeafNode;
		for (i in 0...mChildren.length)
		{
			child = mChildren[i];
			//child.replaceLeafNode(paramMap);
			
			var leafNode:AtomNode = Std.instance(paramMap.get(child.name),AtomNode);
			if (leafNode != null)
			{
				if (Std.is(leafNode, ConstantNode))
				{
					mChildren[i] = leafNode.clone();
				}
				else
				{
					child.replaceLeafNode(paramMap);
				}
			}
			else
			{
				child.replaceLeafNode(paramMap);
			}
		}
	}

	override public function clone():LeafNode
	{
		var node:SgslNode = new SgslNode(this.type,name);
		cloneChildren(node);
		return node;
	}

	private function cloneChildren(parent:SgslNode):Void
	{
		var m:LeafNode;
		for (i in 0...mChildren.length)
		{
			m = mChildren[i];
			parent.addChild(m.clone());
		}
	}

	override public function toString(level:Int = 0):String
	{
		var result:String = "";

		result = getSelfString(level) + getChildrenString(level);

		return result;
	}

	private function getSelfString(level:Int):String
	{
		var result:String = getSpace(level) + name;

		return result;
	}

	private function getChildrenString(level:Int):String
	{
		level++;
		var result:String = "";
		var m:LeafNode;
		for (i in 0...mChildren.length)
		{
			m = mChildren[i];
			result += m.toString(level);
		}
		return result;
	}
}

