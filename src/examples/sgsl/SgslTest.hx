package examples.sgsl;

import flash.text.TextField;

import angle3d.app.SimpleApplication;
import angle3d.manager.ShaderManager;
import angle3d.material.sgsl.node.ProgramNode;
import angle3d.material.sgsl.parser.SgslParser;
import angle3d.material.sgsl.SgslData;
import angle3d.material.sgsl.SgslOptimizer;
import angle3d.shader.DefineList;
import angle3d.shader.ShaderKey;

import angle3d.shader.ShaderType;
import angle3d.shader.VarType;
import angle3d.math.Color;
import angle3d.math.Vector4f;
import angle3d.utils.FileUtil;

class SgslTest extends BasicExample
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
		
		var sources:Array<String> = new Array<String>();
		sources[0] = getVertexSource();
		sources[1] = getFragmentSource();

		var time:Int = Lib.getTimer();
		var parser:SgslParser = new SgslParser();
		//var node:ProgramNode = parser.exec(FileUtil.getFileContent("../assets/shader/lighting.vs"));
		textField.text += "parse time :" + (Lib.getTimer() - time) + "\n";
		textField.text += "parse Code:\n";
		//textField.text += node.toString();
		
		textField.text += "------optimize------\n";
		time = Lib.getTimer();
		var optimizer:SgslOptimizer = new SgslOptimizer();
		var sgslData:SgslData = new SgslData(ShaderProfile.STANDARD, ShaderType.VERTEX);
		//optimizer.exec(sgslData, node, ["VERTEX_LIGHTING"]);
		
		textField.text += "optimize time :" + (Lib.getTimer() - time) + "\n";
		textField.text += "optimize Code:\n";
		//textField.text += node.toString();
		
		var defineList = new DefineList();
		defineList.set("USE_SKINNING", VarType.BOOL, true);
		ShaderManager.instance.registerShader(new ShaderKey(defineList, "teture", "texture"), FileUtil.getFileContent("../assets/shader/lighting.vs"),
		FileUtil.getFileContent("../assets/shader/lighting.fs"));
	}
	
	private function getVertexSource():String
	{
		return FileUtil.getFileContent("../assets/shader/lighting.vs");
	}

	private function getFragmentSource():String
	{
		return FileUtil.getFileContent("../assets/shader/lighting.fs");
	}
	
}