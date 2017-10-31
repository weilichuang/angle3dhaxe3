package org.angle3d.material.sgsl.node;

import org.angle3d.material.sgsl.node.reg.TextureReg;
import haxe.ds.StringMap;
import org.angle3d.manager.ShaderManager;
import org.angle3d.material.sgsl.node.reg.RegNode;
import org.angle3d.material.sgsl.SgslData;

class ProgramNode extends SgslNode
{
	public var version:Int = 1;
	
	private var defineMap:FastStringMap<Float>;
	private var defines:Vector<String>;
	
	private var formatMap:FastStringMap<String>;
	
	public var regMap:FastStringMap<RegNode>;
	private var regNodes:Array<RegNode>;
	private var textureNodes:Array<TextureReg>;
	public function new() 
	{
		super(NodeType.PROGRAM);
		
		formatMap = new FastStringMap<String>();
		defineMap = new FastStringMap<Float>();
		defines = new Vector<String>();
		regMap = new FastStringMap<RegNode>();
		regNodes = [];
		textureNodes = [];
	}
	
	public function addTextureFormat(name:String, value:String):Void
	{
		formatMap.set(name, value);
	}
	
	public function hasTextureFormat(name:String):Bool
	{
		return formatMap.exists(name);
	}
	
	public inline function getTextureFormat(name:String):String
	{
		return formatMap.get(name);
	}
	
	public function addDefine(name:String, value:Float):Void
	{
		defineMap.set(name, value);
		if(value > 0)
			defines.push(name);
	}
	
	public function hasDefine(name:String):Bool
	{
		return defineMap.exists(name);
	}
	
	public inline function getDefines():Vector<String>
	{
		return defines;
	}
	
	public inline function getDefineValue(name:String):Float
	{
		return defineMap.get(name);
	}
	
	override public function clone(result:LeafNode = null):LeafNode
	{
		if (result == null)
			result = new ProgramNode();
			
		var node:ProgramNode = cast super.clone(result);
		
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
		#if debug
		if (regMap.exists(regNode.name))
		{
			throw '${regNode.name} 不能重复定义';
		}
		#end
		regMap.set(regNode.name, regNode);
		regNodes.push(regNode);
		if (Std.is(regNode, TextureReg))
		{
			textureNodes.push(cast regNode);
		}
	}
	
	public function getRegNode(name:String):RegNode
	{
		return regMap.get(name);
	}
	
	public function getTextureNodes():Array<TextureReg>
	{
		return textureNodes;
	}
	
	public function toSgslData(data:SgslData):Void
	{
		for (i in 0...regNodes.length)
		{
			data.addReg(cast regNodes[i].clone());
		}
		
		var mainFunction:FunctionNode = getFunction("main");
		var children:Vector<LeafNode> = mainFunction.children;
		for (i in 0...children.length)
		{
			var child:SgslNode = cast children[i];
			data.addNode(child.toAgalNode());
		}
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
	
	public function hasFunction(funcName:String, paramTypes:Array<String>):Bool
	{
		return getFunction(paramTypes.length > 0 ? funcName + "_" + paramTypes : funcName) != null;
	}
	
	public function getFunctionDataType(funcName:String, paramTypes:Array<String>):String
	{
		var paramName:String = paramTypes.join("_");

		if (ShaderManager.instance.hasFunction(funcName,paramName))
		{
			return ShaderManager.instance.getFunctionDataType(funcName,paramName);
		}
		
		var node:FunctionNode = getFunction(paramName.length > 0 ? funcName + "_" + paramName : funcName);
		if (node != null)
			return node.dataType;
		
		return null;
	}
	
}