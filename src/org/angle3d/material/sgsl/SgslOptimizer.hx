package org.angle3d.material.sgsl;

import haxe.ds.StringMap;
import org.angle3d.manager.ShaderManager;
import org.angle3d.material.sgsl.node.agal.AgalNode;
import org.angle3d.material.sgsl.node.SgslNode;
import org.angle3d.material.sgsl.node.FunctionNode;
import org.angle3d.material.sgsl.node.LeafNode;
import org.angle3d.material.sgsl.node.reg.RegNode;
import de.polygonal.ds.error.Assert;


/**
 * 对生成的SgslNode进行处理
 * 具体分为两方面工作
 * 一个是根据条件替换预编译部分
 * 另外一个是替换掉自定义函数
 * @author andy
 *
 */
class SgslOptimizer
{
	public function new()
	{
	}

	/**
	 * 这里主要做几件事情
	 * 1、根据条件编译去掉不需要的代码
	 * 2、替换用户自定义函数
	 * 3、输出SgslData
	 */
	public function exec(data:SgslData, tree:SgslNode, defines:Array<String>):Void
	{
		var cloneTree:SgslNode = tree; //.clone() as SgslNode;

		//条件过滤
		cloneTree.filter(defines);

		var customFunctionMap:StringMap<FunctionNode> = new StringMap<FunctionNode>();

		var mainFunction:FunctionNode = null;

		//保存所有自定义函数
		var child:LeafNode;
		var children:Array<LeafNode> = cloneTree.children;
		var cLength:Int = children.length;
		for (i in 0...cLength)
		{
			child = children[i];
			if (Std.is(child,FunctionNode))
			{
				if (child.name == "main")
				{
					mainFunction = Std.instance(child, FunctionNode);
				}
				else
				{
					Assert.assert(!customFunctionMap.exists(child.name),"自定义函数" + child.name + "定义重复");
					customFunctionMap.set(child.name, Std.instance(child, FunctionNode));
				}
			}
			else
			{
				data.addReg(Std.instance(child, RegNode));
			}
		}

		//复制系统自定义函数到字典中
		var systemMap:StringMap<FunctionNode> = ShaderManager.instance.getCustomFunctionMap();
		var keys = systemMap.keys();
		for (key in keys)
		{
			customFunctionMap.set(key, systemMap.get(key));
		}

		//替换main中自定义函数
		mainFunction.replaceCustomFunction(customFunctionMap);

		//找出mainFunction中的RegNode
		children = mainFunction.children;
		cLength = children.length;
		for (i in 0...cLength)
		{
			child = children[i];
			if (Std.is(child, RegNode))
			{
				data.addReg(Std.instance(child, RegNode));
			}
			else
			{
				data.addNode(Std.instance(child, AgalNode));
			}
		}

		data.build();
	}
}


