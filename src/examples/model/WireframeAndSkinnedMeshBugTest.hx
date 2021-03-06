package examples.model;

import org.angle3d.asset.FilesLoader;
import org.angle3d.asset.FileInfo;

import flash.display.BitmapData;
import flash.events.KeyboardEvent;
import flash.ui.Keyboard;
import flash.utils.ByteArray;
import flash.Vector;
import haxe.ds.StringMap;
import org.angle3d.Angle3D;
import org.angle3d.animation.Animation;
import org.angle3d.animation.AnimChannel;
import org.angle3d.animation.Bone;
import org.angle3d.animation.Skeleton;
import org.angle3d.animation.AnimControl;
import org.angle3d.animation.SkeletonControl;
import org.angle3d.app.SimpleApplication;
import org.angle3d.cinematic.LoopMode;
import org.angle3d.io.parser.ms3d.MS3DParser;
import org.angle3d.material.Material;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.debug.SkeletonDebugger;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.scene.Node;
import org.angle3d.scene.shape.Cube;
import org.angle3d.texture.BitmapTexture;
import org.angle3d.utils.Stats;

class WireframeAndSkinnedMeshBugTest extends BasicExample
{
	static function main() 
	{
		flash.Lib.current.addChild(new WireframeAndSkinnedMeshBugTest());
	}
	
	private var baseURL:String;
	public function new()
	{
		super();
	}
	
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);

		baseURL = "../assets/ms3d/";

		var assetLoader:FilesLoader = new FilesLoader();
		assetLoader.queueBinary(baseURL + "ninja.ms3d");
		assetLoader.queueImage(baseURL + "nskinbr.JPG");
		assetLoader.onFilesLoaded.addOnce(_loadComplete);
		assetLoader.loadQueuedFiles();

		
	}

	private var material:Material;
	private var meshes:Array<Mesh>;
	private var animation:Animation;
	private var bones:Vector<Bone>;
	private var _center:Vector3f;
	private var ninjaNode:Node;
	private var skeletonControl:SkeletonControl;
	
	private function _loadComplete(loader:FilesLoader):Void
	{
		flyCam.setDragToRotate(true);
		
		//mRenderManager.setPreferredLightMode(LightMode.SinglePass);
		//mRenderManager.setSinglePassLightBatchSize(2);
		
		var byteArray:ByteArray = loader.getAssetByUrl(baseURL + "ninja.ms3d").info.content;
		var bitmapData:BitmapData = loader.getAssetByUrl(baseURL + "nskinbr.JPG").info.content;
		
		var mat2:Material = new Material();
		mat2.load(Angle3D.materialFolder + "material/unshaded.mat");
		mat2.setTexture("u_DiffuseMap", new BitmapTexture(bitmapData));

		colorMat = new Material();
		colorMat.load(Angle3D.materialFolder + "material/unshaded.mat");
		colorMat.setColor("u_MaterialColor", Color.fromColor(0xFFff00));

		var parser:MS3DParser = new MS3DParser();
		meshes = parser.parseSkinnedMesh("ninja", byteArray);
		var boneAnimation:BoneAnimation = parser.buildSkeleton();
		bones = boneAnimation.bones;
		animation = boneAnimation.animation;
		animation.name = "default";
		
		for (i in 0...meshes.length)
		{
			var geometry:Geometry = new Geometry("ninja", meshes[i]);

			ninjaNode = new Node("ninja");
			ninjaNode.attachChild(geometry);
			ninjaNode.setMaterial(mat2);
			
			var skeleton:Skeleton = new Skeleton(bones);
			skeletonControl = new SkeletonControl(skeleton);
			var animationControl:AnimControl = new AnimControl(skeleton);
			animationControl.addAnimation(animation);

			ninjaNode.addControl(skeletonControl);
			ninjaNode.addControl(animationControl);

			var channel:AnimChannel = animationControl.createChannel();
			channel.setAnim("default"); 
			channel.setLoopMode(LoopMode.Cycle);
			channel.setSpeed(10);
			
			scene.attachChild(ninjaNode);
		}

		var solidCube : Cube = new Cube(2, 2, 2, 1, 1, 1);
		var cubeGeometry : Geometry = new Geometry("wireCube", solidCube);
		cubeGeometry.setMaterial(colorMat);
		cubeGeometry.rotateAngles(45 / 180 * Math.PI, 0, 0);
		scene.attachChild(cubeGeometry);
		
		_center = new Vector3f(0, 0, 0);

		camera.location.setTo(Math.cos(angle) * 10, 5, Math.sin(angle) * 10);
		camera.lookAt(_center, Vector3f.UNIT_Y);
		
		start();
		
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
	}
	
	private function onKeyDown(e:KeyboardEvent):Void
	{
		if (e.keyCode == Keyboard.NUMBER_1)
		{
			if (skeletonDebugger != null)
				skeletonDebugger.visible = false;
		}
		else if (e.keyCode == Keyboard.NUMBER_2)
		{
			if (skeletonDebugger == null)
			{
				skeletonDebugger = new SkeletonDebugger("skeletonDebugger", skeletonControl.getSkeleton(),
																	0.2, Std.int(Math.random() * 0xFFFFFF), Std.int(Math.random() * 0xFFFFFF));
				ninjaNode.attachChild(skeletonDebugger);
			}
			skeletonDebugger.visible = true;
		}
	}

	private var colorMat:Material;
	private var skeletonDebugger:SkeletonDebugger;
	private function createNinja(index:Int):Node
	{
		

		return ninjaNode;
	}

	private var angle:Float = -1.5;

	override public function simpleUpdate(tpf:Float):Void
	{
		angle += 0.01;
		angle %= FastMath.TWO_PI;

		//camera.location.setTo(Math.cos(angle) * 100, 15, Math.sin(angle) * 100);
		//camera.lookAt(_center, Vector3f.Y_AXIS);
	}
}
