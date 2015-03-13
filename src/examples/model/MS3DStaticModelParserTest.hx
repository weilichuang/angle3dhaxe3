package examples.model;

import assets.manager.FileLoader;
import assets.manager.misc.FileInfo;
import assets.manager.misc.FileType;
import flash.display.BitmapData;
import flash.utils.ByteArray;
import org.angle3d.app.SimpleApplication;
import org.angle3d.io.parser.ms3d.MS3DParser;
import org.angle3d.material.Material;
import org.angle3d.material.VarType;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.texture.BitmapTexture;
import org.angle3d.utils.Stats;


class MS3DStaticModelParserTest extends SimpleApplication
{
	static function main() 
	{
		flash.Lib.current.addChild(new MS3DStaticModelParserTest());
	}
	
	private var baseURL:String;
	public function new()
	{
		super();
	}
	
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);

		baseURL = "ms3d/";
		
		var assetLoader:FileLoader = new FileLoader();
		assetLoader.queueBinary(baseURL + "ninja.ms3d");
		assetLoader.queueImage(baseURL + "nskinbr.JPG");
		assetLoader.onFilesLoaded.addOnce(_loadComplete);
		assetLoader.loadQueuedFiles();

		Stats.show(stage);
	}

	private function _loadComplete(files:Array<FileInfo>):Void
	{
		var byteArray:ByteArray = null;
		var bitmapData:BitmapData = null;
		for (i in 0...files.length)
		{
			if (files[i].type == FileType.BINARY)
			{
				byteArray = files[i].data;
			}
			else if (files[i].type == FileType.IMAGE)
			{
				bitmapData = files[i].data;
			}
		}
		
		flyCam.setDragToRotate(true);
		
		var material:Material = new Material();
		material.load("assets/material/unshaded.mat");
		material.setTextureParam("u_DiffuseMap", VarType.TEXTURE2D, new BitmapTexture(bitmapData));

		var parser:MS3DParser = new MS3DParser();
		var meshes:Array<Mesh> = parser.parseStaticMesh(byteArray);
		for (i in 0...meshes.length)
		{
			var geomtry:Geometry = new Geometry("ninja" + i, meshes[i]);
			geomtry.setMaterial(material);
			scene.attachChild(geomtry);
			geomtry.setTranslationXYZ(0, -5, 0);
		}

		
		camera.location.setTo(0, 5, -20);
		camera.lookAt(new Vector3f(), Vector3f.Y_AXIS);
		
		start();
	}

	private var angle:Float = 0;

	override public function simpleUpdate(tpf:Float):Void
	{
		angle += 0.02;
		angle %= FastMath.TWO_PI();


		camera.location.setTo(Math.cos(angle) * 20, 0, Math.sin(angle) * 20);
		camera.lookAt(new Vector3f(), Vector3f.Y_AXIS);
	}
}
