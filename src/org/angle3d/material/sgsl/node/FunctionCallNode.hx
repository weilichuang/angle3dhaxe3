package org.angle3d.material.sgsl.node;

import haxe.ds.StringMap;
import org.angle3d.material.sgsl.node.reg.RegNode;
import org.angle3d.material.sgsl.utils.SgslUtils;

class FunctionCallNode extends SgslNode
{
	public function new(name:String)
	{
		super(NodeType.FUNCTION_CALL,name);
	}
	
	override public function checkDataType(programNode:ProgramNode, paramMap:StringMap<String> = null):Void
	{
		super.checkDataType(programNode, paramMap);
		
		var params:Array<String> = [];
		for (i in 0...mChildren.length)
		{
			params[i] = mChildren[i].dataType;
		}
		
		this._dataType = programNode.getFunctionDataType(this.name, params);
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
		node.mask = mask;
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
		
		if (parent != null && Std.is(parent, FunctionNode))
		{
			result = getSpace(level);
		}

		result += name + "(" + getChildrenString(level) + ")";
		
		if (parent != null && Std.is(parent, FunctionNode))
		{
			result += ";\n";
		}

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

