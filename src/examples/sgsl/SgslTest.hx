package examples.sgsl;
import de.polygonal.core.util.Assert;
import flash.Lib;
import flash.Vector;
import haxe.ds.StringMap;
import org.angle3d.app.SimpleApplication;
import org.angle3d.manager.ShaderManager;
import org.angle3d.material.sgsl.DataType;
import org.angle3d.material.sgsl.node.AssignNode;
import org.angle3d.material.sgsl.node.AtomNode;
import org.angle3d.material.sgsl.node.FunctionCallNode;
import org.angle3d.material.sgsl.node.FunctionNode;
import org.angle3d.material.sgsl.node.LeafNode;
import org.angle3d.material.sgsl.node.NodeType;
import org.angle3d.material.sgsl.node.OpNode;
import org.angle3d.material.sgsl.node.reg.RegNode;
import org.angle3d.material.sgsl.node.SgslNode;
import org.angle3d.material.sgsl.parser.SgslParser2;
import org.angle3d.material.sgsl.SgslData;
import org.angle3d.material.sgsl.SgslOptimizer;
import org.angle3d.material.shader.ShaderProfile;
import org.angle3d.material.shader.ShaderType;
import org.angle3d.utils.FileUtil;

class SgslTest extends SimpleApplication
{
	public static function main()
	{       
        Lib.current.addChild(new SgslTest());
    }

	public function new() 
	{
		super();
		
	}
	
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);
		
		var sources:Vector<String> = new Vector<String>();
		sources[0] = getVertexSource();
		sources[1] = getFragmentSource();

		//var shader:Shader = ShaderManager.instance.registerShader("test", sources);

		var time:Int = Lib.getTimer();
		var parser:SgslParser2 = new SgslParser2();
		var node:SgslNode = parser.exec(FileUtil.getFileContent("shader/wireframe_test.vs"));
		trace(Lib.getTimer() - time);
		trace(node.toString());
		
		trace("------optimize------");
		var sgslData:SgslData = new SgslData(ShaderProfile.STANDARD, ShaderType.VERTEX);
		var newNode:SgslNode = optimize(sgslData,node,[]);
		trace(newNode);
		
		//var newFuncNode:FunctionNode = new FunctionNode("test_new",DataType.VOID);
		//node.flat(newFuncNode);
		//
		//trace(newFuncNode);
	}
	
	private function optimize(data:SgslData,node:SgslNode,defines:Array<String>):SgslNode
	{
		//条件过滤
		node.filter(defines);

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

		//复制系统自定义函数到字典中
		var systemMap:StringMap<FunctionNode> = ShaderManager.instance.getCustomFunctionMap();
		var keys = systemMap.keys();
		for (key in keys)
		{
			customFunctionMap.set(key, systemMap.get(key));
		}

		//替换main中自定义函数
		mainFunction.replaceCustomFunction(customFunctionMap);
		
		return node;
	}
	
	//private function flatNode(node:SgslNode):Void
	//{
		//var newNode:SgslNode = new SgslNode(NodeType.PROGRAM,"newProgram");
		//for (i in 0...node.children.length)
		//{
			//var child:LeafNode = node.children[i];
			//if (child.type == NodeType.ASSIGNMENT)
			//{
				//var list:Array<LeafNode> = [];
				//child.flat(list);
				//for (j in 0...list.length)
				//{
					//newNode.addChild(list[j]);
				//}
			//}
			//else
			//{
				//newNode.addChild(child);
			//}
		//}
		//
		//trace("After Flat-----------------");
		//trace(newNode.toString());
	//}
	
	private function flatTest():Void
	{
		// t_pos = normal(cross(t_end-t_start,t_vec));
		
		// t_es = t_end - tstart;
		// t_cr = cross(t_es,t_vec);
		// t_n = normal(t_cr);
		// t_pos = t_n;
		
		var assignNode:AssignNode = new AssignNode();
		
		var destNode:AtomNode = new AtomNode("t_pos");
		
		assignNode.addChild(destNode);
		
		var startNode:AtomNode = new AtomNode("t_start");
		var endNode:AtomNode = new AtomNode("t_end");
		
		var node1:OpNode = new OpNode(NodeType.SUBTRACT,"-");
		node1.addChild(endNode);
		node1.addChild(startNode);
		
		var vecNode:AtomNode = new AtomNode("t_vec");
		var node2:FunctionCallNode = new FunctionCallNode("cross");
		node2.addChild(node1);
		node2.addChild(vecNode);
		
		var node3:FunctionCallNode = new FunctionCallNode("normal");
		node3.addChild(node2);
	
		assignNode.addChild(node3);
		
		var newFuncNode:FunctionNode = new FunctionNode("test_new",DataType.VOID);
		assignNode.flat(newFuncNode);
		
		trace(newFuncNode);
	}
	
	private function getVertexSource():String
	{
		return FileUtil.getFileContent("shader/lighting.vs");
	}

	private function getFragmentSource():String
	{
		return FileUtil.getFileContent("shader/lighting.fs");
	}
	
}