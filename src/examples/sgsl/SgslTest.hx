package examples.sgsl;
import flash.Lib;
import flash.Vector;
import org.angle3d.app.SimpleApplication;
import org.angle3d.manager.ShaderManager;
import org.angle3d.material.sgsl.OpCodeManager;
import org.angle3d.material.sgsl.parser.SgslParser;
import org.angle3d.material.sgsl.SgslCompiler;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.shader.ShaderProfile;
import org.angle3d.utils.FileUtil;

class SgslTest extends SimpleApplication
{
	public static function main() {       
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

		var shader:Shader = ShaderManager.instance.registerShader("test", sources);
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