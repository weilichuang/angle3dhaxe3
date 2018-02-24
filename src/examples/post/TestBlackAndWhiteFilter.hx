package examples.post;

import angle3d.asset.FilesLoader;
import angle3d.asset.FileInfo;
import flash.ui.Keyboard;

import haxe.ds.StringMap;
import angle3d.Angle3D;
import angle3d.app.SimpleApplication;
import angle3d.input.controls.KeyTrigger;
import angle3d.io.parser.obj.ObjParser;
import angle3d.light.DirectionalLight;
import angle3d.light.SpotLight;
import angle3d.material.FaceCullMode;
import angle3d.material.Material;
import angle3d.shader.VarType;
import angle3d.math.Color;
import angle3d.math.FastMath;
import angle3d.math.Quaternion;
import angle3d.math.Vector3f;
import angle3d.post.filter.BlackAndWhiteFilter;
import angle3d.post.filter.BloomFilter;
import angle3d.post.FilterPostProcessor;
import angle3d.scene.Geometry;
import angle3d.scene.mesh.Mesh;
import angle3d.texture.BitmapTexture;
import angle3d.utils.Stats;


class TestBlackAndWhiteFilter extends BasicExample
{
	static function main() 
	{
		flash.Lib.current.addChild(new TestBlackAndWhiteFilter());
	}
	
	private var baseURL:String;
	private var radius:Float = 50;
	private var active:Bool = true;
	private var fpp:FilterPostProcessor;
	public function new()
	{
		super();
		Angle3D.maxAgalVersion = 2;
	}
	
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);

		baseURL = "../assets/obj/";
		
		var assetLoader:FilesLoader = new FilesLoader();
		assetLoader.queueText(baseURL + "Teapot.obj");
		assetLoader.onFilesLoaded.addOnce(_loadComplete);
		assetLoader.loadQueuedFiles();
	}

	private function _loadComplete(loader:FilesLoader):Void
	{
		flyCam.setDragToRotate(true);
		flyCam.setMoveSpeed(30);
		
		var light:DirectionalLight=new DirectionalLight();
        light.direction = (new Vector3f(-1, -1, -1).normalizeLocal());
        light.color = (new Color(1.5,1.5,1.5));
        scene.addLight(light);
		
		var material:Material = new Material();
		material.load(Angle3D.materialFolder + "material/lighting.mat");
		material.setFloat("u_Shininess", 15);
        material.setBoolean("useMaterialColor", true);
		material.setBoolean("useVertexLighting", false);
		material.setBoolean("useLowQuality", false);
        material.setColor("u_Ambient",  Color.Yellow().mult(0.2));
        material.setColor("u_Diffuse",  Color.Yellow().mult(0.2));
        material.setColor("u_Specular", Color.Yellow().mult(0.8));

		var parser:ObjParser = new ObjParser();
		var mesh:Dynamic = parser.syncParse(loader.getAssetByUrl(baseURL + "Teapot.obj").info.content)[0];
		var geomtry:Geometry = new Geometry("Teapot", mesh.mesh);
		geomtry.setMaterial(material);
		scene.attachChild(geomtry);
		geomtry.setLocalScaleXYZ(20, 20, 20);
		geomtry.setTranslationXYZ(0, 0, 0);

		camera.location.setTo(0, 0, radius);
		camera.lookAt(new Vector3f(), Vector3f.UNIT_Y);
		
		fpp = new FilterPostProcessor();
		
		var blackAndWhiteFilter:BlackAndWhiteFilter = new BlackAndWhiteFilter();
		fpp.addFilter(blackAndWhiteFilter);
        viewPort.addProcessor(fpp);
        
		initInputs();
		
		showMsg("Hit Space to remove black and white filter");
		
		start();
	}
	
	private function initInputs():Void
	{
		mInputManager.addTrigger("space", new KeyTrigger(Keyboard.SPACE));

		mInputManager.addListener(this, ["space"]);
	}
	
	override public function onAction(name:String, keyPressed:Bool, tpf:Float):Void
	{
		super.onAction(name, keyPressed, tpf);
		
		if (name == "space" && keyPressed)
		{
            if (active)
			{
                active = false;
				viewPort.removeProcessor(fpp);
				
				showMsg("Hit Space to add black and white filter");
            }
			else
			{
                active = true;
				viewPort.addProcessor(fpp);
				
				showMsg("Hit Space to remove black and white filter");
            }
        }
	}

	private var angle:Float = 0;

	override public function simpleUpdate(tpf:Float):Void
	{
		angle += 0.02;
		angle %= FastMath.TWO_PI;


		camera.location.setTo(Math.cos(angle) * radius, 20, Math.sin(angle) * radius);
		camera.lookAt(new Vector3f(), Vector3f.UNIT_Y);
	}
}
