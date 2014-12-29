package examples.sgsl;
import flash.Lib;
import flash.Vector;
import org.angle3d.app.SimpleApplication;
import org.angle3d.manager.ShaderManager;
import org.angle3d.material.sgsl.node.agal.AgalLine;
import org.angle3d.material.sgsl.node.agal.FlatInfo;
import org.angle3d.material.sgsl.node.AssignNode;
import org.angle3d.material.sgsl.node.AtomNode;
import org.angle3d.material.sgsl.node.BranchNode;
import org.angle3d.material.sgsl.node.FunctionCallNode;
import org.angle3d.material.sgsl.node.LeafNode;
import org.angle3d.material.sgsl.node.OpNode;
import org.angle3d.material.sgsl.OpCodeManager;
import org.angle3d.material.sgsl.parser.SgslParser;
import org.angle3d.material.sgsl.parser.SgslParser2;
import org.angle3d.material.sgsl.parser.Token;
import org.angle3d.material.sgsl.parser.Tokenizer2;
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

		//var shader:Shader = ShaderManager.instance.registerShader("test", sources);

		var time:Int = Lib.getTimer();
		var parser:SgslParser2 = new SgslParser2();
		var node:BranchNode = parser.exec(FileUtil.getFileContent("shader/wireframe_test.vs"));
		trace(Lib.getTimer() - time);
		trace(node.toString());
		
		var assignNode:AssignNode = new AssignNode();
		
		var destNode:AtomNode = new AtomNode("t_pos");
		
		assignNode.destNode = destNode;
		
		var node1:OpNode = new OpNode("-");
		
		var startNode:AtomNode = new AtomNode("t_start");
		startNode.mask = "xyz";
		
		var endNode:AtomNode = new AtomNode("t_end");
		endNode.mask = "xyz";
		
		node1.leftNode = endNode;
		node1.rightNode = startNode;
		
		var vecNode:AtomNode = new AtomNode("t_vec");
		endNode.mask = "xyz";
		
		var node2:FunctionCallNode = new FunctionCallNode("cross");
		node2.addChild(node1);
		node2.addChild(vecNode);
		
		var node3:FunctionCallNode = new FunctionCallNode("normal");
		node3.addChild(node2);
		
		assignNode.sourceNode = node3;
		
		assignNode.calDepth(0);
		
		var lines:Array<LeafNode> = [];
		assignNode.flat(lines);
		
		//lines.sort(function(a:FlatInfo, b:FlatInfo):Int
		//{
			//return b.depth - a.depth;
		//});
		
		trace(lines);
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