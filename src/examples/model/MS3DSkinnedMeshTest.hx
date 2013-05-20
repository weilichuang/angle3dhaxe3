package examples.model;

import flash.display.Bitmap;
import flash.utils.ByteArray;
import flash.Vector;
import hu.vpmedia.assets.AssetLoaderVO;
import org.angle3d.animation.Animation;
import org.angle3d.animation.AnimChannel;
import org.angle3d.animation.Bone;
import org.angle3d.animation.Skeleton;
import org.angle3d.animation.SkeletonAnimControl;
import org.angle3d.animation.SkeletonControl;
import org.angle3d.app.SimpleApplication;
import org.angle3d.cinematic.LoopMode;
import org.angle3d.io.AssetManager;
import org.angle3d.io.parser.ms3d.MS3DParser;
import org.angle3d.material.MaterialColorFill;
import org.angle3d.material.MaterialTexture;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.queue.QueueBucket;
import org.angle3d.scene.debug.SkeletonDebugger;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.mesh.SkinnedMesh;
import org.angle3d.scene.Node;
import org.angle3d.scene.shape.Cube;
import org.angle3d.texture.Texture2D;
import org.angle3d.utils.Stats;
import hu.vpmedia.assets.AssetLoader;

class MS3DSkinnedMeshTest extends SimpleApplication
{
	static function main() 
	{
		flash.Lib.current.addChild(new MS3DSkinnedMeshTest());
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
		assetLoader.add(baseURL + "nskinbr.jpg");

		assetLoader.execute();
		
		Stats.show(stage);
	}

	private var material:MaterialTexture;
	private var skinnedMesh:SkinnedMesh;
	private var animation:Animation;
	private var bones:Vector<Bone>;
	private var _center:Vector3f;

	private function _loadComplete(loader:AssetLoader):Void
	{
		flyCam.setDragToRotate(true);
		
		var assetLoaderVO1:AssetLoaderVO = loader.get(baseURL + "ninja.ms3d");
		var assetLoaderVO2:AssetLoaderVO = loader.get(baseURL + "nskinbr.jpg");

		var bitmap:Bitmap = assetLoaderVO2.data;
		material = new MaterialTexture(new Texture2D(bitmap.bitmapData));

		var parser:MS3DParser = new MS3DParser();

		var byteArray:ByteArray = assetLoaderVO1.data;
		skinnedMesh = parser.parseSkinnedMesh("ninja", byteArray);
		var boneAnimation:BoneAnimation = parser.buildSkeleton();
		bones = boneAnimation.bones;
		animation = boneAnimation.animation;

		var hCount:Int = 20;
		var vCount:Int = 20;
		var halfHCount:Float = (hCount / 2);
		var halfVCount:Float = (vCount / 2);
		for (i in 0...hCount)
		{
			for (j in 0...vCount)
			{
				var node:Node = createNinja(i);
				node.setTranslationXYZ((i - halfHCount) * 15, 0, (j - halfVCount) * 15);
				scene.attachChild(node);
			}
		}
		
		_center = new Vector3f(0, 0, 0);

		camera.location.setTo(0, 15, 100);
		camera.lookAt(_center, Vector3f.Y_AXIS);
		
		start();
	}

	private function createNinja(index:Int):Node
	{
		var geometry:Geometry = new Geometry("ninja" + index, skinnedMesh);

		var ninjaNode:Node = new Node("ninja" + index);
		ninjaNode.attachChild(geometry);
		ninjaNode.setMaterial(material);

		var newBones:Vector<Bone> = new Vector<Bone>();
		for (i in 0...bones.length)
		{
			newBones[i] = bones[i].clone();
		}

		var skeleton:Skeleton = new Skeleton(newBones);
		var skeletonControl:SkeletonControl = new SkeletonControl(geometry, skeleton);
		var animationControl:SkeletonAnimControl = new SkeletonAnimControl(skeleton);
		animationControl.addAnimation("default", animation);

		ninjaNode.addControl(skeletonControl);
		ninjaNode.addControl(animationControl);

		//attatchNode
		//var boxNode:Node = new Node("box");
		//var gm:Geometry = new Geometry("cube", new Cube(0.5, 0.5, 5, 1, 1, 1));
		//gm.setMaterial(new MaterialColorFill(0xff0000, 1.0));
		//gm.localQueueBucket = QueueBucket.Opaque;
		//boxNode.attachChild(gm);
//
		//var attachNode:Node = skeletonControl.getAttachmentsNode("Joint29");
		//attachNode.attachChild(boxNode);

		var channel:AnimChannel = animationControl.createChannel();
		channel.playAnimation("default", LoopMode.Cycle, 10);

		//var skeletonDebugger:SkeletonDebugger = new SkeletonDebugger("skeletonDebugger", skeletonControl.getSkeleton(), 0.1);
		//ninjaNode.attachChild(skeletonDebugger);

		return ninjaNode;
	}

	private var angle:Float = 0;

	override public function simpleUpdate(tpf:Float):Void
	{
		angle += 0.01;
		angle %= FastMath.TWO_PI();

		camera.location.setTo(Math.cos(angle) * 200, 30, Math.sin(angle) * 200);
		camera.lookAt(_center, Vector3f.Y_AXIS);
	}
}
