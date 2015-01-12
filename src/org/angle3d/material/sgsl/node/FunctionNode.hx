package org.angle3d.material.sgsl.node;

import haxe.ds.StringMap;
import org.angle3d.material.sgsl.node.reg.RegNode;
import org.angle3d.material.sgsl.utils.SgslUtils;

/**
 * 函数体
 */
class FunctionNode extends SgslNode
{
	/**
	 * 需要替换自定义函数
	 */
	public var needReplace(get, null):Bool;

	private var mParams:Array<ParameterNode>;

	private var mNeedReplace:Bool;

	public function new(name:String, dataType:String)
	{
		super(NodeType.FUNCTION, name);
		
		this.dataType = dataType;
		
		mParams = new Array<ParameterNode>();
		mNeedReplace = true;
	}
	
	override public function checkDataType(programNode:ProgramNode, paramMap:StringMap<String> = null):Void
	{
		if (mParams.length > 0)
		{
			paramMap = new StringMap<String>();
			for (i in 0...mParams.length)
			{
				if (paramMap.exists(mParams[i].name))
				{
					throw this.name + "have tow param with same name: " + mParams[i].name;
				}
				else
				{
					paramMap.set(mParams[i].name, mParams[i].dataType);
				}
			}
		}
		else
		{
			paramMap = null;
		}
		
		
		super.checkDataType(programNode, paramMap);
	}
	
	public function flatFunction(programNode:ProgramNode):Void
	{
		var newChildren:Array<LeafNode> = [];
		for (i in 0...mChildren.length)
		{
			var child:LeafNode = mChildren[i];
			
			child.flat(programNode, this, newChildren);
		}
		
		this.removeAllChildren();
		this.addChildren(newChildren);
	}
	
	public function getNameWithParamType():String
	{
		var result:String = this.name;
		if (this.mParams.length > 0)
		{
			for (i in 0...mParams.length)
			{
				result += "_" + mParams[i].dataType;
			}
		}
		return result;
	}

	private function get_needReplace():Bool
	{
		return mNeedReplace;
	}

	public function renameTempVar():Void
	{
		var map:StringMap<String> = new StringMap<String>();

		var child:LeafNode;
		var cLength:Int = mChildren.length;
		for (i in 0...cLength)
		{
			child = mChildren[i];
			if (Std.is(child,RegNode))
			{
				map.set(child.name, SgslUtils.getTempName(child.name + "_" + this.name));
				child.name = map.get(child.name);
			}
			else
			{
				child.renameLeafNode(map);
			}
		}
	}

	/**
	 * 替换自定义函数
	 * @param map 自定义函数Map <functionName,fcuntionNode>
	 */
	public function replaceCustomFunction(programNode:ProgramNode,functionMap:StringMap<FunctionNode>):Void
	{
		if (!mNeedReplace)
			return;

		var newChildren:Array<LeafNode> = new Array<LeafNode>();

		var child:LeafNode;
		var callNode:FunctionCallNode;
		var customFunc:FunctionNode; 
		for (i in 0...mChildren.length)
		{
			child = mChildren[i];

			if (child.type == NodeType.FUNCTION_CALL)
			{
				callNode = cast child;

				if (SgslUtils.isCustomFunctionCall(callNode))
				{
					customFunc = callNode.cloneCustomFunction(programNode, functionMap);
					
					if (customFunc.dataType != DataType.VOID)
					{
						//remove return node
						var lastNode:ReturnNode =  cast customFunc.children.pop();
						
						if (lastNode == null)
						{
							throw '${customFunc.name} function last child should be return node';
						}
					}
					else
					{
						for (i in 0...customFunc.numChildren)
						{
							if (customFunc.children[i].type == NodeType.RETURN)
							{
								throw '${customFunc.name} function should not have return';
							}
						}
					}
					
					newChildren = newChildren.concat(customFunc.children);
				}
				else
				{
					newChildren.push(child);
				}
			}
			else if (child.type == NodeType.ASSIGNMENT)
			{
				var assignNode:AssignNode = cast child;
				var returnNode:ReturnNode = null;
				if (Std.is(assignNode.children[1], FunctionCallNode))
				{
					callNode = cast assignNode.children[1];
					
					if (SgslUtils.isCustomFunctionCall(callNode))
					{
						customFunc = callNode.cloneCustomFunction(programNode, functionMap);
						
						if (customFunc.dataType == DataType.VOID)
						{
							throw '${customFunc.name} function should have return value';
						}

						returnNode = cast customFunc.children.pop();
							
						if (returnNode == null)
						{
							throw '${customFunc.name} function last child should be return node';
						}
						
						newChildren = newChildren.concat(customFunc.children);
					}
				}
				
				if (returnNode != null)
				{
					assignNode.children[1] = returnNode.children[0];
					assignNode.children[1].parent = assignNode;
				}
				
				newChildren.push(assignNode);
			}
			else
			{
				newChildren.push(child);
			}
		}

		removeAllChildren();
		
		for (i in 0...newChildren.length)
		{
			if (newChildren[i].type == NodeType.SHADERVAR)
			{
				programNode.addReg(cast newChildren[i]);
			}
			else
			{
				addChild(newChildren[i]);
			}
		}

		mNeedReplace = false;
	}

	override public function clone():LeafNode
	{
		var node:FunctionNode = new FunctionNode(this.name,this.dataType);
		node.mNeedReplace = mNeedReplace;

		cloneChildren(node);

		//clone Param
		var m:ParameterNode;
		var pLength:Int = mParams.length;
		for (i in 0...pLength)
		{
			m = mParams[i];
			node.addParam(Std.instance(m.clone(), ParameterNode));
		}

		return node;
	}

	/**
	 * 主函数
	 * @return
	 *
	 */
	public function isMain():Bool
	{
		return this.name == "main";
	}

	public function addParam(param:ParameterNode):Void
	{
		mParams.push(param);
	}

	public function getParams():Array<ParameterNode>
	{
		return mParams;
	}

	override public function toString(level:Int = 0):String
	{
		var output:String = "";

		output = getSpace(level) + dataType + " function " + name + "(";

		var paramStrings:Array<String> = [];
		var length:Int = mParams.length;
		for (i in 0...length)
		{
			paramStrings.push(mParams[i].dataType + " " + mParams[i].name);
		}

		output += paramStrings.join(",") + ")\n";

		var space:String = getSpace(level);
		output += space + "{\n";
		output += getChildrenString(level);
		output += space + "}\n";
		return output;
	}
}

