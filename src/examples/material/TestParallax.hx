package examples.material;

import examples.BasicExample;

import flash.display.BitmapData;
import flash.ui.Keyboard;
import org.angle3d.Angle3D;
import org.angle3d.asset.FilesLoader;
import org.angle3d.input.controls.KeyTrigger;
import org.angle3d.light.AmbientLight;
import org.angle3d.light.DirectionalLight;
import org.angle3d.material.Material;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector2f;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.shape.Quad;
import org.angle3d.texture.BitmapTexture;
import org.angle3d.texture.MipFilter;
import org.angle3d.texture.Texture2D;
import org.angle3d.texture.WrapMode;
import org.angle3d.utils.TangentBinormalGenerator;
import org.angle3d.material.LightMode;

/**
 * ...
 * @author ...
 */
class TestParallax extends BasicExample
{

	static function main() 
	{
		flash.Lib.current.addChild(new TestParallax());
	}
	
	private var baseURL:String;
	private var normalMap:Texture2D;
	private var diffuseMap:Texture2D;
	private var parallaxHeight:Vector2f;
	public function new()
	{
		Angle3D.maxAgalVersion = 2;
		super();
	}
	
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);

		baseURL = "../assets/wall/";

		var assetLoader:FilesLoader = new FilesLoader();
		assetLoader.queueImage(baseURL + "BrickWall.jpg");
		assetLoader.queueImage(baseURL + "BrickWall_normal_parallax.png");
		assetLoader.onFilesLoaded.addOnce(_loadComplete);
		assetLoader.loadQueuedFiles();
	}
	
	private function setupLighting():Void
	{
		var al:AmbientLight = new AmbientLight();
		al.color = new Color(0.5, 0.5, 0.5);
		scene.addLight(al);
		
		var lightDir:Vector3f = new Vector3f( -1, -1, .5).normalizeLocal();
		
		var dl = new DirectionalLight();
        dl.direction = lightDir;
        dl.color = new Color(.9, .9, .9, 1);
        scene.addLight(dl);
	}
	
	private var mat:Material;
	private function setupFloor():Void
	{
		mat = new Material();
		mat.load(Angle3D.materialFolder + "material/lighting.mat");
		mat.setFloat("u_Shininess", 2);
        mat.setBoolean("useMaterialColor", false);
		mat.setBoolean("useVertexLighting", false);
		mat.setBoolean("useLowQuality", false);
        mat.setColor("u_Ambient",  Color.White());
        mat.setColor("u_Diffuse",  Color.White());
        mat.setColor("u_Specular", Color.White());
		
		mat.setTexture("u_DiffuseMap", diffuseMap);
		mat.setTexture("u_NormalMap", normalMap);
		mat.setBoolean("u_PackedNormalParallax", true);
		
		parallaxHeight = new Vector2f();
		parallaxHeight.x = 0.05;
		parallaxHeight.y = -0.6 * parallaxHeight.x;
		mat.setVector2("u_ParallaxHeight", parallaxHeight);
		updateMsg();
		
		var quad:Quad = new Quad(100, 100);
		quad.scaleTextureCoordinates(new Vector2f(10, 10));
		TangentBinormalGenerator.generateMesh(quad);
		var floorGeom:Geometry = new Geometry("Floor", quad);
		floorGeom.setMaterial(mat);
		floorGeom.setLocalRotation(new Quaternion().fromAngleAxis(-FastMath.HALF_PI, Vector3f.UNIT_X));
		scene.attachChild(floorGeom);
	}
	
	private function getBitmap(loader:FilesLoader,name:String):BitmapData
	{
		return loader.getAssetByUrl(name).info.content;
	}

	private function _loadComplete(loader:FilesLoader):Void
	{
		diffuseMap = new BitmapTexture(getBitmap(loader, baseURL + "BrickWall.jpg"),true);
		diffuseMap.wrapMode = WrapMode.REPEAT;
		diffuseMap.mipFilter = MipFilter.MIPLINEAR;
		normalMap = new BitmapTexture(getBitmap(loader, baseURL + "BrickWall_normal_parallax.png"),true);
		normalMap.wrapMode = WrapMode.REPEAT;
		normalMap.mipFilter = MipFilter.MIPLINEAR;
				
		setupLighting();
		setupFloor();
		
		camera.setLocation(new Vector3f(80.445636, 30.162927, 30));
        camera.lookAt(new Vector3f(60,0,0), Vector3f.UNIT_Y);
        flyCam.setMoveSpeed(30);
		flyCam.setDragToRotate(true);
		
		mInputManager.addTrigger("up", new KeyTrigger(Keyboard.UP));
		mInputManager.addTrigger("down", new KeyTrigger(Keyboard.DOWN));
		mInputManager.addTrigger("lightMode", new KeyTrigger(Keyboard.SPACE));
		mInputManager.addListener(this, Vector.ofArray(["up","down","lightMode"]));
		
		start();
	}
	
	private function updateMsg():Void
	{
		showMsg('Press UP or DOWN to change parallaxHeight,cur parallaxHeight ${parallaxHeight.x}\n' +
		'Press SPACE to change LightMode,cur LightMode is ${LightMode.getLightModeName(mRenderManager.getPreferredLightMode())}');
	}
	
	override public function onAction(name:String, value:Bool, tpf:Float):Void
	{
		super.onAction(name, value, tpf);

		if (value)
		{
			if (name == "up")
			{
				parallaxHeight.x += 0.01;
				parallaxHeight.y = -0.6 * parallaxHeight.x;
				mat.setVector2("u_ParallaxHeight", parallaxHeight);
				updateMsg();
			}
			else if (name == "down")
			{
				parallaxHeight.x -= 0.01;
				parallaxHeight.x = Math.max(parallaxHeight.x, 0.01);
				parallaxHeight.y = -0.6 * parallaxHeight.x;
				mat.setVector2("u_ParallaxHeight", parallaxHeight);
				updateMsg();
			}
			else if (name == "lightMode")
			{
				mat.clearTechniuqe();
				if (mRenderManager.getPreferredLightMode() == LightMode.MultiPass)
				{
					mRenderManager.setPreferredLightMode(LightMode.SinglePass);
					mRenderManager.setSinglePassLightBatchSize(2);
				}
				else
				{
					mRenderManager.setPreferredLightMode(LightMode.MultiPass);
				}	
				updateMsg();
			}
		}
	}
}