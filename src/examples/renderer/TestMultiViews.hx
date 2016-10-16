package examples.renderer;

import org.angle3d.Angle3D;
import org.angle3d.asset.FilesLoader;
import org.angle3d.asset.LoaderType;
import org.angle3d.io.parser.obj.ObjParser;
import org.angle3d.light.DirectionalLight;
import org.angle3d.material.Material;
import org.angle3d.math.Color;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.Camera;
import org.angle3d.renderer.ViewPort;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.mesh.Mesh;

class TestMultiViews extends BasicExample
{
	static function main() 
	{
		flash.Lib.current.addChild(new TestMultiViews());
	}
	
	private var baseURL:String;
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
		assetLoader.queueFile(baseURL + "Teapot.obj", LoaderType.TEXT);
		assetLoader.onFilesLoaded.addOnce(_loadComplete);
		assetLoader.loadQueuedFiles();
	}
	
	private function _loadComplete(loader:FilesLoader):Void
	{
		var dl:DirectionalLight = new DirectionalLight();
		dl.color = Color.White();
		dl.direction = new Vector3f( -1, -1, -1);
		scene.addLight(dl);
		
		var mat:Material = new Material();
		mat.load(Angle3D.materialFolder + "material/lighting.mat");
        mat.setFloat("u_Shininess", 32);
        mat.setBoolean("useMaterialColor", true);
        mat.setColor("u_Ambient",  new Color(0.2,0.2,0.2));
        mat.setColor("u_Diffuse",  new Color(0.8,0.8,0.8));
        mat.setColor("u_Specular", new Color(0.3,0.3,0.3));
		
		
		var parser:ObjParser = new ObjParser();
		var mesh:Mesh = parser.syncParse(loader.getAssetByUrl(baseURL + "Teapot.obj").info.content)[0].mesh;
		var geomtry:Geometry = new Geometry("Teapot", mesh);
		geomtry.setMaterial(mat);
		scene.attachChild(geomtry);
		geomtry.setLocalScaleXYZ(3, 3, 3);
		
		// Setup first view
        viewPort.backgroundColor = Color.Random();
		camera.name = "cam1";
        camera.setViewPortRect(0.5, 1, 0, 0.5);
        camera.setLocation(new Vector3f(3.3212643, 4.484704, 4.2812433));
        camera.setRotation(new Quaternion(-0.07680723, 0.92299235, -0.2564353, -0.27645364));

        // Setup second view
        var cam2:Camera = camera.clone("cam2");
        cam2.setViewPortRect(0, 0.5, 0, 0.5);
        cam2.setLocation(new Vector3f(-0.10947256, 1.5760219, 4.81758));
        cam2.setRotation(new Quaternion(0.0010108891, 0.99857414, -0.04928594, 0.020481428));

        var view2:ViewPort = mRenderManager.createMainView("Bottom Left", cam2);
        view2.setClearFlags(false, false, false);
        view2.attachScene(scene);

        // Setup third view
        var cam3:Camera = camera.clone("cam3");
        cam3.setViewPortRect(0, .5, .5, 1);
        cam3.setLocation(new Vector3f(0.2846221, 6.4271426, 0.23380789));
        cam3.setRotation(new Quaternion(0.004381671, 0.72363687, -0.69015175, 0.0045953835));

        var view3:ViewPort = mRenderManager.createMainView("Top Left", cam3);
        view3.setClearFlags(false, false, false);
        view3.attachScene(scene);

        // Setup fourth view
        var cam4:Camera = camera.clone("cam4");
        cam4.setViewPortRect(.5, 1, .5, 1);
        cam4.setLocation(new Vector3f(4.775564, 1.4548365, 0.11491505));
        cam4.setRotation(new Quaternion(0.02356979, -0.74957186, 0.026729556, 0.66096294));

        var view4:ViewPort = mRenderManager.createMainView("Top Right", cam4);
        view4.setClearFlags(false, false, false);
        view4.attachScene(scene);
		
		start();
	}
}