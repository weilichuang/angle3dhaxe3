package examples.material;

import examples.skybox.DefaultSkyBox;
import flash.Vector;
import flash.display.BitmapData;
import org.angle3d.Angle3D;
import org.angle3d.asset.FilesLoader;
import org.angle3d.input.ChaseCamera;
import org.angle3d.io.parser.ang.AngReader;
import org.angle3d.io.parser.obj.ObjParser;
import org.angle3d.light.AmbientLight;
import org.angle3d.light.DirectionalLight;
import org.angle3d.light.PointLight;
import org.angle3d.material.LightMode;
import org.angle3d.material.Material;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.LightNode;
import org.angle3d.scene.Node;
import org.angle3d.scene.SkyBox;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.scene.shape.Sphere;
import org.angle3d.texture.BitmapTexture;
import org.angle3d.texture.CubeTextureMap;
import org.angle3d.texture.Texture2D;

class TestHead extends BasicExample
{
	static function main() 
	{
		flash.Lib.current.addChild(new TestHead());
	}
	
	private var baseURL:String;
	private var skyURL:String;
	public function new()
	{
		Angle3D.maxAgalVersion = 2;
		super();
	}
	
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);

		baseURL = "../assets/obj/";
		
		skyURL = "../assets/sky/";

		var assetLoader:FilesLoader = new FilesLoader();
		assetLoader.queueBinary(baseURL + "head.ang");
		assetLoader.queueImage(baseURL + "head_diffuse.jpg");
		assetLoader.queueImage(baseURL + "head_normals.jpg");
		assetLoader.queueImage(baseURL + "head_specular.jpg");
		assetLoader.queueImage(baseURL + "head_AO.jpg");
		assetLoader.queueImage(skyURL + "left.jpg");
		assetLoader.queueImage(skyURL + "bottom.jpg");
		assetLoader.queueImage(skyURL + "front.jpg");
		assetLoader.queueImage(skyURL + "right.jpg");
		assetLoader.queueImage(skyURL + "top.jpg");
		assetLoader.queueImage(skyURL + "back.jpg");
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
	
	private function getBitmap(loader:FilesLoader,name:String):BitmapData
	{
		return loader.getAssetByUrl(name).info.content;
	}

	private function _loadComplete(loader:FilesLoader):Void
	{
		var px : BitmapData = getBitmap(loader,skyURL + "right.jpg");
		var nx : BitmapData = getBitmap(loader,skyURL + "left.jpg");
		var py : BitmapData = getBitmap(loader,skyURL + "top.jpg");
		var ny : BitmapData = getBitmap(loader,skyURL + "bottom.jpg");
		var pz : BitmapData = getBitmap(loader,skyURL + "front.jpg");
		var nz : BitmapData = getBitmap(loader,skyURL + "back.jpg");

		var cubeMap:CubeTextureMap = new CubeTextureMap(px, nx, py, ny, pz, nz);
		
		var sky:DefaultSkyBox = new DefaultSkyBox(500);
		scene.attachChild(sky);
		
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
		
		var directionLight:DirectionalLight = new DirectionalLight();
		directionLight.color = Color.Random();
		directionLight.direction = new Vector3f(0.5, 1, 0);
		scene.addLight(directionLight);
		
		var al:AmbientLight = new AmbientLight();
		al.color = new Color(0.5, 0.5, 0.5, 1);
		scene.addLight(al);
		
		texture = new BitmapTexture(getBitmap(loader,baseURL + "head_diffuse.jpg"));
		normalTexture = new BitmapTexture(getBitmap(loader,baseURL + "head_normals.jpg"));
		specularTexture = new BitmapTexture(getBitmap(loader,baseURL + "head_specular.jpg"));
		
		var mat:Material = new Material();
		mat.load(Angle3D.materialFolder + "material/lighting.mat");
        mat.setFloat("u_Shininess", 8);
        mat.setBoolean("useMaterialColor", true);
        mat.setColor("u_Ambient",  new Color(0.5, 0.5, 0.50));
        mat.setColor("u_Diffuse",  new Color(1.0, 1.0, 1.0));
        mat.setColor("u_Specular", new Color(1.0, 1.0, 1.0));
		mat.setTexture("u_DiffuseMap", texture);
		
		var mat1:Material = new Material();
		mat1.load(Angle3D.materialFolder + "material/lighting.mat");
        mat1.setFloat("u_Shininess", 8);
        mat1.setBoolean("useMaterialColor", true);
        mat1.setColor("u_Ambient",  new Color(0.5, 0.5, 0.50));
        mat1.setColor("u_Diffuse",  new Color(1.0, 1.0, 1.0));
        mat1.setColor("u_Specular", new Color(1.0, 1.0, 1.0));
		mat1.setTexture("u_DiffuseMap", texture);
		mat1.setTexture("u_SpecularMap", specularTexture);
		
		var mat2:Material = new Material();
		mat2.load(Angle3D.materialFolder + "material/lighting.mat");
        mat2.setFloat("u_Shininess", 8);
        mat2.setBoolean("useMaterialColor", true);
        mat2.setColor("u_Ambient",  new Color(0.5, 0.5, 0.50));
        mat2.setColor("u_Diffuse",  new Color(1.0, 1.0, 1.0));
        mat2.setColor("u_Specular", new Color(1.0, 1.0, 1.0));
		mat2.setTexture("u_DiffuseMap", texture);
		mat2.setTexture("u_NormalMap", normalTexture);
		mat2.setTexture("u_SpecularMap", specularTexture);
		//mat2.setVector3("u_FresnelParams", new Vector3f(0.2, 0.1, 0.5));
		//mat2.setTexture("u_EnvMap", cubeMap);
		
		
		var parser:ObjParser = new ObjParser();
		var meshInfo:Dynamic;
		var reader:AngReader = new AngReader();
		var meshes:Vector<Mesh> = reader.readMeshes(loader.getAssetByUrl(baseURL + "head.ang").info.content);

		var geomtry:Geometry = new Geometry(meshes[0].id, meshes[0]);
		geomtry.setMaterial(mat);
		geomtry.rotateAngles(0, Math.PI / 2, 0);
		geomtry.setTranslationXYZ( 0, 0, 10);
		scene.attachChild(geomtry);
		
		var geomtry1 = new Geometry(meshes[0].id+"_1", meshes[0]);
		geomtry1.setMaterial(mat1);
		geomtry1.rotateAngles(0, Math.PI / 2, 0);
		geomtry1.setTranslationXYZ( 0, 0, 0);
		scene.attachChild(geomtry1);
		
		var geomtry2 = new Geometry(meshes[0].id+"_2", meshes[0]);
		geomtry2.setMaterial(mat2);
		geomtry2.rotateAngles(0, Math.PI / 2, 0);
		geomtry2.setTranslationXYZ( 0, 0, -10);
		scene.attachChild(geomtry2);
		
		_center = new Vector3f(0, 0, 0);

		camera.location.setTo(0, 0, 20);
		camera.lookAt(new Vector3f(), Vector3f.UNIT_Y);
		
		flyCam.setDragToRotate(true);
		flyCam.setMoveSpeed(2.0);
		flyCam.setEnabled(false);

		var cc : ChaseCamera = new ChaseCamera(this.camera, geomtry1, mInputManager);
		cc.setSmoothMotion(true);
		cc.setEnabled(true);
		cc.setDragToRotate(true);
		cc.setRotationSpeed(5);
		cc.setMinVerticalRotation( -FastMath.HALF_PI);

		reshape(mContextWidth, mContextHeight);

		start();
	}

	private var angle:Float = -1.5;

	override public function simpleUpdate(tpf:Float):Void
	{
		angle += 0.01;
		angle %= FastMath.TWO_PI;
		
		pointLightNode.setTranslationXYZ(Math.cos(angle) * 40, 20, Math.sin(angle) * 40);
	}
}
