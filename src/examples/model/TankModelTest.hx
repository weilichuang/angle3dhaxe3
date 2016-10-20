package examples.model;

import flash.Vector;
import org.angle3d.Angle3D;
import org.angle3d.asset.FileInfo;
import org.angle3d.asset.FilesLoader;
import org.angle3d.input.ChaseCamera;
import org.angle3d.io.parser.ogre.OgreMeshXmlParser;
import org.angle3d.light.DirectionalLight;
import org.angle3d.material.Material;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.Node;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.texture.BitmapTexture;

class TankModelTest extends BasicExample
{
	static function main() 
	{
		flash.Lib.current.addChild(new TankModelTest());
	}
	
	private var baseURL:String;
	private var angle:Float = -1.5;
	private var _loadedCount:Int = 0;
	private var _loadCount:Int = 0;
	private var tankMeshes:Vector<Mesh>;
	private var material:Material;
	
	public function new()
	{
		Angle3D.maxAgalVersion = 2;
		super();
	}
	
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);

		baseURL = "../assets/tank/";

		var assetLoader:FilesLoader = new FilesLoader();
		assetLoader.queueText(baseURL + "tank.mesh.xml");
		assetLoader.queueImage(baseURL + "tank_diffuse.jpg");
		assetLoader.queueImage(baseURL + "tank_normals.png");
		assetLoader.queueImage(baseURL + "tank_specular.jpg");
		assetLoader.queueImage(baseURL + "tank_glow_map.jpg");
		assetLoader.onFilesLoaded.addOnce(_loadComplete);
		assetLoader.onFileLoaded.add(_loadFile);
		assetLoader.loadQueuedFiles();
		
		_loadCount = assetLoader.getFileCount();
		
		showMsg("资源加载中"+_loadedCount+"/"+_loadCount+"...","center");
	}
	
	private function _loadFile(file:FileInfo):Void
	{
		_loadedCount++;
		showMsg("资源加载中" + _loadedCount + "/" + _loadCount + "...", "center");
	}
	
	private function _loadComplete(loader:FilesLoader):Void
	{
		hideMsg();
		
		material = new Material();
		material.load(Angle3D.materialFolder + "material/lighting.mat");
		material.setTexture("u_DiffuseMap", new BitmapTexture(loader.getAssetByUrl(baseURL + "tank_diffuse.jpg").info.content));
		material.setTexture("u_NormalMap", new BitmapTexture(loader.getAssetByUrl(baseURL + "tank_normals.png").info.content));
		material.setTexture("u_SpecularMap", new BitmapTexture(loader.getAssetByUrl(baseURL + "tank_specular.jpg").info.content));
		//material.setTexture("u_GlowMap", new BitmapTexture(loader.getAssetByUrl(baseURL + "tank_glow_map.jpg").info.content));

		var parser:OgreMeshXmlParser = new OgreMeshXmlParser();
		tankMeshes = parser.parse(loader.getAssetByUrl(baseURL + "tank.mesh.xml").info.content);

		var node:Node = new Node("tank");
		for (i in 0...tankMeshes.length)
		{
			var mesh:Mesh = tankMeshes[i];
			var geometry:Geometry = new Geometry(mesh.id, mesh);
			geometry.setMaterial(material);
			node.attachChild(geometry);
		}
		scene.attachChild(node);
		
		var lightDir:Vector3f = new Vector3f(-0.8719428, -0.46824604, 0.14304268);
        var dl:DirectionalLight = new DirectionalLight();
        dl.color = new Color(1.0, 0.92, 0.75, 1);
        dl.direction = lightDir;

        var lightDir2:Vector3f = new Vector3f(0.70518064, 0.5902297, -0.39287305);
        var dl2:DirectionalLight = new DirectionalLight();
        dl2.color = new Color(0.7, 0.85, 1.0, 1);
        dl2.direction = lightDir2;

        scene.addLight(dl);
        scene.addLight(dl2);
		
		camera.location.setTo(0, 0, 20);
		camera.lookAt(new Vector3f(), Vector3f.UNIT_Y);
		
		flyCam.setDragToRotate(true);
		flyCam.setMoveSpeed(2.0);
		flyCam.setEnabled(false);

		var cc : ChaseCamera = new ChaseCamera(this.camera, node, mInputManager);
		//cc.setSmoothMotion(true);
		cc.setEnabled(true);
		cc.setDragToRotate(true);
		cc.setRotationSpeed(5);

		start();
	}

	override public function simpleUpdate(tpf:Float):Void
	{
		super.simpleUpdate(tpf);
		
		angle += 0.01;
		angle %= FastMath.TWO_PI;
	}
}
