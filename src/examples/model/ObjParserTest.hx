package examples.model;

import assets.manager.FileLoader;
import assets.manager.misc.FileInfo;
import haxe.ds.StringMap;
import org.angle3d.Angle3D;
import org.angle3d.app.SimpleApplication;
import org.angle3d.io.parser.obj.ObjParser;
import org.angle3d.material.CullMode;
import org.angle3d.material.Material;
import org.angle3d.material.VarType;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.texture.BitmapTexture;
import org.angle3d.utils.Stats;


class ObjParserTest extends SimpleApplication
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
		
		var assetLoader:FileLoader = new FileLoader();
		assetLoader.queueText(baseURL + "suzanne.obj");
		assetLoader.queueImage(baseURL + "suzanne.png");
		assetLoader.queueText(baseURL + "head.obj");
		assetLoader.queueImage(baseURL + "head_diffuse.jpg");
		assetLoader.queueText(baseURL + "Teapot.obj");
		assetLoader.onFilesLoaded.addOnce(_loadComplete);
		assetLoader.loadQueuedFiles();

		Stats.show(stage);
	}

	private function _loadComplete(fileMap:StringMap<FileInfo>):Void
	{
		flyCam.setDragToRotate(true);
		flyCam.setMoveSpeed(30);
		
		var material:Material = new Material();
		material.load(Angle3D.materialFolder + "material/unshaded.mat");
		material.setTextureParam("u_DiffuseMap", VarType.TEXTURE2D, new BitmapTexture(fileMap.get(baseURL + "head_diffuse.jpg").data));
		
		var parser:ObjParser = new ObjParser();
		var mesh:Mesh = parser.parse(fileMap.get(baseURL + "head.obj").data);
		var geomtry:Geometry = new Geometry("R2D2", mesh);
		geomtry.setMaterial(material);
		scene.attachChild(geomtry);
		geomtry.setLocalScaleXYZ(10, 10, 10);
		geomtry.setTranslationXYZ( -40, 0, 0);
		
		var material2:Material = new Material();
		material2.load(Angle3D.materialFolder + "material/unshaded.mat");
		material2.setTextureParam("u_DiffuseMap", VarType.TEXTURE2D, new BitmapTexture(fileMap.get(baseURL + "suzanne.png").data));
		
		mesh = parser.parse(fileMap.get(baseURL + "suzanne.obj").data);
		geomtry = new Geometry("suzanne", mesh);
		geomtry.setMaterial(material2);
		scene.attachChild(geomtry);
		geomtry.setLocalScaleXYZ(20, 20, 20);
		geomtry.setTranslationXYZ(40, 0, 0);
		
		
		mesh = parser.parse(fileMap.get(baseURL + "Teapot.obj").data);
		geomtry = new Geometry("Teapot", mesh);
		geomtry.setMaterial(material2);
		scene.attachChild(geomtry);
		geomtry.setLocalScaleXYZ(20, 20, 20);
		geomtry.setTranslationXYZ(80, 0, 0);
		
		camera.location.setTo(0, 2, 200);
		camera.lookAt(new Vector3f(), Vector3f.Y_AXIS);
		
		start();
	}

	private var angle:Float = 0;

	override public function simpleUpdate(tpf:Float):Void
	{
		angle += 0.02;
		angle %= FastMath.TWO_PI();


		camera.location.setTo(Math.cos(angle) * 200, 0, Math.sin(angle) * 200);
		camera.lookAt(new Vector3f(), Vector3f.Y_AXIS);
	}
}
