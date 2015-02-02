package examples.model;

import examples.skybox.DefaultSkyBox;
import flash.display.Bitmap;
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
import org.angle3d.material.Material;
import org.angle3d.material.MaterialTexture;
import org.angle3d.material.StandardMaterial;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.math.VectorUtil;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.scene.Node;
import org.angle3d.texture.Texture2D;
import org.angle3d.utils.Stats;

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
		assetLoader.add(baseURL + "nskinbr.JPG");

		assetLoader.execute();
		
		Stats.show(stage);
	}

	private var material:StandardMaterial;
	private var material2:MaterialTexture;
	private var meshes:Array<Mesh>;
	private var animation:Animation;
	private var bones:Vector<Bone>;
	private var _center:Vector3f;

	private function _loadComplete(loader:AssetLoader):Void
	{
		flyCam.setDragToRotate(true);
		
		var assetLoaderVO1:AssetLoaderVO = loader.get(baseURL + "ninja.ms3d");
		var assetLoaderVO2:AssetLoaderVO = loader.get(baseURL + "nskinbr.JPG");

		var bitmap:Bitmap = assetLoaderVO2.data;
		material2 = new MaterialTexture(new Texture2D(bitmap.bitmapData));
		
		var sky : DefaultSkyBox = new DefaultSkyBox(500);
		scene.attachChild(sky);

		material = new StandardMaterial();
		material.isReflect = true;
		material.texture = new Texture2D(bitmap.bitmapData);
		material.environmentMap = sky.cubeMap;
		material.reflectivity = 0.8;

		var parser:MS3DParser = new MS3DParser();

		var byteArray:ByteArray = assetLoaderVO1.data;
		meshes = parser.parseSkinnedMesh("ninja", byteArray);
		var boneAnimation:BoneAnimation = parser.buildSkeleton();
		bones = boneAnimation.bones;
		animation = boneAnimation.animation;

		var hCount:Int = 10;
		var vCount:Int = 10;
		var halfHCount:Float = (hCount / 2);
		var halfVCount:Float = (vCount / 2);
		var index:Int = 0;
		for (i in 0...hCount)
		{
			for (j in 0...vCount)
			{
				var nodes:Array<Node> = createNinja(index++);
				for (k in 0...nodes.length)
				{
					nodes[k].setTranslationXYZ((i - halfHCount) * 15, 0, (j - halfVCount) * 15);
					scene.attachChild(nodes[k]);
				}
			}
		}
		
		_center = new Vector3f(0, 0, 0);

		camera.location.setTo(Math.cos(angle) * 100, 15, Math.sin(angle) * 100);
		camera.lookAt(_center, Vector3f.Y_AXIS);
		
		start();
		
		var v:Vector<Int> = Vector.ofArray([1, 2, 3, 4, 5]);
		VectorUtil.insert(v, 2, 100);
		trace(v);
	}
	
	private function createNinja(index:Int):Array<Node>
	{
		var nodes:Array<Node> = [];
		for (i in 0...meshes.length)
		{
			var geometry:Geometry = new Geometry("ninjaGeometry" + index + "_part" + i, meshes[i]);

			var ninjaNode:Node = new Node("ninja" + index + "_part" + i);
			ninjaNode.attachChild(geometry);
			ninjaNode.setMaterial(material2);
			
			//var q:Quaternion = new Quaternion();
			//q.fromAngles(0, Math.random()*180, 0);
			//ninjaNode.setRotation(q);

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
			//var boxNode:Node = new Node(ninjaNode.name + "attachBox");
			//var gm:Geometry = new Geometry("cube", new Cube(0.5, 0.5, 5, 1, 1, 1));
			//gm.setMaterial(new MaterialColorFill(0xff0000, 1.0));
			//boxNode.attachChild(gm);
			
			//var attachNode:Node = skeletonControl.getAttachmentsNode("Joint29");
			//attachNode.attachChild(boxNode);

			var channel:AnimChannel = animationControl.createChannel();
			channel.playAnimation("default", LoopMode.Cycle, 10, 0);

			//if (index % 2 == 0)
			//{
				//var skeletonDebugger:SkeletonDebugger = new SkeletonDebugger("skeletonDebugger", skeletonControl.getSkeleton(),
																		//0.2, Std.int(Math.random() * 0xFFFFFF), Std.int(Math.random() * 0xFFFFFF));
				//ninjaNode.attachChild(skeletonDebugger);
			//}
			
			nodes.push(ninjaNode);
		}
		

		return nodes;
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
