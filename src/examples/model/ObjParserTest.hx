package examples.model;

import org.angle3d.asset.FilesLoader;
import org.angle3d.asset.FileInfo;

import haxe.ds.StringMap;
import org.angle3d.Angle3D;
import org.angle3d.app.SimpleApplication;
import org.angle3d.io.parser.obj.ObjParser;
import org.angle3d.material.FaceCullMode;
import org.angle3d.material.Material;
import org.angle3d.shader.VarType;
import org.angle3d.math.FastMath;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.texture.BitmapTexture;
import org.angle3d.utils.Stats;


class ObjParserTest extends BasicExample
{
	static function main() 
	{
		flash.Lib.current.addChild(new ObjParserTest());
	}
	
	private var baseURL:String;
	public function new()
	{
		super();
	}
	
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);

		baseURL = "../assets/obj/";
		
		var assetLoader:FilesLoader = new FilesLoader();
		assetLoader.queueText(baseURL + "suzanne.obj");
		assetLoader.queueImage(baseURL + "suzanne.png");
		assetLoader.queueText(baseURL + "head.obj");
		assetLoader.queueImage(baseURL + "head_diffuse.jpg");
		assetLoader.queueText(baseURL + "Teapot.obj");
		assetLoader.queueText(baseURL + "Model.obj");
		assetLoader.queueImage(baseURL + "Skeleton01.png");
		assetLoader.queueImage(baseURL + "Sword01.png");
		assetLoader.onFilesLoaded.addOnce(_loadComplete);
		assetLoader.loadQueuedFiles();
	}

	private function _loadComplete(loader:FilesLoader):Void
	{
		flyCam.setDragToRotate(true);
		flyCam.setMoveSpeed(30);
		
		var material:Material = new Material();
		material.load(Angle3D.materialFolder + "material/unshaded.mat");
		material.setTextureParam("u_DiffuseMap", VarType.TEXTURE2D, new BitmapTexture(loader.getAssetByUrl(baseURL + "head_diffuse.jpg").info.content));
		
		var materialSkeleton:Material = new Material();
		materialSkeleton.load(Angle3D.materialFolder + "material/unshaded.mat");
		materialSkeleton.setTextureParam("u_DiffuseMap", VarType.TEXTURE2D, new BitmapTexture(loader.getAssetByUrl(baseURL + "Skeleton01.png").info.content));
		
		var materialSword:Material = new Material();
		materialSword.load(Angle3D.materialFolder + "material/unshaded.mat");
		materialSword.setTextureParam("u_DiffuseMap", VarType.TEXTURE2D, new BitmapTexture(loader.getAssetByUrl(baseURL + "Sword01.png").info.content));
		
		var parser:ObjParser = new ObjParser();
		var meshInfo:Dynamic;
		var geomtry:Geometry;
		
		meshInfo = parser.syncParse(loader.getAssetByUrl(baseURL + "head.obj").info.content)[0];
		geomtry = new Geometry(meshInfo.name, meshInfo.mesh);
		geomtry.setMaterial(material);
		scene.attachChild(geomtry);
		geomtry.setLocalScaleXYZ(10, 10, 10);
		geomtry.setTranslationXYZ( -40, 0, 0);
		
		var material2:Material = new Material();
		material2.load(Angle3D.materialFolder + "material/unshaded.mat");
		material2.setTextureParam("u_DiffuseMap", VarType.TEXTURE2D, new BitmapTexture(loader.getAssetByUrl(baseURL + "suzanne.png").info.content));
		
		meshInfo = parser.syncParse(loader.getAssetByUrl(baseURL + "suzanne.obj").info.content)[0];
		geomtry = new Geometry(meshInfo.name, meshInfo.mesh);
		geomtry.setMaterial(material2);
		scene.attachChild(geomtry);
		geomtry.setLocalScaleXYZ(20, 20, 20);
		geomtry.setTranslationXYZ(40, 0, 0);
		
		var materialNormal:Material = new Material();
		materialNormal.load(Angle3D.materialFolder + "material/showNormals.mat");

		meshInfo = parser.syncParse(loader.getAssetByUrl(baseURL + "Teapot.obj").info.content)[0];
		geomtry = new Geometry("Teapot", meshInfo.mesh);
		geomtry.setMaterial(materialNormal);
		scene.attachChild(geomtry);
		geomtry.setLocalScaleXYZ(20, 20, 20);
		geomtry.setTranslationXYZ(80, 0, 0);
		
		
		var q:Quaternion = new Quaternion();
		q.fromAngles(-90, 0, 0);
		
		var meshes:Array<Dynamic> = parser.syncParse(loader.getAssetByUrl(baseURL + "Model.obj").info.content);
		for (i in 0...meshes.length)
		{
			geomtry = new Geometry(meshes[i].name, meshes[i].mesh);
			if(i == 0)
				geomtry.setMaterial(materialSkeleton);
			else
				geomtry.setMaterial(materialSword);
			scene.attachChild(geomtry);
			geomtry.setLocalRotation(q);
			geomtry.setTranslationXYZ(0, 0, 50);
			geomtry.setLocalScaleXYZ(2, 2, 2);
		}
		
		camera.location.setTo(0, 2, 200);
		camera.lookAt(new Vector3f(), Vector3f.UNIT_Y);
		
		start();
	}

	private var angle:Float = 0;

	override public function simpleUpdate(tpf:Float):Void
	{
		angle += 0.02;
		angle %= FastMath.TWO_PI;


		camera.location.setTo(Math.cos(angle) * 200, 0, Math.sin(angle) * 200);
		camera.lookAt(new Vector3f(), Vector3f.UNIT_Y);
	}
}
