package org.angle3d.material.sgsl.node;
import haxe.ds.StringMap;
import org.angle3d.manager.ShaderManager;
import org.angle3d.material.sgsl.node.reg.RegNode;

class ProgramNode extends SgslNode
{
	public var regMap:StringMap<RegNode>;

	public function new() 
	{
		super(NodeType.PROGRAM);
		
		regMap = new StringMap<RegNode>();
	}
	
	override public function clone():LeafNode
	{
		var node:ProgramNode = new ProgramNode();
		cloneChildren(node);
		
		var keys = regMap.keys();
		for (key in keys)
		{
			node.addReg(cast regMap.get(key).clone());
		}
		
		return node;
	}
	
	public function flatProgram():Void
	{
		for (i in 0...mChildren.length)
		{
			cast(mChildren[i],FunctionNode).flatFunction(this);
		}
	}
	
	public function addReg(regNode:RegNode):Void
	{
		regMap.set(regNode.name, regNode);
	}
	
	public function getRegNode(name:String):RegNode
	{
		return regMap.get(name);
	}
	
	public function getFunction(nameWithParamType:String):FunctionNode
	{
		for (i in 0...mChildren.length)
		{
			if (mChildren[i].type == NodeType.FUNCTION && cast(mChildren[i],FunctionNode).getNameWithParamType() == nameWithParamType)
			{
				return cast mChildren[i];
			}
		}
		return null;
	}
	
	
	public function getFunctionDataType(funcName:String, paramTypes:Array<String>):String
	{
		var nameWithParamType:String = funcName;
		if (paramTypes.length > 0)
		{
			for (i in 0...paramTypes.length)
			{
				nameWithParamType += "_" + paramTypes[i];
			}
		}
		
		if (ShaderManager.instance.hasFunction(nameWithParamType))
		{
			return ShaderManager.instance.getFunctionDataType(nameWithParamType);
		}
		
		var node:FunctionNode = getFunction(nameWithParamType);
		if (node != null)
			return node.dataType;
		
		return null;
	}
	
}