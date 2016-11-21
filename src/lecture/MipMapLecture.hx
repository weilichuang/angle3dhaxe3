package lecture;

import examples.BasicExample;
import flash.Vector;
import flash.display.BitmapData;
import flash.ui.Keyboard;
import lecture.BasicLecture;
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
class MipMapLecture extends BasicLecture
{

	static function main() 
	{
		flash.Lib.current.addChild(new MipMapLecture());
	}
	
	private var baseURL:String;
	private var diffuseMap:Texture2D;
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
		assetLoader.onFilesLoaded.addOnce(_loadComplete);
		assetLoader.loadQueuedFiles();
	}

	private var mat:Material;
	private function setupFloor():Void
	{
		mat = new Material();
		mat.load(Angle3D.materialFolder + "material/unshaded.mat");
		mat.setTexture("u_DiffuseMap", diffuseMap);

		var quad:Quad = new Quad(100, 100);
		quad.scaleTextureCoordinates(new Vector2f(10, 10));
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
		diffuseMap.mipFilter = MipFilter.MIPNONE;

		setupFloor();
		
		camera.setLocation(new Vector3f(80.445636, 30.162927, 30));
        camera.lookAt(new Vector3f(60,0,0), Vector3f.UNIT_Y);
        flyCam.setMoveSpeed(30);
		flyCam.setDragToRotate(true);
		
		mInputManager.addTrigger("space", new KeyTrigger(Keyboard.SPACE));
		mInputManager.addListener(this, Vector.ofArray(["space"]));
		
		start();
	}

	override public function onAction(name:String, value:Bool, tpf:Float):Void
	{
		super.onAction(name, value, tpf);

		if (value)
		{
			if (name == "space")
			{
				if(diffuseMap.mipFilter == MipFilter.MIPLINEAR)
					diffuseMap.mipFilter = MipFilter.MIPNONE;
				else
					diffuseMap.mipFilter = MipFilter.MIPLINEAR;
			}
		}
	}
}