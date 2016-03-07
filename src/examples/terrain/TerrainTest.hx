package examples.terrain;

import assets.manager.FileLoader;
import assets.manager.misc.FileInfo;
import examples.BasicExample;
import flash.display.BitmapData;
import haxe.ds.StringMap;
import org.angle3d.Angle3D;
import org.angle3d.material.Material;
import org.angle3d.material.WrapMode;
import org.angle3d.math.Vector3f;
import org.angle3d.terrain.Terrain;
import org.angle3d.terrain.geomipmap.TerrainQuad;
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
		
		var alphaTexture:BitmapTexture = new BitmapTexture(fileMap.get(baseURL + "alphamap.png").data);
		
		var grassTexture:BitmapTexture = new BitmapTexture(fileMap.get(baseURL + "grass.jpg").data);
		grassTexture.wrapMode = WrapMode.REPEAT;
		var dirtTexture:BitmapTexture = new BitmapTexture(fileMap.get(baseURL + "dirt.jpg").data);
		dirtTexture.wrapMode = WrapMode.REPEAT;
		var rockTexture:BitmapTexture = new BitmapTexture(fileMap.get(baseURL + "road.jpg").data);
		rockTexture.wrapMode = WrapMode.REPEAT;
		
		matRock = new Material();
		matRock.load(Angle3D.materialFolder + "material/terrain.mat");
		
		matRock.setBoolean("useTriPlanarMapping", false);
		
		matRock.setTexture("u_AlphaMap", alphaTexture);
		
		matRock.setTexture("u_TexMap1", grassTexture);
		matRock.setFloat("u_Tex1Scale", grassScale);
		
		matRock.setTexture("u_TexMap2", dirtTexture);
		matRock.setFloat("u_Tex2Scale", dirtScale);
		
		matRock.setTexture("u_TexMap3", rockTexture);
		matRock.setFloat("u_Tex3Scale", rockScale);
		
		terrain = new TerrainQuad("terrain");
		terrain.init2(65, 513, new Vector3f(1, 1, 1), heightMap.getHeightMap());
		terrain.setMaterial(matRock);
		terrain.setLocalTranslation(new Vector3f(0, -100, 0));
        terrain.setLocalScale(new Vector3f(2, 0.5, 2));
		scene.attachChild(terrain);
		
		camera.setLocation(new Vector3f(0, 10, -10));
        camera.lookAtDirection(new Vector3f(0, -1.5, -1).normalizeLocal(), Vector3f.Y_AXIS);
		
		start();
	}
	
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);
	}
	
	override public function simpleUpdate(tpf:Float):Void
	{
		
	}
	
}