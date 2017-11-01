package examples.post;

import org.angle3d.asset.FilesLoader;
import org.angle3d.asset.FileInfo;
import flash.ui.Keyboard;

import haxe.ds.StringMap;
import org.angle3d.Angle3D;
import org.angle3d.app.SimpleApplication;
import org.angle3d.input.controls.KeyTrigger;
import org.angle3d.io.parser.obj.ObjParser;
import org.angle3d.light.DirectionalLight;
import org.angle3d.light.SpotLight;
import org.angle3d.material.FaceCullMode;
import org.angle3d.material.LightMode;
import org.angle3d.material.Material;
import org.angle3d.material.VarType;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;
import org.angle3d.post.filter.BloomFilter;
import org.angle3d.post.FilterPostProcessor;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.texture.BitmapTexture;
import org.angle3d.utils.Stats;


class TestBloom extends BasicExample
{
	static function main() 
	{
		flash.Lib.current.addChild(new TestBloom());
	}
	
	private var baseURL:String;
	private var radius:Float = 50;
	private var active:Bool = false;
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
		
		mRenderManager.setPreferredLightMode(LightMode.SinglePass);
		mRenderManager.setSinglePassLightBatchSize(2);
		
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
		geomtry.setLocalScaleXYZ(10, 10, 10);
		geomtry.setTranslationXYZ(0, 0, 0);

		camera.location.setTo(0, 20, radius);
		camera.lookAt(new Vector3f(), Vector3f.UNIT_Y);
		
		fpp = new FilterPostProcessor();
		
		var bloom:BloomFilter = new BloomFilter();
        bloom.setDownSamplingFactor(2);
        bloom.setBlurScale(1.37);
        bloom.setExposurePower(3.30);
        bloom.setExposureCutOff(0.2);
        bloom.setBloomIntensity(2.45);
		fpp.addFilter(bloom);

        //viewPort.addProcessor(fpp);
        
		
		initInputs();
		
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
            }
			else
			{
                active = true;
				viewPort.addProcessor(fpp);
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
