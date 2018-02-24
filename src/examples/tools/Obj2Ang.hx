package examples.tools;



import flash.events.Event;
import flash.events.MouseEvent;
import flash.net.FileFilter;
import flash.net.FileReference;
import flash.utils.ByteArray;
import haxe.Timer;
import angle3d.io.parser.ang.AngWriter;
import angle3d.io.parser.obj.ObjParser;
import angle3d.scene.mesh.BufferType;
import angle3d.scene.mesh.Mesh;
import angle3d.utils.TangentBinormalGenerator;


class Obj2Ang extends BasicExample
{
	static function main() 
	{
		flash.Lib.current.addChild(new Obj2Ang());
	}
	
	private var _byteArray:ByteArray;
	private var _fileName:String;
	private var _objParser:ObjParser;
	private var meshes:Array<Mesh>;
	public function new()
	{
		super();
	}
	
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);
		
		 meshes= new Array<Mesh>();
		
		_objParser = new ObjParser();
		_objParser.addEventListener(Event.COMPLETE, onParseComplete);

		showMsg("点击加载模型文件", "center");
		stage.addEventListener(MouseEvent.CLICK, onClick);
	}
	
	private function onParseComplete(event:Event):Void
	{
		var needTangentMeshes:Array<Mesh> = new Array<Mesh>();
		
		var meshInfos:Array<Dynamic> = _objParser.getMeshes();
		
		meshes.length = 0;
		for (i in 0...meshInfos.length)
		{
			var mesh:Mesh = meshInfos[i].mesh;
			meshes.push(mesh);
			if (mesh.getVertexBuffer(BufferType.NORMAL) != null && mesh.getVertexBuffer(BufferType.TANGENT) == null)
			{
				needTangentMeshes.push(mesh);
			}
		}

		if (needTangentMeshes.length > 0)
		{
			var totalCount:Int = needTangentMeshes.length;
			showMsg("生成Tangent中0/"+totalCount+"...", "center");
			
			var timer:Timer = new Timer(100);
			timer.run = function():Void
			{
				var g:Mesh = needTangentMeshes.pop();
				TangentBinormalGenerator.generateMesh(g);
				if (needTangentMeshes.length == 0)
				{
					timer.stop();
					writeMeshData();
				}
				else
				{
					showMsg("生成Tangent中" + (totalCount - needTangentMeshes.length) + "/" + totalCount + "...", "center");
				}
			}
		}
		else
		{
			writeMeshData();
		}
	}
	
	private function writeMeshData():Void
	{
		var write:AngWriter = new AngWriter();
		_byteArray = write.writeMeshes(meshes);
		
		showMsg("点击下载Ang模型文件", "center");
		
		stage.addEventListener(MouseEvent.CLICK, onSaveClick);
	}
	
	private function onClick(event:MouseEvent):Void
	{
		stage.removeEventListener(MouseEvent.CLICK, onClick);
		var file:FileReference = new FileReference();
		file.addEventListener(Event.SELECT, onSelectFile);
		file.addEventListener(Event.COMPLETE, completeHandler);
		file.addEventListener(Event.CANCEL, cancelHandler);
		file.browse([new FileFilter("*.obj", "*.obj")]);
	}
	
	private function cancelHandler(event:Event):Void 
	{
		stage.addEventListener(MouseEvent.CLICK, onClick); 
	}
	
	private function completeHandler(event:Event):Void 
	{
		var file:FileReference = Std.instance(event.target, FileReference);
		
		var data:ByteArray = file.data;
		data.position = 0;
		var obj:String = data.readUTFBytes(data.length);
		
		_objParser.asyncParse(obj);
		
		showMsg("解析模型文件中...", "center");
	}
	
	private function onSelectFile(event:Event):Void
	{
		var file:FileReference = Std.instance(event.target, FileReference);
		
		_fileName = file.name;
		
		file.load();
	}
	
	private function onSaveClick(event:MouseEvent):Void
	{
		stage.removeEventListener(MouseEvent.CLICK, onSaveClick);
		var file:FileReference = new FileReference();
		file.save(_byteArray, _fileName.substring(0, _fileName.indexOf(".")) + ".ang");
		
		showMsg("点击加载模型文件", "center");
		stage.addEventListener(MouseEvent.CLICK, onClick);
	}
}
