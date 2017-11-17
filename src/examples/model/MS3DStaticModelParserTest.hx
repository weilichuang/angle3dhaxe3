package examples.model;

import org.angle3d.asset.FilesLoader;
import org.angle3d.asset.FileInfo;

import flash.display.BitmapData;
import flash.utils.ByteArray;
import haxe.ds.StringMap;
import org.angle3d.Angle3D;
import org.angle3d.app.SimpleApplication;
import org.angle3d.io.parser.ms3d.MS3DParser;
import org.angle3d.material.Material;
import org.angle3d.shader.VarType;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.texture.BitmapTexture;
import org.angle3d.utils.Stats;


class MS3DStaticModelParserTest extends BasicExample
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

		baseURL = "../assets/ms3d/";
		
		var assetLoader:FilesLoader = new FilesLoader();
		assetLoader.queueBinary(baseURL + "ninja.ms3d");
		assetLoader.queueImage(baseURL + "nskinbr.JPG");
		assetLoader.queueBinary(baseURL + "f360.ms3d");
		assetLoader.queueImage(baseURL + "fskin.JPG");
		assetLoader.queueBinary(baseURL + "jeep1.ms3d");
		assetLoader.queueImage(baseURL + "jeep1.jpg");
		assetLoader.onFilesLoaded.addOnce(_loadComplete);
		assetLoader.loadQueuedFiles();

		
	}

	private function _loadComplete(loader:FilesLoader):Void
	{
		flyCam.setDragToRotate(true);
		flyCam.setMoveSpeed(30);
		
		var material:Material = new Material();
		material.load(Angle3D.materialFolder + "material/unshaded.mat");
		material.setTextureParam("u_DiffuseMap", VarType.TEXTURE2D, new BitmapTexture(loader.getAssetByUrl(baseURL + "nskinbr.JPG").info.content));
		
		var material2:Material = new Material();
		material2.load(Angle3D.materialFolder + "material/unshaded.mat");
		material2.setTextureParam("u_DiffuseMap", VarType.TEXTURE2D, new BitmapTexture(loader.getAssetByUrl(baseURL + "fskin.JPG").info.content));
		
		var material3:Material = new Material();
		material3.load(Angle3D.materialFolder + "material/unshaded.mat");
		material3.setTextureParam("u_DiffuseMap", VarType.TEXTURE2D, new BitmapTexture(loader.getAssetByUrl(baseURL + "jeep1.jpg").info.content));

		var parser:MS3DParser = new MS3DParser();
		var meshes:Array<Mesh> = parser.parseStaticMesh(loader.getAssetByUrl(baseURL + "ninja.ms3d").info.content);
		for (i in 0...meshes.length)
		{
			var geomtry:Geometry = new Geometry("ninja" + i, meshes[i]);
			geomtry.setMaterial(material);
			scene.attachChild(geomtry);
			geomtry.setTranslationXYZ(-5, -5, 0);
		}

		meshes = parser.parseStaticMesh(loader.getAssetByUrl(baseURL + "f360.ms3d").info.content);
		for (i in 0...meshes.length)
		{
			var geomtry:Geometry = new Geometry("car" + i, meshes[i]);
			geomtry.setLocalScaleXYZ(0.2, 0.2, 0.2);
			geomtry.setMaterial(material2);
			scene.attachChild(geomtry);
			geomtry.setTranslationXYZ(5, 0, 0);
		}

		meshes = parser.parseStaticMesh(loader.getAssetByUrl(baseURL + "jeep1.ms3d").info.content);
		for (i in 0...meshes.length)
		{
			var geomtry:Geometry = new Geometry("jeep" + i, meshes[i]);
			//geomtry.setLocalScaleXYZ(0.2, 0.2, 0.2);
			geomtry.setMaterial(material3);
			scene.attachChild(geomtry);
			geomtry.setTranslationXYZ(20, 0, 0);
		}
		
		camera.location.setTo(0, 10, -50);
		camera.lookAt(new Vector3f(), Vector3f.UNIT_Y);
		
		start();
	}

	private var angle:Float = 0;

	override public function simpleUpdate(tpf:Float):Void
	{
		//angle += 0.02;
		//angle %= FastMath.TWO_PI;
//
//
		//camera.location.setTo(Math.cos(angle) * 20, 0, Math.sin(angle) * 20);
		//camera.lookAt(new Vector3f(), Vector3f.Y_AXIS);
	}
}
