package examples.material;

import assets.manager.FileLoader;
import assets.manager.misc.FileInfo;
import examples.BasicExample;
import haxe.ds.StringMap;
import org.angle3d.Angle3D;
import org.angle3d.light.AmbientLight;
import org.angle3d.light.PointLight;
import org.angle3d.material.BlendMode;
import org.angle3d.material.CullMode;
import org.angle3d.material.Material;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.queue.QueueBucket;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.shape.Quad;
import org.angle3d.math.Color;
import org.angle3d.texture.ATFTexture;
import org.angle3d.utils.Stats;

class AlphaMapTest extends BasicExample
{
	static function main() 
	{
		flash.Lib.current.addChild(new AlphaMapTest());
	}

	public function new() 
	{
		super();
		Angle3D.maxAgalVersion = 2;
		
	}
	
	private var baseURL:String;
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);
		
		mViewPort.backgroundColor = new Color(0.5, 0.5, 0.5, 1);

		baseURL = "../assets/sponza/textures/";

		var assetLoader:FileLoader = new FileLoader();
		assetLoader.queueBinary(baseURL + "vase_plant.atf");
		assetLoader.queueBinary(baseURL + "vase_plant_mask.atf");
		assetLoader.onFilesLoaded.addOnce(_loadComplete);
		assetLoader.loadQueuedFiles();
	}

	private var mat:Material;
	private var plane:Quad;

	private function _loadComplete(fileMap:StringMap<FileInfo>):Void
	{
		flyCam.setDragToRotate(true);
		flyCam.setMoveSpeed(100);
		
		var fileInfo:FileInfo = fileMap.get(baseURL + "vase_plant.atf");
		var texture:ATFTexture = new ATFTexture(fileInfo.data);
		
		fileInfo = fileMap.get(baseURL + "vase_plant_mask.atf");
		var maskTexture:ATFTexture = new ATFTexture(fileInfo.data);
		
		var am:AmbientLight = new AmbientLight();
		am.color = new Color(1, 1, 1);
		scene.addLight(am);
		
		var pl = new PointLight();
		pl.color = Color.Random();
		pl.radius = 1000;
		pl.position = new Vector3f(0, 500, 0);
		scene.addLight(pl);
		
		mat = new Material();
		mat.setTransparent(true);
		mat.getAdditionalRenderState().setCullMode(CullMode.NONE);
		mat.getAdditionalRenderState().setBlendMode(BlendMode.Alpha);
		mat.load(Angle3D.materialFolder + "material/unshaded.mat");
		mat.setTexture("u_DiffuseMap", texture);
		mat.setTexture("u_AlphaMap", maskTexture);
		//mat.setFloat("u_AlphaDiscardThreshold", 0.01);
		
		plane = new Quad(200, 200,false);

		var geometry:Geometry = new Geometry("plane", plane);
		scene.attachChild(geometry);
		geometry.setMaterial(mat);
		geometry.localQueueBucket = QueueBucket.Transparent;
		//geometry.setTranslationXYZ(-100,-100,0);
		geometry.rotateAngles(90, 0, 0);
		
		var mat2 = new Material();
		mat2.setTransparent(true);
		mat2.getAdditionalRenderState().setCullMode(CullMode.NONE);
		mat2.getAdditionalRenderState().setBlendMode(BlendMode.Alpha);
		mat2.load(Angle3D.materialFolder + "material/lighting.mat");
		mat2.setFloat("u_Shininess", 10);
		mat2.setBoolean("useMaterialColor", false);
		mat2.setBoolean("useVertexLighting", false);
		mat2.setBoolean("useLowQuality", false);
		mat2.setColor("u_Ambient",  Color.Random());
		mat2.setColor("u_Specular", Color.Random());
		mat2.setTexture("u_DiffuseMap", texture);
		mat2.setTexture("u_AlphaMap", maskTexture);
		//mat2.setFloat("u_AlphaDiscardThreshold", 0.01);
		
		var geometry2:Geometry = new Geometry("plane2", plane);
		scene.attachChild(geometry2);
		geometry2.setMaterial(mat2);
		geometry2.localQueueBucket = QueueBucket.Transparent;
		geometry2.setTranslationXYZ(-100,0,10);
		geometry2.rotateAngles(90, 0, 0);

		camera.location.setTo(0, 0, 400);
		camera.lookAt(new Vector3f(0, 0, 0), Vector3f.Y_AXIS);

		reshape(mContextWidth, mContextHeight);
		
		start();
		Stats.show(stage);
	}
	
}