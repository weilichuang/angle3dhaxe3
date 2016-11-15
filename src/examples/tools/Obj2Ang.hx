package examples.tools;

import flash.Lib;
import flash.Vector;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.net.FileFilter;
import flash.net.FileReference;
import flash.utils.ByteArray;
import org.angle3d.io.parser.ang.AngWriter;
import org.angle3d.io.parser.obj.ObjParser;
import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.utils.TangentBinormalGenerator;


class Obj2Ang extends BasicExample
{
	static function main() 
	{
		flash.Lib.current.addChild(new Obj2Ang());
	}
	
	private var _byteArray:ByteArray;
	private var _fileName:String;
	public function new()
	{
		super();
	}
	
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);

		showMsg("点击加载模型文件", "center");
		stage.addEventListener(MouseEvent.CLICK, onClick);
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
		var file:FileReference = Lib.as(event.target, FileReference);
		
		var data:ByteArray = file.data;
		data.position = 0;
		var obj:String = data.readUTFBytes(data.length);
		
		var parser:ObjParser = new ObjParser();
		var meshInfos:Vector<Dynamic> = parser.syncParse(obj);
		var meshes:Vector<Mesh> = new Vector<Mesh>();
		for (i in 0...meshInfos.length)
		{
			var meshInfo:Dynamic = meshInfos[i];
			meshes.push(meshInfo.mesh);
			if (meshes[i].getVertexBuffer(BufferType.NORMAL) != null && meshes[i].getVertexBuffer(BufferType.TANGENT) == null)
			{
				TangentBinormalGenerator.generateMesh(meshes[i]);
			}
		}
		
		var write:AngWriter = new AngWriter();
		_byteArray = write.writeMeshes(meshes);
		
		showMsg("点击下载Ang模型文件", "center");
		
		stage.addEventListener(MouseEvent.CLICK, onSaveClick);
	}
	
	private function onSelectFile(event:Event):Void
	{
		var file:FileReference = Lib.as(event.target, FileReference);
		
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
