package org.angle3d.material.sgsl;
import de.polygonal.core.util.Assert;
import haxe.ds.StringMap;
import org.angle3d.manager.ShaderManager;
import org.angle3d.material.sgsl.node.FunctionNode;
import org.angle3d.material.sgsl.node.LeafNode;
import org.angle3d.material.sgsl.node.NodeType;
import org.angle3d.material.sgsl.node.ProgramNode;

/**
 * ...
 * @author weilichuang
 */
class SgslOptimizer
{

	public function new() 
	{
		
	}
	
	
	public function exec(data:SgslData, tree:ProgramNode, defines:Array<String>):Void
	{
		//预定义过滤
		tree.filter(defines);
		
		var children:Array<LeafNode> = tree.children;
		for (i in 0...children.length)
		{
			var child:LeafNode = children[i];
			if (child.type == NodeType.FUNCTION)
			{
				cast(child,FunctionNode).renameTempVar();
			}
		}
		
		tree.gatherRegNode(tree);
		
		tree.checkDataType(tree);
		
		tree.flatProgram();
		
		tree.opToFunctionCall();
		
		replaceCustomFunction(data, tree);
		
		tree.toSgslData(data);
		
		data.build();
	}
	
	private function replaceCustomFunction(data:SgslData, node:ProgramNode):Void
	{
		//替换自定义表达式
		var customFunctionMap:StringMap<FunctionNode> = new StringMap<FunctionNode>();

		var mainFunction:FunctionNode = null;

		//保存所有自定义函数
		var child:LeafNode;
		var children:Array<LeafNode> = node.children;
		var cLength:Int = children.length;
		for (i in 0...cLength)
		{
			child = children[i];
			if (Std.is(child,FunctionNode))
			{
				var func:FunctionNode = cast child;
				if (func.name == "main")
				{
					mainFunction = func;
				}
				else
				{
					Assert.assert(!customFunctionMap.exists(func.getNameWithParamType()),"自定义函数" + func.getNameWithParamType() + "定义重复");
					customFunctionMap.set(func.getNameWithParamType(), func);
				}
			}
			else
			{
				data.addReg(cast child);
			}
		}
		
		
		var systemMap:StringMap<FunctionNode> = ShaderManager.instance.getCustomFunctionMap();
		var keys = systemMap.keys();
		for (key in keys)
		{
			customFunctionMap.set(key, systemMap.get(key));
		}

		//替换main中自定义函数
		mainFunction.replaceCustomFunction(node,customFunctionMap);
	}
}