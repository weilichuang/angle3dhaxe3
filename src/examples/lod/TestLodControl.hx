package examples.lod;

import org.angle3d.asset.FilesLoader;
import org.angle3d.asset.FileInfo;
import flash.Lib;
import flash.text.TextField;

import haxe.ds.StringMap;
import org.angle3d.Angle3D;
import org.angle3d.app.SimpleApplication;
import org.angle3d.io.parser.ogre.OgreMeshXmlParser;
import org.angle3d.light.PointLight;
import org.angle3d.material.Material;
import org.angle3d.math.Color;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.queue.ShadowMode;
import org.angle3d.scene.control.LodControl;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.scene.shape.Box;
import org.angle3d.utils.Stats;

class TestLodControl extends BasicExample
{
	static function main() 
	{
		Lib.current.addChild(new TestLodControl());
	}
	
	private var _center:Vector3f;
	private var baseURL:String;
	private var tf:TextField;
	public function new() 
	{
		Angle3D.maxAgalVersion = 2;
		super();
	}
	
	
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);

		baseURL = "../assets/ogre/";
		
		var assetLoader:FilesLoader = new FilesLoader();
		assetLoader.queueText(baseURL + "Teapot.mesh.xml");
		assetLoader.onFilesLoaded.addOnce(_loadComplete);
		assetLoader.loadQueuedFiles();
	}
	
	private function _loadComplete(loader:FilesLoader):Void
	{
		flyCam.setDragToRotate(true);
		flyCam.setMoveSpeed(100);
		
		setupFloor();
		
		createTeapots(loader.getAssetByUrl(baseURL+"Teapot.mesh.xml").info.content);
		
		_center = new Vector3f(0, 0, 0);

		camera.location.setTo(0, 40, 80);
		camera.lookAt(_center, Vector3f.UNIT_Y);
		
		var pl = new PointLight();
		pl.color = new Color(1, 0, 0, 1);
		pl.position = new Vector3f(0, 100, 0);
		pl.radius = 150;
		scene.addLight(pl);
		
		tf = new TextField();
		tf.textColor = 0xffffff;
		tf.width = 200;
		tf.height = 400;
		this.stage.addChild(tf);
		
		reshape(mContextWidth, mContextHeight);
		
		
		start();
	}
	
	private function createTeapots(xmlStr:String):Void
	{
		var parser:OgreMeshXmlParser = new OgreMeshXmlParser();
		var meshes:Vector<Mesh> = parser.parse(xmlStr);
		if (meshes.length == 0)
			return;
		
		
		var mat:Material = new Material();
		mat.load(Angle3D.materialFolder + "material/lighting.mat");
		mat.setFloat("u_Shininess", 1);
		mat.setBoolean("useMaterialColor", false);
		mat.setBoolean("useVertexLighting", false);
		mat.setBoolean("useLowQuality", false);
		mat.setColor("u_Ambient",  Color.White());
		mat.setColor("u_Diffuse",  Color.Random());
		mat.setColor("u_Specular", Color.White());
		
		var hCount:Int = 10;
		var vCount:Int = 10;
		var halfHCount:Float = (hCount / 2);
		var halfVCount:Float = (vCount / 2);
		var index:Int = 0;
		for (i in 0...hCount)
		{
			for (j in 0...vCount)
			{
				var geometry:Geometry = new Geometry("box" + index, meshes[0]);
				geometry.addControl(new LodControl());
				geometry.setMaterial(mat);
				geometry.setLocalScaleXYZ(2, 2, 2);
				geometry.setTranslationXYZ((i - halfHCount) * 15, 5, (j - halfVCount) * 15);
				scene.attachChild(geometry);
			}
		}
	}
	
	private function setupFloor():Void
	{
		var mat:Material = new Material();
		mat.load(Angle3D.materialFolder + "material/unshaded.mat");
        mat.setColor("u_MaterialColor",  new Color(0.8,0.8,0.8));

		var floor:Box = new Box(150, 1, 150);
		var floorGeom:Geometry = new Geometry("Floor", floor);
		floorGeom.setMaterial(mat);
		floorGeom.setLocalTranslation(new Vector3f(0, 0, 0));
		floorGeom.localShadowMode = ShadowMode.Receive;
		scene.attachChild(floorGeom);
	}

	override public function simpleUpdate(tpf:Float):Void 
	{
		super.simpleUpdate(tpf);
		
		tf.text = scene.getTriangleCount() + "";
	}
}