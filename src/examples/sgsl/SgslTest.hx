package examples.sgsl;
import flash.Lib;
import flash.text.TextField;
import flash.Vector;
import org.angle3d.app.SimpleApplication;
import org.angle3d.material.sgsl.node.ProgramNode;
import org.angle3d.material.sgsl.parser.SgslParser;
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

		var time:Int = Lib.getTimer();
		var parser:SgslParser = new SgslParser();
		var node:ProgramNode = parser.exec(FileUtil.getFileContent("shader/lighting.vs"));
		textField.text += "parse time :" + (Lib.getTimer() - time) + "\n";
		textField.text += "parse Code:\n";
		textField.text += node.toString();
		
		textField.text += "------optimize------\n";
		time = Lib.getTimer();
		var optimizer:SgslOptimizer = new SgslOptimizer();
		var sgslData:SgslData = new SgslData(ShaderProfile.STANDARD, ShaderType.VERTEX);
		optimizer.exec(sgslData, node, ["MATERIAL_COLORS"]);
		
		textField.text += "optimize time :" + (Lib.getTimer() - time) + "\n";
		textField.text += "optimize Code:\n";
		textField.text += node.toString();
	}
	
	private function getVertexSource():String
	{
		return FileUtil.getFileContent("../../assets/shader/lighting.vs");
	}

	private function getFragmentSource():String
	{
		return FileUtil.getFileContent("../../assets/shader/lighting.fs");
	}
	
}