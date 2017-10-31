package examples.material;

import org.angle3d.asset.FilesLoader;
import org.angle3d.asset.FileInfo;

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
import org.angle3d.scene.shape.WireframeShape;
import org.angle3d.scene.shape.WireframeUtil;
import org.angle3d.scene.WireframeGeometry;
import org.angle3d.texture.BitmapTexture;
import org.angle3d.texture.Texture2D;
import org.angle3d.utils.Stats;
import org.angle3d.utils.TangentBinormalGenerator;

class MaterialNormalMapTest extends BasicExample
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

		var assetLoader:FilesLoader = new FilesLoader();
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

	private function _loadComplete(loader:FilesLoader):Void
	{
		flyCam.setDragToRotate(true);
		
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
		//var directionLight:DirectionalLight = new DirectionalLight();
		//directionLight.color = new Color(0, 1, 0, 1);
		//directionLight.direction = new Vector3f(0.5, 1, 0);
		//scene.addLight(directionLight);
		
		var al:AmbientLight = new AmbientLight();
		al.color = new Color(0.3, 0.3, 0.3, 1);
		scene.addLight(al);
		
		texture = new BitmapTexture(loader.getAssetByUrl(baseURL + "boat.png").info.content);
		normalTexture = new BitmapTexture(loader.getAssetByUrl(baseURL + "boat_normal.png").info.content);
		
		var parser:OgreMeshXmlParser = new OgreMeshXmlParser();
		var meshes:Vector<Mesh> = parser.parse(loader.getAssetByUrl(baseURL + "boat.mesh.xml").info.content);
		if (meshes.length == 0)
			return;
			
		TangentBinormalGenerator.generateMesh(meshes[0]);
		//
		//var wireMat:Material = new Material();
		//wireMat.load(Angle3D.materialFolder + "material/wireframe.mat");
		//wireMat.setFloat("u_thickness", 0.001);
		//wireMat.setBoolean("useVertexColor", true);
		//
		//var wire:WireframeShape = TangentBinormalGenerator.genTbnLines(meshes[0], 0.08);
		//var wireGeom:WireframeGeometry = new WireframeGeometry("wireBoat", wire);
		//wireGeom.setMaterial(wireMat);
		//wireGeom.setLocalScaleXYZ(10, 10, 10);
		//scene.attachChild(wireGeom);

		var boat:Geometry = new Geometry("boat", meshes[0]);
		scene.attachChild(boat);
		boat.setLocalScaleXYZ(10, 10, 10);

		var mat:Material = new Material();
		mat.load(Angle3D.materialFolder + "material/lighting.mat");
        mat.setFloat("u_Shininess", 32);
        mat.setBoolean("useMaterialColor", true);
        mat.setColor("u_Ambient",  new Color(0.2,0.2,0.2));
        mat.setColor("u_Diffuse",  new Color(0.8,0.8,0.8));
        mat.setColor("u_Specular", new Color(0.3,0.3,0.3));
		mat.setTexture("u_DiffuseMap", texture);
		mat.setTexture("u_NormalMap", normalTexture);
		boat.setMaterial(mat);
		
		_center = new Vector3f(0, 0, 0);

		camera.location.setTo(Math.cos(angle) * 80, 60, Math.sin(angle) * 80);
		camera.lookAt(_center, Vector3f.UNIT_Y);
		
		flyCam.setMoveSpeed(20);

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
