package examples.sgsl;
import de.polygonal.core.util.Assert;
import flash.Lib;
import flash.text.TextField;
import flash.Vector;
import haxe.ds.StringMap;
import org.angle3d.app.SimpleApplication;
import org.angle3d.manager.ShaderManager;
import org.angle3d.material.sgsl.node.FunctionNode;
import org.angle3d.material.sgsl.node.LeafNode;
import org.angle3d.material.sgsl.node.ProgramNode;
import org.angle3d.material.sgsl.node.SgslNode;
import org.angle3d.material.sgsl.parser.SgslParser2;
import org.angle3d.material.sgsl.SgslData;
import org.angle3d.material.shader.ShaderProfile;
import org.angle3d.material.shader.ShaderType;
import org.angle3d.utils.FileUtil;

class SgslTest extends SimpleApplication
{
	public static function main()
	{       
        Lib.current.addChild(new SgslTest());
    }

	private var textField:TextField;
	
	public function new() 
	{
		super();
		
	}
	
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);
		
		textField = new TextField();
		textField.textColor = 0x00FF00;
		textField.width = width;
		textField.height = height;
		stage.addChild(textField);
		
		var sources:Vector<String> = new Vector<String>();
		sources[0] = getVertexSource();
		sources[1] = getFragmentSource();

		//var shader:Shader = ShaderManager.instance.registerShader("test", sources);

		var time:Int = Lib.getTimer();
		var parser:SgslParser2 = new SgslParser2();
		var node:ProgramNode = parser.exec(FileUtil.getFileContent("shader/lighting.vs"));
		textField.text += "parse time :" + (Lib.getTimer() - time) + "\n";
		textField.text += "parse Code:\n";
		textField.text += node.toString();
		
		textField.text += "------optimize------\n";
		time = Lib.getTimer();
		var sgslData:SgslData = new SgslData(ShaderProfile.STANDARD, ShaderType.VERTEX);
		var newNode:ProgramNode = optimize(sgslData, node, ["MATERIAL_COLORS"]);
		textField.text += "optimize time :" + (Lib.getTimer() - time) + "\n";
		textField.text += "optimize Code:\n";
		textField.text += newNode.toString();
	}
	
	private function optimize(data:SgslData,node:ProgramNode,defines:Array<String>):ProgramNode
	{
		var cNode:ProgramNode = cast node.clone();
		
		//复制系统自定义函数到字典中
		var systemMap:StringMap<FunctionNode> = ShaderManager.instance.getCustomFunctionMap();
		var keys = systemMap.keys();
		for (key in keys)
		{
			cNode.addChild(systemMap.get(key).clone());
		}
		
		//预定义过滤
		cNode.filter(defines);
		
		var child:LeafNode;
		var children:Array<LeafNode> = cNode.children;
		var cLength:Int = children.length;
		for (i in 0...cLength)
		{
			child = children[i];
			if (Std.is(child,FunctionNode))
			{
				var func:FunctionNode = cast child;
				func.renameTempVar();
			}
		}
		
		cNode.gatherRegNode(cNode);
		
		cNode.checkDataType(cNode);
		
		cNode.flatProgram();
		
		cNode.opToFunctionCall();
		
		replaceCustomFunction(data, cNode);
		
		return cNode;
	}
	
	private function replaceCustomFunction(data:SgslData, node:SgslNode):Void
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

		//替换main中自定义函数
		mainFunction.replaceCustomFunction(customFunctionMap);
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