package examples.material;

import assets.manager.FileLoader;
import assets.manager.misc.FileInfo;
import flash.ui.Keyboard;
import haxe.ds.StringMap;
import org.angle3d.Angle3D;
import org.angle3d.app.SimpleApplication;
import org.angle3d.input.controls.KeyTrigger;
import org.angle3d.light.AmbientLight;
import org.angle3d.light.PointLight;
import org.angle3d.material.Material;
import org.angle3d.material.TechniqueDef.LightMode;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.LightNode;
import org.angle3d.scene.Node;
import org.angle3d.scene.shape.Sphere;
import org.angle3d.texture.BitmapTexture;
import org.angle3d.texture.Texture2D;
import org.angle3d.utils.Stats;
import org.angle3d.utils.TangentBinormalGenerator;

class MaterialNormalMapTest2 extends SimpleApplication
{
	static function main() 
	{
		flash.Lib.current.addChild(new MaterialNormalMapTest2());
	}
	
	private var baseURL:String;
	public function new()
	{
		Angle3D.maxAgalVersion = 2;
		super();
	}
	
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);

		baseURL = "../assets/textures/";

		var assetLoader:FileLoader = new FileLoader();
		assetLoader.queueImage(baseURL + "Pond.jpg");
		assetLoader.queueImage(baseURL + "Pond_normal.png");
		assetLoader.onFilesLoaded.addOnce(_loadComplete);
		assetLoader.loadQueuedFiles();
	}

	private var mat:Material;
	private var _center:Vector3f;
	private var texture:Texture2D;
	private var normalTexture:Texture2D;
	
	private var pl:PointLight;
	private var pointLightNode:Node;

	private function _loadComplete(files:StringMap<FileInfo>):Void
	{
		flyCam.setDragToRotate(true);
		
		mRenderManager.setPreferredLightMode(LightMode.SinglePass);
		mRenderManager.setSinglePassLightBatchSize(2);
		
		var sphere:Sphere = new Sphere(2, 32, 32, false, false, SphereTextureMode.Projected);
		
		
		var mat2:Material = new Material();
		mat2.load(Angle3D.materialFolder + "material/unshaded.mat");
		mat2.setColor("u_MaterialColor", Color.White());
		
		var lightModel:Geometry = new Geometry("Light", sphere);
		lightModel.setMaterial(mat2);
		//lightModel.visible = false;
		
		pointLightNode = new Node("lightParentNode");
		pointLightNode.attachChild(lightModel);
		
		scene.attachChild(pointLightNode);
		
		pl = new PointLight();
		pl.color = Color.White();
		pl.radius = 100;
		scene.addLight(pl);
		
		var lightNode:LightNode = new LightNode("pointLight", pl);
		pointLightNode.attachChild(lightNode);
		

		var al:AmbientLight = new AmbientLight();
		al.color = new Color(0.3, 0.3, 0.3, 1);
		scene.addLight(al);
		
		texture = new BitmapTexture(files.get(baseURL + "Pond.jpg").data);
		normalTexture = new BitmapTexture(files.get(baseURL + "Pond_normal.png").data);
		
		TangentBinormalGenerator.generateMesh(sphere);

		var boat:Geometry = new Geometry("boat", sphere);
		scene.attachChild(boat);
		boat.setLocalScaleXYZ(10, 10, 10);
		boat.setTranslationXYZ(-20, 0, 0);

		var mat:Material = new Material();
		mat.load(Angle3D.materialFolder + "material/lighting.mat");
		mat.setFloat("u_Shininess", 32);
        mat.setBoolean("useMaterialColor", true);
        mat.setColor("u_Ambient",  new Color(0.2,0.2,0.2));
        mat.setColor("u_Diffuse",  new Color(0.8,0.8,0.8));
        mat.setColor("u_Specular", new Color(0.3,0.3,0.3));
		mat.setTexture("u_DiffuseMap", texture);
		boat.setMaterial(mat);
		
		var boat2:Geometry = new Geometry("boat", sphere);
		scene.attachChild(boat2);
		boat2.setTranslationXYZ(20, 0, 0);
		boat2.setLocalScaleXYZ(10, 10, 10);

		var mat3:Material = new Material();
		mat3.load(Angle3D.materialFolder + "material/lighting.mat");
		mat3.setFloat("u_Shininess", 32);
        mat3.setBoolean("useMaterialColor", true);
        mat3.setColor("u_Ambient",  new Color(0.2,0.2,0.2));
        mat3.setColor("u_Diffuse",  new Color(0.8,0.8,0.8));
        mat3.setColor("u_Specular", new Color(0.3,0.3,0.3));
		mat3.setTexture("u_DiffuseMap", texture);
		mat3.setTexture("u_NormalMap", normalTexture);
		boat2.setMaterial(mat3);
		
		_center = new Vector3f(0, 0, 0);

		camera.location.setTo(Math.cos(angle) * 100, 0, Math.sin(angle) * 100);
		camera.lookAt(_center, Vector3f.Y_AXIS);
		
		flyCam.setMoveSpeed(20);

		initInputs();
		reshape(mContextWidth, mContextHeight);
		
		start();
		Stats.show(stage);
	}

	private var angle:Float = -1.5;

	override public function simpleUpdate(tpf:Float):Void
	{
		if (pause)
			return;
			
		angle += 0.01;
		angle %= FastMath.TWO_PI();
		
		pointLightNode.setTranslationXYZ(Math.cos(angle) * 80, 10, Math.sin(angle) * 80);
	}
	
	private function initInputs():Void
	{
		mInputManager.addSingleMapping("pause", new KeyTrigger(Keyboard.SPACE));
		mInputManager.addListener(this, ["pause"]);
	}
	
	private var pause:Bool = false;
	override public function onAction(name:String, value:Bool, tpf:Float):Void
	{
		super.onAction(name, value, tpf);
		
		if (name == "pause" && value)
		{
			pause = !pause;
		}
	}
}
