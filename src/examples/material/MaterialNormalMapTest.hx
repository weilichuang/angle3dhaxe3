package examples.material;

import assets.manager.FileLoader;
import assets.manager.misc.FileInfo;
import examples.skybox.DefaultSkyBox;
import flash.display.BitmapData;
import flash.display3D.Context3DWrapMode;
import flash.Vector;
import haxe.ds.StringMap;
import org.angle3d.Angle3D;
import org.angle3d.app.SimpleApplication;
import org.angle3d.io.parser.ogre.OgreMeshXmlParser;
import org.angle3d.light.AmbientLight;
import org.angle3d.light.PointLight;
import org.angle3d.material.Material;
import org.angle3d.material.VarType;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector2f;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.queue.ShadowMode;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.LightNode;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.scene.Node;
import org.angle3d.scene.shape.Box;
import org.angle3d.scene.shape.Sphere;
import org.angle3d.texture.BitmapTexture;
import org.angle3d.texture.Texture2D;
import org.angle3d.utils.Stats;
import org.angle3d.utils.TangentBinormalGenerator;

@:bitmap("../assets/embed/wood.jpg") class ROCK_ASSET extends flash.display.BitmapData { }

class MaterialNormalMapTest extends SimpleApplication
{
	static function main() 
	{
		flash.Lib.current.addChild(new MaterialNormalMapTest());
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

		baseURL = "../assets/ogre/boat/";

		var assetLoader:FileLoader = new FileLoader();
		assetLoader.queueText(baseURL + "boat.mesh.xml");
		assetLoader.queueImage(baseURL + "boat.png");
		assetLoader.queueImage(baseURL + "boat_normal.png");
		assetLoader.onFilesLoaded.addOnce(_loadComplete);
		assetLoader.loadQueuedFiles();
	}

	private var mat:Material;
	private var meshes:Array<Mesh>;

	private var _center:Vector3f;
	private var texture:Texture2D;
	private var normalTexture:Texture2D;
	
	private var pl:PointLight;
	private var pointLightNode:Node;

	private function _loadComplete(files:StringMap<FileInfo>):Void
	{
		flyCam.setDragToRotate(true);
		
		//mRenderManager.setPreferredLightMode(LightMode.SinglePass);
		//mRenderManager.setSinglePassLightBatchSize(2);
		
		var sphere:Sphere = new Sphere(2, 32, 32);
		var mat2:Material = new Material();
		mat2.load(Angle3D.materialFolder + "material/unshaded.mat");
		var groundTexture = new BitmapTexture(new ROCK_ASSET(0, 0));
		groundTexture.wrapMode = Context3DWrapMode.REPEAT;
		mat2.setTextureParam("u_DiffuseMap", VarType.TEXTURE2D, groundTexture);
		
		var lightModel:Geometry = new Geometry("Light", sphere);
		lightModel.setMaterial(mat2);
		
		pointLightNode = new Node("lightParentNode");
		pointLightNode.attachChild(lightModel);
		scene.attachChild(pointLightNode);
		
		pl = new PointLight();
		pl.color = new Color(1, 0, 0, 1);
		pl.radius = 100;
		scene.addLight(pl);
		
		var lightNode:LightNode = new LightNode("pointLight", pl);
		pointLightNode.attachChild(lightNode);
		
		//var sky : DefaultSkyBox = new DefaultSkyBox(500);
		//scene.attachChild(sky);
//
		//var directionLight:DirectionalLight = new DirectionalLight();
		//directionLight.color = new Color(0, 1, 0, 1);
		//directionLight.direction = new Vector3f(0, 1, 0);
		//scene.addLight(directionLight);
		
		var al:AmbientLight = new AmbientLight();
		al.color = new Color(0.3, 0.3, 0.3, 1);
		scene.addLight(al);
		
		texture = new BitmapTexture(files.get(baseURL + "boat.png").data);
		normalTexture = new BitmapTexture(files.get(baseURL + "boat_normal.png").data);
		
		//TODO 需要生成Tagent
		var parser:OgreMeshXmlParser = new OgreMeshXmlParser();
		var meshes:Vector<Mesh> = parser.parse(files.get(baseURL + "boat.mesh.xml").data);
		if (meshes.length == 0)
			return;
			
		TangentBinormalGenerator.generateMesh(meshes[0]);

		var boat:Geometry = new Geometry("boat", meshes[0]);
		scene.attachChild(boat);
		boat.setLocalScaleXYZ(10, 10, 10);

		var mat:Material = new Material();
		mat.load(Angle3D.materialFolder + "material/lighting.mat");
		mat.setFloat("u_Shininess", 32);
        mat.setBoolean("useMaterialColor", false);
		mat.setBoolean("useVertexLighting", false);
		mat.setBoolean("useLowQuality", false);
        mat.setColor("u_Ambient",  Color.White());
        mat.setColor("u_Diffuse",  new Color(0.8,0.8,0.8));
        mat.setColor("u_Specular", Color.White());
		mat.setTexture("u_DiffuseMap", texture);
		mat.setTexture("u_NormalMap", normalTexture);
		boat.setMaterial(mat);
		
		_center = new Vector3f(0, 0, 0);

		camera.location.setTo(Math.cos(angle) * 80, 60, Math.sin(angle) * 80);
		camera.lookAt(_center, Vector3f.Y_AXIS);
		
		flyCam.setMoveSpeed(20);

		reshape(mContextWidth, mContextHeight);
		
		start();
		Stats.show(stage);
	}

	private var angle:Float = -1.5;

	override public function simpleUpdate(tpf:Float):Void
	{
		angle += 0.03;
		angle %= FastMath.TWO_PI();
		
		if (angle > FastMath.TWO_PI())
		{
			//pl.color = new Color(Math.random(), Math.random(), Math.random());
			//fillMaterial.color = pl.color.getColor();
		}

		//camera.location.setTo(Math.cos(angle) * 100, 15, Math.sin(angle) * 100);
		//camera.lookAt(_center, Vector3f.Y_AXIS);
		
		pointLightNode.setTranslationXYZ(Math.cos(angle) * 50, 10, Math.sin(angle) * 50);
	}
}
