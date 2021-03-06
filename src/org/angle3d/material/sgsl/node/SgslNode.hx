package org.angle3d.material.sgsl.node;

import flash.display3D.Program3D;
import flash.Vector;
import org.angle3d.ds.FastStringMap;
import org.angle3d.material.sgsl.node.reg.RegFactory;
import org.angle3d.material.sgsl.node.reg.RegNode;
import org.angle3d.material.sgsl.utils.SgslUtils;

using org.angle3d.utils.ArrayUtil;

class SgslNode extends LeafNode
{
	public var children(get, null):Vector<LeafNode>;
	
	public var numChildren(get, null):Int;
	
	private var mChildren:Vector<LeafNode>;
	
	public function new(type:Int, name:String = "")
	{
		super(name);

		this.type = type;
		
		mChildren = new Vector<LeafNode>();
	}
	
	public function toAgalNode():AgalNode
	{
		return null;
	}

	override public function checkDataType(programNode:ProgramNode, paramMap:FastStringMap<String> = null):Void
	{
		for (i in 0...mChildren.length)
		{
			mChildren[i].checkDataType(programNode, paramMap);
		}
		
		if (mChildren.length == 1)
		{
			_dataType = mChildren[0].dataType;
		}
	}
	
	public function gatherRegNode(programNode:ProgramNode):Void
	{
		var i:Int = 0;
		while(i < children.length)
		{
			var child:LeafNode = children[i];
			if (child.type == NodeType.SHADERVAR)
			{
				programNode.addReg(cast child);
				this.removeChild(child);
				i--;
			}
			else if(Std.is(child,SgslNode))
			{
				cast(child, SgslNode).gatherRegNode(programNode);
			}
			i++;
		}
	}
	
	public function opToFunctionCall():Void
	{
		for (i in 0...mChildren.length)
		{
			var child:LeafNode = mChildren[i];
			if (Std.is(child, OpNode))
			{
				var callNode:FunctionCallNode = cast(child, OpNode).toFunctionCallNode();
				callNode.parent = this;
				mChildren[i] = callNode;
			}
			else if (Std.is(child, SgslNode))
			{
				cast(child, SgslNode).opToFunctionCall();
			}
		}
	}
	
	//t_pos = normal(cross(t_start,t_end-t_start))
	//t_pos = -t_start
	//t_pos = t_start*t_end;
	override public function flat(programNode:ProgramNode, functionNode:FunctionNode, result:Vector<LeafNode>):Void
	{
		for (i in 0...mChildren.length)
		{
			var child:LeafNode = mChildren[i];
			if (Std.is(child, SgslNode))
			{
				child.flat(programNode, functionNode, result);
				
				if (Std.is(child, OpNode) || Std.is(child, FunctionCallNode))
				{	
					var tmpVar:RegNode = RegFactory.create(SgslUtils.getTempName("t_local"), RegType.TEMP, child.dataType);
					programNode.addReg(tmpVar);
				
					var destNode:AtomNode = new AtomNode(tmpVar.name);
					destNode.dataType = child.dataType;
					
					var newAssignNode:AssignNode = new AssignNode();
					newAssignNode.addChild(destNode);
					newAssignNode.addChild(child.clone());
					
					var newNode:LeafNode = destNode.clone();
					newNode.mask = child.mask;
					setChildAt(newNode, i);

					result.push(newAssignNode);
				}
			}
		}
		
		if (this.parent == functionNode)
		{
			result.push(this);
		}
	}
	
	public function removeAllChildren():Void
	{
		for (i in 0...mChildren.length)
		{
			mChildren[i].parent = null;
		}
		untyped mChildren.length = 0;
	}

	public function addChild(node:LeafNode):Void
	{
		node.parent = this;
		mChildren.push(node);
	}

	public function removeChild(node:LeafNode):Void
	{
		var index:Int = mChildren.indexOf(node);
		if (index != -1)
		{
			mChildren.splice(index, 1);
			node.parent = null;
		}
	}
	
	public function setChildAt(child:LeafNode, index:Int):Void
	{
		var oldNode:LeafNode = mChildren[index];
		if (oldNode != null)
		{
			oldNode.parent = null;
		}
		
		child.parent = this;
		mChildren[index] = child;
	}

	public function addChildren(list:Vector<LeafNode>):Void
	{
		var count:Int = list.length;
		for (i in 0...count)
		{
			addChild(list[i]);
		}
	}

	
	private inline function get_children():Vector<LeafNode>
	{
		return mChildren;
	}

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
	public function filter(defines:Vector<String>):Void
	{
		if (defines == null)
		{
			defines = new Vector<String>();
		}

		var results:Vector<LeafNode> = new Vector<LeafNode>();

		var child:LeafNode;
		var predefine:PredefineNode;
		var cLength:Int = mChildren.length;
		for (i in 0...cLength)
		{
			child = mChildren[i];

			//预定义条件
			if (child.type == NodeType.PREPROCESOR)
			{
				predefine = cast(child, PredefineNode);
				//符合条件则替换掉，否则忽略
				if (predefine.isMatch(defines))
				{
					var subList:Vector<LeafNode> = predefine.getMatchChildren(defines);
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
		
		this.removeAllChildren();
		for (i in 0...results.length)
		{
			this.addChild(results[i]);
		}
	}

	/**
	 * 主要用于替换自定义变量的名称
	 */
	override public function renameLeafNode(map:FastStringMap<String>):Void
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
	override public function replaceParamNode(paramMap:FastStringMap<LeafNode>):Void
	{
		for (i in 0...mChildren.length)
		{
			var child:LeafNode = mChildren[i];
			
			//这里有点问题，需要理清楚
			var paramNode:LeafNode = paramMap.get(child.name);
			if (paramNode != null && paramNode.type == NodeType.NUMBER) 
			{
				//if (paramNode.type == NodeType.NUMBER)
				//{
					child.parent = null;
				
					mChildren[i] = paramNode.clone();
					mChildren[i].parent = this;
				//}
				//else if (paramNode.type == NodeType.ARRAYACCESS)
				//{
					//child.parent = null;
				//
					//mChildren[i] = paramNode.clone();
					//mChildren[i].parent = this;
					//
					////if (child.mask.length < mChildren[i].mask.length)
					////{
						////mChildren[i].mask = child.mask;
					////}
				//}
				//else
				//{
					//child.replaceParamNode(paramMap);
				//}
			}
			else
			{
				child.replaceParamNode(paramMap);
			}
		}
	}
	
	override public function clone(result:LeafNode = null):LeafNode
	{
		if (result == null)
			result = new SgslNode(this.type, name);
			
		super.clone(result);
		
		cloneChildren(cast result);
		
		return result;
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
		var result:String = getSpace(level);
		
		if (mask != "" && mChildren.length > 1)
		{
			result += "(" + name;
		}
		
		result += getChildrenString(level);
		
		if (mask != "")
		{
			if (mChildren.length > 1)
				result += ")." + mask;
			else
				result += "." + mask;
		}

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

