package examples.advanced;

import assets.manager.FileLoader;
import assets.manager.misc.FileInfo;
import flash.events.KeyboardEvent;
import flash.ui.Keyboard;
import flash.utils.ByteArray;
import flash.Vector;
import haxe.ds.StringMap;
import org.angle3d.Angle3D;
import org.angle3d.app.SimpleApplication;
import org.angle3d.cinematic.events.DirectionType;
import org.angle3d.cinematic.events.MotionEvent;
import org.angle3d.cinematic.LoopMode;
import org.angle3d.cinematic.MotionPath;
import org.angle3d.io.parser.obj.MtlParser;
import org.angle3d.io.parser.obj.ObjParser;
import org.angle3d.light.PointLight;
import org.angle3d.material.LightMode;
import org.angle3d.material.Material;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.math.Quaternion;
import org.angle3d.math.SplineType;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.scene.Node;
import org.angle3d.texture.ATFTexture;
import org.angle3d.texture.BitmapTexture;
import org.angle3d.utils.Logger;
import org.angle3d.utils.Stats;

class SponzaExample extends SimpleApplication
{

	static function main() 
	{
		flash.Lib.current.addChild(new SponzaExample());
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

		baseURL = "../assets/sponza/";
		
		var assetLoader:FileLoader = new FileLoader();
		assetLoader.queueText(baseURL + "sponza.obj");
		assetLoader.queueText(baseURL + "sponza.mtl");
		assetLoader.onFilesLoaded.addOnce(_loadComplete);
		assetLoader.loadQueuedFiles();
		
		//TODO single pass光照有问题
		//mRenderManager.setPreferredLightMode(LightMode.SinglePass);
		//mRenderManager.setSinglePassLightBatchSize(4);

		Stats.show(stage);
	}

	private var mtlInfos:Vector<MtlInfo>;
	private var _objSource:String;
	private function _loadComplete(fileMap:StringMap<FileInfo>):Void
	{
		_objSource = fileMap.get(baseURL + "sponza.obj").data;
		
		mtlInfos = new MtlParser().parse(fileMap.get(baseURL + "sponza.mtl").data);
		var assetLoader = new FileLoader();
		for (i in 0...mtlInfos.length)
		{
			if(mtlInfos[i].diffuseMap != null)
				assetLoader.queueImage(baseURL + mtlInfos[i].diffuseMap);
		}
		assetLoader.onFilesLoaded.addOnce(_onTextureLoaded);
		assetLoader.loadQueuedFiles();
	}
	
	private function getMtlInfo(id:String):MtlInfo
	{
		for (i in 0...mtlInfos.length)
		{
			if (mtlInfos[i].id == id)
				return mtlInfos[i];
		}
		return null;
	}
	
	private function _onTextureLoaded(fileMap:StringMap<FileInfo>):Void
	{
		flyCam.setDragToRotate(true);
		flyCam.setMoveSpeed(1000);
		
		var pl = new PointLight();
		pl.color = Color.Random();
		pl.radius = 15000;
		pl.position = new Vector3f(0, 500, 0);
		scene.addLight(pl);
		
		pl = new PointLight();
		pl.color = Color.Random();
		pl.radius = 15000;
		pl.position = new Vector3f(500, 500, 0);
		scene.addLight(pl);
		
		pl = new PointLight();
		pl.color = Color.Random();
		pl.radius = 15000;
		pl.position = new Vector3f(-500, 500, 0);
		scene.addLight(pl);
		
		var parser:ObjParser = new ObjParser();

		var meshes:Vector<Mesh> = parser.parse(_objSource);
		for (i in 0...meshes.length)
		{
			var geomtry:Geometry = new Geometry("Model" + i, meshes[i]);
			
			scene.attachChild(geomtry);

			
			var material:Material = new Material();
			material.load(Angle3D.materialFolder + "material/lighting.mat");
			material.setFloat("u_Shininess", 1);
			material.setBoolean("useMaterialColor", false);
			material.setBoolean("useVertexLighting", false);
			material.setBoolean("useLowQuality", false);
			material.setColor("u_Ambient",  Color.White());
			material.setColor("u_Diffuse",  Color.Random());
			material.setColor("u_Specular", Color.White());
			
			var mtlInfo:MtlInfo = getMtlInfo(meshes[i].id);
			if (mtlInfo != null && fileMap.get(baseURL + mtlInfo.diffuseMap) != null)
			{
				if (fileMap.get(baseURL + mtlInfo.diffuseMap).data != null)
				{
					//var texture:BitmapTexture = new BitmapTexture(fileMap.get(baseURL + mtlInfo.diffuseMap).data);
					//material.setTexture("u_DiffuseMap", texture);
				}
				
			}
			
			geomtry.setMaterial(material);
		}
		
		camera.frustumFar = 15000;
		camera.location.setTo(0, 0, 200);
		camera.lookAt(new Vector3f(), Vector3f.Y_AXIS);
		
		addMotion();
		
		start();
		
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
	}
	
	private var path:MotionPath;
	private var motionNode:Node;
	private var motionControl:MotionEvent;
	private var target:Vector3f;
	private function addMotion():Void
	{
		path = new MotionPath();
		path.setCycle(true);

		path.addWayPoint(new Vector3f(240,139,13));
		path.addWayPoint(new Vector3f(957,139,-33));
		path.addWayPoint(new Vector3f(954,167,-426));
		path.addWayPoint(new Vector3f(-1209,211,-409));
		path.addWayPoint(new Vector3f(-1179,205,390));
		path.addWayPoint(new Vector3f(1084,229,411));
		path.addWayPoint(new Vector3f(1021,216,-20));

		path.splineType = SplineType.CatmullRom;
		//path.enableDebugShape(scene);
		
		path.onWayPointReach.add(onWayPointReach);
		
		motionNode = new Node("motionNOde");
		scene.attachChild(motionNode);
		
		target = path.getWayPoint(1);

		motionControl = new MotionEvent(motionNode, path, 10, LoopMode.Loop);
		motionControl.directionType = DirectionType.PathAndRotation;
		var rot : Quaternion = new Quaternion();
		rot.fromAngleAxis(-FastMath.HALF_PI, Vector3f.Y_AXIS);
		motionControl.setRotation(rot);
		motionControl.setInitialDuration(100);
		motionControl.setSpeed(2);
		motionControl.play();
	}
	
	private function onWayPointReach(control:MotionEvent, wayPointIndex:Int) : Void
	{
		Logger.log("currentPointIndex is " + wayPointIndex);
		var index:Int = wayPointIndex >= path.numWayPoints - 1 ? 0 : wayPointIndex + 1;
		target = path.getWayPoint(index);
	}
	
	private function onKeyDown(event:KeyboardEvent):Void
	{
		if (event.keyCode == Keyboard.SPACE)
		{
			if (motionControl == null)
				return;
			if (motionControl.isEnabled())
			{
				motionControl.pause();
			}
			else
			{
				motionControl.play();
			}
		}
	}

	private var angle:Float = 0;

	override public function simpleUpdate(tpf:Float):Void
	{
		angle += 0.02;
		angle %= FastMath.TWO_PI;
		
		if (motionNode != null && motionControl.isEnabled())
		{
			camera.setLocation(motionNode.getLocalTranslation());
			camera.lookAt(target, Vector3f.Y_AXIS);
		}

		//camera.location.setTo(Math.cos(angle) * 200, 0, Math.sin(angle) * 200);
		//camera.lookAt(new Vector3f(), Vector3f.Y_AXIS);
	}
	
}