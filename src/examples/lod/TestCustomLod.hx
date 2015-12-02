package examples.lod;

import assets.manager.FileLoader;
import assets.manager.misc.FileInfo;
import flash.Lib;
import flash.text.TextField;
import flash.ui.Keyboard;
import flash.Vector;
import haxe.ds.StringMap;
import org.angle3d.Angle3D;
import org.angle3d.app.SimpleApplication;
import org.angle3d.input.controls.KeyTrigger;
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

class TestCustomLod extends BasicExample
{
	static function main() 
	{
		Lib.current.addChild(new TestCustomLod());
	}
	
	private var _center:Vector3f;
	private var baseURL:String;
	private var tf:TextField;
	private var numLod:Int = 0;
	private var curLod:Int = 0;
	private var geometry:Geometry;
	public function new() 
	{
		Angle3D.maxAgalVersion = 2;
		super();
	}
	
	
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);

		baseURL = "../assets/ogre/";
		
		var assetLoader:FileLoader = new FileLoader();
		assetLoader.queueText(baseURL + "Teapot.mesh.xml");
		assetLoader.onFilesLoaded.addOnce(_loadComplete);
		assetLoader.loadQueuedFiles();
	}
	
	private function _loadComplete(fileMap:StringMap<FileInfo>):Void
	{
		flyCam.setDragToRotate(true);
		flyCam.setMoveSpeed(100);
		
		setupFloor();
		
		createTeapots(fileMap.get(baseURL+"Teapot.mesh.xml").data);
		
		_center = new Vector3f(0, 0, 0);

		camera.location.setTo(0, 40, 80);
		camera.lookAt(_center, Vector3f.Y_AXIS);
		
		var pl = new PointLight();
		pl.color = new Color(1, 0, 0, 1);
		pl.position = new Vector3f(0, 50, 0);
		pl.radius = 150;
		scene.addLight(pl);
		
		tf = new TextField();
		tf.textColor = 0xffffff;
		tf.width = 300;
		tf.height = 400;
		this.stage.addChild(tf);
		
		initInputs();
		
		reshape(mContextWidth, mContextHeight);
		
		Stats.show(stage);
		start();
	}
	
	private function createTeapots(xmlStr:String):Void
	{
		var parser:OgreMeshXmlParser = new OgreMeshXmlParser();
		var meshes:Vector<Mesh> = parser.parse(xmlStr);
		if (meshes.length == 0)
			return;
			
		numLod = meshes[0].getNumLodLevels();
		
		var mat:Material = new Material();
		mat.load(Angle3D.materialFolder + "material/lighting.mat");
		mat.setFloat("u_Shininess", 1);
		mat.setBoolean("useMaterialColor", false);
		mat.setBoolean("useVertexLighting", false);
		mat.setBoolean("useLowQuality", false);
		mat.setColor("u_Ambient",  Color.White());
		mat.setColor("u_Diffuse",  Color.Random());
		mat.setColor("u_Specular", Color.White());
		
		geometry = new Geometry("box", meshes[0]);
		geometry.setMaterial(mat);
		geometry.setLocalScaleXYZ(5, 5, 5);
		geometry.setTranslationXYZ(0, 0, 0);
		scene.attachChild(geometry);
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
	
	private function initInputs():Void
	{
		mInputManager.addTrigger("lodUP", new KeyTrigger(Keyboard.UP));
		mInputManager.addTrigger("lodDown", new KeyTrigger(Keyboard.DOWN));
		mInputManager.addListener(this, Vector.ofArray(["lodUP", "lodDown"]));
	}
	
	override public function onAction(name:String, value:Bool, tpf:Float):Void
	{
		super.onAction(name, value, tpf);
		
		if (!value)
			return;
		
		if (name == "lodUP")
		{
			curLod++;
			if (curLod >= numLod)
				curLod = 0;
				
			if (geometry != null)
				geometry.setLodLevel(curLod);
		}
		else if (name == "lodDown")
		{
			curLod--;
			if (curLod < 0)
				curLod = 0;
				
			if (geometry != null)
				geometry.setLodLevel(curLod);
		}
	}

	override public function update():Void 
	{
		super.update();
		
		tf.text = 'curLod: ${curLod},totalLod: ${numLod}, curTriangleCount: ${scene.getTriangleCount()}\n Press Up or Down to change LOD';
	}
}