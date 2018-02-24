package examples.material;

import angle3d.asset.FilesLoader;
import angle3d.asset.FileInfo;

import haxe.ds.StringMap;
import angle3d.Angle3D;
import angle3d.app.SimpleApplication;
import angle3d.io.parser.obj.ObjParser;
import angle3d.material.FaceCullMode;
import angle3d.material.Material;
import angle3d.shader.VarType;
import angle3d.math.FastMath;
import angle3d.math.Quaternion;
import angle3d.math.Vector3f;
import angle3d.scene.Geometry;
import angle3d.scene.mesh.Mesh;
import angle3d.texture.BitmapTexture;
import angle3d.utils.Stats;


class MaterialLightMapTest extends BasicExample
{
	static function main() 
	{
		flash.Lib.current.addChild(new MaterialLightMapTest());
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
		assetLoader.queueText(baseURL + "house_2.obj");
		assetLoader.queueImage(baseURL + "House2.png");
		assetLoader.queueImage(baseURL + "House2-lightmap.png");
		assetLoader.onFilesLoaded.addOnce(_loadComplete);
		assetLoader.loadQueuedFiles();

		
	}

	private function _loadComplete(loader:FilesLoader):Void
	{
		flyCam.setDragToRotate(true);
		flyCam.setMoveSpeed(30);
		
		var material:Material = new Material();
		material.load(Angle3D.materialFolder + "material/unshaded.mat");
		material.setTexture("u_DiffuseMap", new BitmapTexture(loader.getAssetByUrl(baseURL + "House2.png").info.content));
		material.setTexture("u_LightMap", new BitmapTexture(loader.getAssetByUrl(baseURL + "House2-lightmap.png").info.content));
		
		var parser:ObjParser = new ObjParser();
		var meshInfo:Dynamic = parser.syncParse(loader.getAssetByUrl(baseURL + "house_2.obj").info.content)[0];
		var geomtry:Geometry = new Geometry(meshInfo.name, meshInfo.mesh);
		geomtry.setMaterial(material);
		scene.attachChild(geomtry);
		geomtry.setLocalScaleXYZ(10, 10, 10);
		//geomtry.setTranslationXYZ( -40, 0, 0);
		
		camera.location.setTo(0, 60, 100);
		camera.lookAt(new Vector3f(), Vector3f.UNIT_Y);
		
		start();
	}

	private var angle:Float = 0;

	override public function simpleUpdate(tpf:Float):Void
	{
		super.simpleUpdate(tpf);
		
		angle += 0.02;
		angle %= FastMath.TWO_PI;

		camera.location.setTo(Math.cos(angle) * 100, 60, Math.sin(angle) * 100);
		camera.lookAt(new Vector3f(), Vector3f.UNIT_Y);
	}
}
