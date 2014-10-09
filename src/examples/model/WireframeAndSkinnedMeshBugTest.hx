package examples.model;

import flash.display.Bitmap;
import flash.events.KeyboardEvent;
import flash.ui.Keyboard;
import flash.utils.ByteArray;
import flash.Vector;
import hu.vpmedia.assets.AssetLoader;
import hu.vpmedia.assets.AssetLoaderVO;
import org.angle3d.animation.Animation;
import org.angle3d.animation.AnimChannel;
import org.angle3d.animation.Bone;
import org.angle3d.animation.Skeleton;
import org.angle3d.animation.SkeletonAnimControl;
import org.angle3d.animation.SkeletonControl;
import org.angle3d.app.SimpleApplication;
import org.angle3d.cinematic.LoopMode;
import org.angle3d.io.parser.ms3d.MS3DParser;
import org.angle3d.material.MaterialColorFill;
import org.angle3d.material.MaterialTexture;
import org.angle3d.math.FastMath;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.queue.QueueBucket;
import org.angle3d.scene.debug.SkeletonDebugger;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.scene.Node;
import org.angle3d.scene.shape.Cube;
import org.angle3d.scene.shape.WireframeShape;
import org.angle3d.scene.shape.WireframeUtil;
import org.angle3d.scene.WireframeGeometry;
import org.angle3d.texture.Texture2D;
import org.angle3d.utils.Stats;

class WireframeAndSkinnedMeshBugTest extends SimpleApplication
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

		baseURL = "ms3d/";
		var assetLoader:AssetLoader = new AssetLoader();
		assetLoader.signalSet.completed.add(_loadComplete);
		assetLoader.add(baseURL + "ninja.ms3d");
		assetLoader.add(baseURL + "nskinbr.JPG");

		assetLoader.execute();
		
		Stats.show(stage);
	}

	private var material:MaterialTexture;
	private var meshes:Array<Mesh>;
	private var animation:Animation;
	private var bones:Vector<Bone>;
	private var _center:Vector3f;
	private var ninjaNode:Node;
	private var skeletonControl:SkeletonControl;
	private function _loadComplete(loader:AssetLoader):Void
	{
		flyCam.setDragToRotate(true);
		
		var assetLoaderVO1:AssetLoaderVO = loader.get(baseURL + "ninja.ms3d");
		var assetLoaderVO2:AssetLoaderVO = loader.get(baseURL + "nskinbr.JPG");

		var bitmap:Bitmap = assetLoaderVO2.data;
		material = new MaterialTexture(new Texture2D(bitmap.bitmapData));
		
		colorMat = new MaterialColorFill(0xFFFF00);

		var parser:MS3DParser = new MS3DParser();

		var byteArray:ByteArray = assetLoaderVO1.data;
		meshes = parser.parseSkinnedMesh("ninja", byteArray);
		var boneAnimation:BoneAnimation = parser.buildSkeleton();
		bones = boneAnimation.bones;
		animation = boneAnimation.animation;
		
		for (i in 0...meshes.length)
		{
			var geometry:Geometry = new Geometry("ninja", meshes[i]);

			ninjaNode = new Node("ninja");
			ninjaNode.attachChild(geometry);
			ninjaNode.setMaterial(material);
			
			var skeleton:Skeleton = new Skeleton(bones);
			skeletonControl = new SkeletonControl(geometry, skeleton);
			var animationControl:SkeletonAnimControl = new SkeletonAnimControl(skeleton);
			animationControl.addAnimation("default", animation);

			ninjaNode.addControl(skeletonControl);
			ninjaNode.addControl(animationControl);

			var channel:AnimChannel = animationControl.createChannel();
			channel.playAnimation("default", LoopMode.Cycle, 10, 0);
			
			scene.attachChild(ninjaNode);
		}

		
		
		var solidCube : Cube = new Cube(2, 2, 2, 1, 1, 1);
		var cubeGeometry : Geometry = new Geometry("wireCube", solidCube);
		cubeGeometry.setMaterial(new MaterialColorFill(0x00FF00));
		cubeGeometry.rotateAngles(45 / 180 * Math.PI, 0, 0);
		scene.attachChild(cubeGeometry);
		
		_center = new Vector3f(0, 0, 0);

		camera.location.setTo(Math.cos(angle) * 10, 5, Math.sin(angle) * 10);
		camera.lookAt(_center, Vector3f.Y_AXIS);
		
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

	private var colorMat:MaterialColorFill;
	private var skeletonDebugger:SkeletonDebugger;
	private function createNinja(index:Int):Node
	{
		

		return ninjaNode;
	}

	private var angle:Float = -1.5;

	override public function simpleUpdate(tpf:Float):Void
	{
		angle += 0.01;
		angle %= FastMath.TWO_PI();

		//camera.location.setTo(Math.cos(angle) * 100, 15, Math.sin(angle) * 100);
		//camera.lookAt(_center, Vector3f.Y_AXIS);
	}
}
