package org.angle3d.material.sgsl.node;

import haxe.ds.StringMap;

class FunctionCallNode extends SgslNode
{
	public function new(name:String)
	{
		super(NodeType.FUNCTION_CALL,name);
	}
	
	//返回值类型
	override public function getDataType():String
	{
		return "";
	}
	
	public function getNameWithParamType():String
	{
		var result:String = this.name;
		for (i in 0...mChildren.length)
		{
			result += "_" + mChildren[i].getDataType();
		}
		return "";
	}

	/**
	 * 克隆一个FunctionNode,并替换参数
	 * 只有自定义函数才能调用此方法
	 */
	public function cloneCustomFunction(functionMap:StringMap<FunctionNode>):FunctionNode
	{
		var functionNode:FunctionNode = Std.instance(functionMap.get(this.name).clone(), FunctionNode);
		if (functionNode.needReplace)
		{
			functionNode.replaceCustomFunction(functionMap);
		}

		var params:Array<ParameterNode> = functionNode.getParams();
		var length:Int = params.length;
		var paramMap:StringMap<LeafNode> = new StringMap<LeafNode>();
		for (i in 0...length)
		{
			var param:ParameterNode = params[i];
			paramMap.set(param.name, children[i]);
		}

		functionNode.replaceLeafNode(paramMap);

		return functionNode;
	}

	override public function clone():LeafNode
	{
		var node:FunctionCallNode = new FunctionCallNode(name);
		cloneChildren(node);
		return node;
	}

	/**
	 * only for debug
	 * @param	level
	 * @return
	 */
	override public function toString(level:Int = 0):String
	{
		var result:String = "";

		result = name + "(" + getChildrenString(level) + ")";

		return result;
	}

	/**
	 * only for debug
	 * @param	level
	 * @return
	 */
	override private function getChildrenString(level:Int):String
	{
		var results:Array<String> = [];
		var m:LeafNode;
		var length:Int = mChildren.length;
		for (i in 0...length)
		{
			m = mChildren[i];
			results.push(m.toString(level));
		}
		return results.join(", ");
	}
}

