package examples.advanced;

import assets.manager.FileLoader;
import assets.manager.misc.FileInfo;
import flash.Vector;
import haxe.ds.StringMap;
import org.angle3d.Angle3D;
import org.angle3d.app.SimpleApplication;
import org.angle3d.io.parser.obj.ObjParser;
import org.angle3d.material.Material;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.utils.Stats;

class SponzaExample extends SimpleApplication
{

	static function main() 
	{
		flash.Lib.current.addChild(new SponzaExample());
	}
	
	private var baseURL:String;
	public function new()
	{
		super();
	}
	
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);

		baseURL = "../assets/sponza/";
		
		var assetLoader:FileLoader = new FileLoader();
		assetLoader.queueText(baseURL + "sponza.obj");
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

		var parser:ObjParser = new ObjParser();

		var meshes:Vector<Mesh> = parser.parse(fileMap.get(baseURL + "sponza.obj").data);
		for (i in 0...meshes.length)
		{
			var geomtry:Geometry = new Geometry("Model" + i, meshes[i]);
			geomtry.setMaterial(material);
			scene.attachChild(geomtry);
			geomtry.setTranslationXYZ(0, 0, 0);
			//geomtry.setLocalScaleXYZ(2, 2, 2);
		}
		
		camera.location.setTo(0, 50, 200);
		camera.lookAt(new Vector3f(), Vector3f.Y_AXIS);
		
		start();
	}

	private var angle:Float = 0;

	override public function simpleUpdate(tpf:Float):Void
	{
		angle += 0.02;
		angle %= FastMath.TWO_PI;

		//camera.location.setTo(Math.cos(angle) * 200, 0, Math.sin(angle) * 200);
		//camera.lookAt(new Vector3f(), Vector3f.Y_AXIS);
	}
	
}