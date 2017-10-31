package examples.sgsl;
import flash.Lib;
import flash.text.TextField;

import org.angle3d.app.SimpleApplication;
import org.angle3d.manager.ShaderManager;
import org.angle3d.material.sgsl.node.ProgramNode;
import org.angle3d.material.sgsl.parser.SgslParser;
import org.angle3d.material.sgsl.SgslData;
import org.angle3d.material.sgsl.SgslOptimizer;
import org.angle3d.material.shader.DefineList;
import org.angle3d.material.shader.ShaderKey;

import org.angle3d.material.shader.ShaderType;
import org.angle3d.material.VarType;
import org.angle3d.math.Color;
import org.angle3d.math.Vector4f;
import org.angle3d.utils.FileUtil;

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