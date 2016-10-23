package examples.terrain;

import examples.BasicExample;
import flash.Vector;
import flash.display.BitmapData;
import flash.ui.Keyboard;
import org.angle3d.Angle3D;
import org.angle3d.asset.FilesLoader;
import org.angle3d.asset.LoaderType;
import org.angle3d.input.controls.KeyTrigger;
import org.angle3d.material.Material;
import org.angle3d.math.Vector3f;
import org.angle3d.terrain.geomipmap.TerrainLodControl;
import org.angle3d.terrain.geomipmap.TerrainQuad;
import org.angle3d.terrain.geomipmap.lodcalc.DistanceLodCalculator;
import org.angle3d.terrain.heightmap.ImageBasedHeightMap;
import org.angle3d.texture.BitmapTexture;
import org.angle3d.texture.MipFilter;
import org.angle3d.texture.WrapMode;

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
		
		var assetLoader:FilesLoader = new FilesLoader();
		assetLoader.queueFile(baseURL + "alphamap.png",LoaderType.IMAGE);
		assetLoader.queueFile(baseURL + "mountains512.png",LoaderType.IMAGE);
		assetLoader.queueFile(baseURL + "grass.jpg",LoaderType.IMAGE);
		assetLoader.queueFile(baseURL + "dirt.jpg",LoaderType.IMAGE);
		assetLoader.queueFile(baseURL + "road.jpg",LoaderType.IMAGE);
		assetLoader.onFilesLoaded.addOnce(_loadComplete);
		assetLoader.loadQueuedFiles();
	}
	
	private function _loadComplete(loader:FilesLoader):Void
	{
		var heightMapData:BitmapData = loader.getAssetByUrl(baseURL + "mountains512.png").info.content;
		var heightMap:ImageBasedHeightMap = new ImageBasedHeightMap(heightMapData, 1);
		heightMap.load();
		
		var alphaTexture:BitmapTexture = new BitmapTexture(loader.getAssetByUrl(baseURL + "alphamap.png").info.content);
		
		var grassTexture:BitmapTexture = new BitmapTexture(loader.getAssetByUrl(baseURL + "grass.jpg").info.content,true);
		grassTexture.wrapMode = WrapMode.REPEAT;
		grassTexture.mipFilter = MipFilter.MIPLINEAR;
		var dirtTexture:BitmapTexture = new BitmapTexture(loader.getAssetByUrl(baseURL + "dirt.jpg").info.content,true);
		dirtTexture.wrapMode = WrapMode.REPEAT;
		dirtTexture.mipFilter = MipFilter.MIPLINEAR;
		var rockTexture:BitmapTexture = new BitmapTexture(loader.getAssetByUrl(baseURL + "road.jpg").info.content,true);
		rockTexture.wrapMode = WrapMode.REPEAT;
		rockTexture.mipFilter = MipFilter.MIPLINEAR;
		
		matRock = new Material();
		matRock.load(Angle3D.materialFolder + "material/terrain.mat");
		//matRock.getAdditionalRenderState().setCullMode(CullMode.NONE);
		
		matRock.setBoolean("useTriPlanarMapping", false);
		
		matRock.setTexture("u_AlphaMap", alphaTexture);
		matRock.setTexture("u_TexMap1", grassTexture);
		matRock.setTexture("u_TexMap2", dirtTexture);
		matRock.setTexture("u_TexMap3", rockTexture);
		
		matRock.setVector3("u_TexScale", new Vector3f(grassScale, dirtScale, rockScale));
		
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
        camera.lookAtDirection(new Vector3f(0, -1.5, -1).normalizeLocal(), Vector3f.UNIT_Y);
		
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
				matRock.setVector3("u_TexScale", new Vector3f(1 / (512 / grassScale),1 / (512 / dirtScale),1 / (512 / rockScale)));
			} 
			else 
			{
				matRock.setBoolean("useTriPlanarMapping", false);
				matRock.setVector3("u_TexScale", new Vector3f(grassScale,dirtScale,rockScale));
			}
			
			showMsg("Hit P to switch to tri-planar texturing,useTriPlanarMapping:" + triPlanar);
        }
	}
	
	override public function simpleUpdate(tpf:Float):Void
	{
		super.simpleUpdate(tpf);
	}
	
}