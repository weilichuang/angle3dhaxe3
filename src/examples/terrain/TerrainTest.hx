package examples.terrain;

import assets.manager.FileLoader;
import assets.manager.misc.FileInfo;
import examples.BasicExample;
import flash.Vector;
import flash.display.BitmapData;
import flash.ui.Keyboard;
import haxe.ds.StringMap;
import org.angle3d.Angle3D;
import org.angle3d.input.controls.KeyTrigger;
import org.angle3d.material.CullMode;
import org.angle3d.material.Material;
import org.angle3d.material.MipFilter;
import org.angle3d.material.WrapMode;
import org.angle3d.math.Vector3f;
import org.angle3d.terrain.Terrain;
import org.angle3d.terrain.geomipmap.TerrainLodControl;
import org.angle3d.terrain.geomipmap.TerrainQuad;
import org.angle3d.terrain.geomipmap.lodcalc.DistanceLodCalculator;
import org.angle3d.terrain.heightmap.ImageBasedHeightMap;
import org.angle3d.texture.BitmapTexture;
import org.angle3d.texture.Texture2D;

class TerrainTest extends BasicExample
{
	static function main() 
	{
		flash.Lib.current.addChild(new TerrainTest());
	}

	private var matRock:Material;
	private var terrain:TerrainQuad;
	private var baseURL:String;
	
	private var grassScale:Float = 64;
    private var dirtScale:Float = 16;
    private var rockScale:Float = 128;
	
	private var triPlanar:Bool = false;
	public function new() 
	{
		super();
		
		baseURL = "../assets/terrain/";
		
		var assetLoader:FileLoader = new FileLoader();
		assetLoader.queueImage(baseURL + "alphamap.png");
		assetLoader.queueImage(baseURL + "mountains512.png");
		assetLoader.queueImage(baseURL + "grass.jpg");
		assetLoader.queueImage(baseURL + "dirt.jpg");
		assetLoader.queueImage(baseURL + "road.jpg");
		assetLoader.onFilesLoaded.addOnce(_loadComplete);
		assetLoader.loadQueuedFiles();
	}
	
	private function _loadComplete(fileMap:StringMap<FileInfo>):Void
	{
		var heightMapData:BitmapData = fileMap.get(baseURL + "mountains512.png").data;
		var heightMap:ImageBasedHeightMap = new ImageBasedHeightMap(heightMapData, 1);
		heightMap.load();
		
		var alphaTexture:BitmapTexture = new BitmapTexture(fileMap.get(baseURL + "alphamap.png").data);
		
		var grassTexture:BitmapTexture = new BitmapTexture(fileMap.get(baseURL + "grass.jpg").data,true);
		grassTexture.wrapMode = WrapMode.REPEAT;
		grassTexture.mipFilter = MipFilter.MIPLINEAR;
		var dirtTexture:BitmapTexture = new BitmapTexture(fileMap.get(baseURL + "dirt.jpg").data,true);
		dirtTexture.wrapMode = WrapMode.REPEAT;
		dirtTexture.mipFilter = MipFilter.MIPLINEAR;
		var rockTexture:BitmapTexture = new BitmapTexture(fileMap.get(baseURL + "road.jpg").data,true);
		rockTexture.wrapMode = WrapMode.REPEAT;
		rockTexture.mipFilter = MipFilter.MIPLINEAR;
		
		matRock = new Material();
		matRock.load(Angle3D.materialFolder + "material/terrain.mat");
		//matRock.getAdditionalRenderState().setCullMode(CullMode.NONE);
		
		matRock.setBoolean("useTriPlanarMapping", false);
		
		matRock.setTexture("u_AlphaMap", alphaTexture);
		
		matRock.setTexture("u_TexMap1", grassTexture);
		matRock.setFloat("u_TexScale1", grassScale);
		
		matRock.setTexture("u_TexMap2", dirtTexture);
		matRock.setFloat("u_TexScale2", dirtScale);
		
		matRock.setTexture("u_TexMap3", rockTexture);
		matRock.setFloat("u_TexScale3", rockScale);
		
		terrain = new TerrainQuad("terrain");
		terrain.init(65, 513, heightMap.getHeightMap(), 513);
		
		var control:TerrainLodControl = new TerrainLodControl(terrain, camera);
        control.setLodCalculator( new DistanceLodCalculator(65, 2.7) ); // patch size, and a multiplier
        terrain.addControl(control);
		
		terrain.setMaterial(matRock);
		terrain.setLocalTranslation(new Vector3f(0, -100, 0));
        terrain.setLocalScale(new Vector3f(2, 0.5, 2));
		scene.attachChild(terrain);
		
		camera.setLocation(new Vector3f(0, 10, -10));
        camera.lookAtDirection(new Vector3f(0, -1.5, -1).normalizeLocal(), Vector3f.Y_AXIS);
		
		flyCam.setMoveSpeed(200);
		
		start();
		
		showMsg("Hit P to switch to tri-planar texturing,useTriPlanarMapping:" + triPlanar);
	}
	
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);
		
		mInputManager.addTrigger("triPlanar", new KeyTrigger(Keyboard.P));
		mInputManager.addListener(this, Vector.ofArray(["triPlanar"]));
	}
	
	override public function onAction(name:String, isPressed:Bool, tpf:Float):Void
	{
		super.onAction(name, isPressed, tpf);
		
		if (name == "triPlanar" && isPressed)
		{
            triPlanar = !triPlanar;
			if (triPlanar)
			{
				matRock.setBoolean("useTriPlanarMapping", true);
				// planar textures don't use the mesh's texture coordinates but real world coordinates,
				// so we need to convert these texture coordinate scales into real world scales so it looks
				// the same when we switch to/from tr-planar mode
				matRock.setFloat("u_TexScale1", 1 / (512 / grassScale));
				matRock.setFloat("u_TexScale2", 1 / (512 / dirtScale));
				matRock.setFloat("u_TexScale3", 1 / (512 / rockScale));
			} 
			else 
			{
				matRock.setBoolean("useTriPlanarMapping", false);
				matRock.setFloat("u_TexScale1", grassScale);
				matRock.setFloat("u_TexScale2", dirtScale);
				matRock.setFloat("u_TexScale3", rockScale);
			}
			
			showMsg("Hit P to switch to tri-planar texturing,useTriPlanarMapping:" + triPlanar);
        }
	}
	
	override public function simpleUpdate(tpf:Float):Void
	{
		
	}
	
}