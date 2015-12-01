package examples.material;

import assets.manager.FileLoader;
import assets.manager.misc.FileInfo;
import flash.text.TextField;
import flash.Vector;
import haxe.ds.StringMap;
import org.angle3d.Angle3D;
import org.angle3d.app.SimpleApplication;
import org.angle3d.io.parser.ogre.OgreMeshXmlParser;
import org.angle3d.light.AmbientLight;
import org.angle3d.light.DirectionalLight;
import org.angle3d.light.PointLight;
import org.angle3d.material.Material;
import org.angle3d.material.LightMode;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.LightNode;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.scene.Node;
import org.angle3d.scene.shape.Sphere;
import org.angle3d.texture.BitmapTexture;
import org.angle3d.texture.Texture2D;
import org.angle3d.utils.Stats;
import org.angle3d.utils.TangentBinormalGenerator;

class TestBumpModel extends SimpleApplication
{
	static function main() 
	{
		flash.Lib.current.addChild(new TestBumpModel());
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

		baseURL = "../assets/ogre/signpost/";

		var assetLoader:FileLoader = new FileLoader();
		assetLoader.queueText(baseURL + "signpost.mesh.xml");
		assetLoader.queueImage(baseURL + "signpost.jpg");
		assetLoader.queueImage(baseURL + "signpost_normal.jpg");
		assetLoader.queueImage(baseURL + "signpost_specular.jpg");
		assetLoader.onFilesLoaded.addOnce(_loadComplete);
		assetLoader.loadQueuedFiles();
	}

	private var mat:Material;
	private var meshes:Array<Mesh>;

	private var _center:Vector3f;
	private var texture:Texture2D;
	private var normalTexture:Texture2D;
	private var specularTexture:Texture2D;
	
	private var pl:PointLight;
	private var pointLightNode:Node;

	private function _loadComplete(files:StringMap<FileInfo>):Void
	{
		flyCam.setDragToRotate(true);
		
		//使用SinglePass时，方向光显示效果和MutilPass不一样
		//mRenderManager.setPreferredLightMode(LightMode.SinglePass);
		//mRenderManager.setSinglePassLightBatchSize(2);
		
		var sphere:Sphere = new Sphere(1, 24, 24);
		var mat2:Material = new Material();
		mat2.load(Angle3D.materialFolder + "material/unshaded.mat");
		mat2.setColor("u_MaterialColor", Color.White());
		
		var lightModel:Geometry = new Geometry("Light", sphere);
		lightModel.setMaterial(mat2);
		
		pointLightNode = new Node("lightParentNode");
		pointLightNode.attachChild(lightModel);
		scene.attachChild(pointLightNode);
		
		pl = new PointLight();
		pl.color = Color.White();
		pl.radius = 150;
		scene.addLight(pl);
		
		var lightNode:LightNode = new LightNode("pointLight", pl);
		pointLightNode.attachChild(lightNode);
		
		//var sky : DefaultSkyBox = new DefaultSkyBox(500);
		//scene.attachChild(sky);
//
		var directionLight:DirectionalLight = new DirectionalLight();
		directionLight.color = new Color(0, 1, 0, 1);
		directionLight.direction = new Vector3f(0.5, 1, 0);
		scene.addLight(directionLight);
		
		var al:AmbientLight = new AmbientLight();
		al.color = new Color(0.5, 0.5, 0.5, 1);
		scene.addLight(al);
		
		texture = new BitmapTexture(files.get(baseURL + "signpost.jpg").data);
		normalTexture = new BitmapTexture(files.get(baseURL + "signpost_normal.jpg").data);
		specularTexture = new BitmapTexture(files.get(baseURL + "signpost_specular.jpg").data);
		
		var parser:OgreMeshXmlParser = new OgreMeshXmlParser();
		var meshes:Vector<Mesh> = parser.parse(files.get(baseURL + "signpost.mesh.xml").data);
		if (meshes.length == 0)
			return;
			
		TangentBinormalGenerator.generateMesh(meshes[0]);

		var boat:Geometry = new Geometry("boat", meshes[0]);
		scene.attachChild(boat);
		boat.setTranslationXYZ(-5, 0, 0);

		var mat:Material = new Material();
		mat.load(Angle3D.materialFolder + "material/lighting.mat");
        mat.setFloat("u_Shininess", 32);
        mat.setBoolean("useMaterialColor", true);
        mat.setColor("u_Ambient",  new Color(0.2,0.2,0.2));
        mat.setColor("u_Diffuse",  new Color(0.8,0.8,0.8));
        mat.setColor("u_Specular", new Color(1.0,1.0,1.0));
		mat.setTexture("u_DiffuseMap", texture);
		mat.setTexture("u_NormalMap", normalTexture);
		mat.setTexture("u_SpecularMap", specularTexture);
		boat.setMaterial(mat);
		
		var boat2:Geometry = new Geometry("boat", meshes[0]);
		scene.attachChild(boat2);
		boat2.setTranslationXYZ(0, 0, 0);
		
		var mat3:Material = new Material();
		mat3.load(Angle3D.materialFolder + "material/lighting.mat");
        mat3.setFloat("u_Shininess", 32);
        mat3.setBoolean("useMaterialColor", true);
        mat3.setColor("u_Ambient",  new Color(0.2,0.2,0.2));
        mat3.setColor("u_Diffuse",  new Color(0.8,0.8,0.8));
        mat3.setColor("u_Specular", new Color(1.0,1.0,1.0));
		mat3.setTexture("u_DiffuseMap", texture);
		mat3.setTexture("u_NormalMap", normalTexture);
		//mat3.setTexture("u_SpecularMap", specularTexture);
		boat2.setMaterial(mat3);
		
		var boat3:Geometry = new Geometry("boat", meshes[0]);
		scene.attachChild(boat3);
		boat3.setTranslationXYZ(5, 0, 0);
		
		var mat4:Material = new Material();
		mat4.load(Angle3D.materialFolder + "material/lighting.mat");
        mat4.setFloat("u_Shininess", 32);
        mat4.setBoolean("useMaterialColor", true);
        mat4.setColor("u_Ambient",  new Color(0.2,0.2,0.2));
        mat4.setColor("u_Diffuse",  new Color(0.8,0.8,0.8));
        mat4.setColor("u_Specular", new Color(1.0,1.0,1.0));
		mat4.setTexture("u_DiffuseMap", texture);
		//mat4.setTexture("u_NormalMap", normalTexture);
		//mat4.setTexture("u_SpecularMap", specularTexture);
		boat3.setMaterial(mat4);
		
		_center = new Vector3f(0, 0, 0);

		camera.location.setTo(Math.cos(angle) * 10, 10, Math.sin(angle) * 10);
		camera.lookAt(_center, Vector3f.Y_AXIS);
		
		flyCam.setMoveSpeed(20);

		reshape(mContextWidth, mContextHeight);
		
		var tf:TextField = new TextField();
		tf.selectable = false;
		tf.textColor = 0xffffff;
		tf.width = 400;
		tf.text = "左侧：普通贴图，中间：法线贴图&高光贴图，右侧：法线贴图";
		this.addChild(tf);
		
		start();
		Stats.show(stage);
	}

	private var angle:Float = -1.5;

	override public function simpleUpdate(tpf:Float):Void
	{
		angle += 0.01;
		angle %= FastMath.TWO_PI;
		
		pointLightNode.setTranslationXYZ(Math.cos(angle) * 40, 20, Math.sin(angle) * 40);
	}
}
