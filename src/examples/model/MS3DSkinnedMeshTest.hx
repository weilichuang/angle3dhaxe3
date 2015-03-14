package examples.model;

import assets.manager.FileLoader;
import assets.manager.misc.FileInfo;
import assets.manager.misc.FileType;
import flash.display.BitmapData;
import flash.utils.ByteArray;
import flash.Vector;
import org.angle3d.animation.Animation;
import org.angle3d.animation.AnimChannel;
import org.angle3d.animation.Bone;
import org.angle3d.animation.Skeleton;
import org.angle3d.animation.SkeletonAnimControl;
import org.angle3d.animation.SkeletonControl;
import org.angle3d.app.SimpleApplication;
import org.angle3d.cinematic.LoopMode;
import org.angle3d.io.parser.ms3d.MS3DParser;
import org.angle3d.light.AmbientLight;
import org.angle3d.light.PointLight;
import org.angle3d.material.TechniqueDef.LightMode;
import org.angle3d.material.Material;
import org.angle3d.material.VarType;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.debug.SkeletonDebugger;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.LightNode;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.scene.Node;
import org.angle3d.scene.shape.Sphere;
import org.angle3d.texture.BitmapTexture;
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

		var assetLoader:FileLoader = new FileLoader();
		assetLoader.queueBinary(baseURL + "ninja.ms3d");
		assetLoader.queueImage(baseURL + "nskinbr.JPG");
		assetLoader.onFilesLoaded.addOnce(_loadComplete);
		assetLoader.loadQueuedFiles();

		Stats.show(stage);
	}

	private var mat:Material;
	private var meshes:Array<Mesh>;
	private var animation:Animation;
	private var bones:Vector<Bone>;
	private var _center:Vector3f;
	private var texture:Texture2D;
	
	private var pl:PointLight;
	private var pointLightNode:Node;

	private function _loadComplete(files:Array<FileInfo>):Void
	{
		flyCam.setDragToRotate(true);
		
		//mRenderManager.setPreferredLightMode(LightMode.SinglePass);
		//mRenderManager.setSinglePassLightBatchSize(2);
		
		var byteArray:ByteArray = null;
		var bitmapData:BitmapData = null;
		for (i in 0...files.length)
		{
			if (files[i].type == FileType.BINARY)
			{
				byteArray = files[i].data;
			}
			else if (files[i].type == FileType.IMAGE)
			{
				bitmapData = files[i].data;
			}
		}
		
		texture = new BitmapTexture(bitmapData);
		
		var sphere:Sphere = new Sphere(2, 10, 10);
		var mat2:Material = new Material();
		mat2.load("assets/material/unshaded.mat");
		mat2.setTextureParam("u_DiffuseMap", VarType.TEXTURE2D, texture);
		
		var lightModel:Geometry = new Geometry("Light", sphere);
		lightModel.setMaterial(mat2);
		
		pointLightNode = new Node("lightParentNode");
		pointLightNode.attachChild(lightModel);
		//scene.attachChild(pointLightNode);
		
		pl = new PointLight();
		pl.color = new Color(1, 0, 0, 1);
		pl.radius = 50;
		scene.addLight(pl);
		
		var lightNode:LightNode = new LightNode("pointLight", pl);
		pointLightNode.attachChild(lightNode);
		
		//var sky : DefaultSkyBox = new DefaultSkyBox(500);
		//scene.attachChild(sky);

		//var directionLight:DirectionalLight = new DirectionalLight();
		//directionLight.color = new Color(0, 1, 0, 1);
		//directionLight.direction = new Vector3f(0, 1, 0);
		//scene.addLight(directionLight);
		
		var al:AmbientLight = new AmbientLight();
		al.color = new Color(0.3, 0.3, 0.3, 1);
		scene.addLight(al);

		var parser:MS3DParser = new MS3DParser();
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
				var node:Node = createNinja(index++);
				node.setTranslationXYZ((i - halfHCount) * 15, 0, (j - halfVCount) * 15);
				scene.attachChild(node);
			}
		}
		
		_center = new Vector3f(0, 0, 0);

		camera.location.setTo(Math.cos(angle) * 60, 30, Math.sin(angle) * 60);
		camera.lookAt(_center, Vector3f.Y_AXIS);
		
		start();
	}
	
	private function createNinja(index:Int):Node
	{
		var speed:Float = Math.random() * 20;
		
		
		
		var ninjaNode:Node = new Node("ninja" + index);
		
		for (i in 0...meshes.length)
		{
			var geometry:Geometry = new Geometry("ninjaGeometry" + index + "_part" + i, meshes[i]);
			ninjaNode.attachChild(geometry);
			
			var mat:Material = new Material();
			mat.load("assets/material/unshaded.mat");
			mat.setColor("u_MaterialColor", new Color(0, 0.5, 0.5));
			
			geometry.setMaterial(mat);
			
			//attatchNode
			//var boxNode:Node = new Node(ninjaNode.name + "attachBox");
			//var gm:Geometry = new Geometry("cube", new Cube(0.5, 0.5, 5, 1, 1, 1));
			//gm.setMaterial(mat);
			//boxNode.attachChild(gm);
			//
			//var attachNode:Node = skeletonControl.getAttachmentsNode("Joint29");
			//attachNode.attachChild(boxNode);


			//if (index % 2 == 0)
			//{
				//var skeletonDebugger:SkeletonDebugger = new SkeletonDebugger("skeletonDebugger", skeletonControl.getSkeleton(),
																		//0.2, Std.int(Math.random() * 0xFFFFFF), Std.int(Math.random() * 0xFFFFFF));
				//ninjaNode.attachChild(skeletonDebugger);
			//}
			
			
		}
		
		//var q:Quaternion = new Quaternion();
		//q.fromAngles(0, Math.random()*180, 0);
		//ninjaNode.setRotation(q);
		
		var newBones:Vector<Bone> = new Vector<Bone>();
		for (i in 0...bones.length)
		{
			newBones[i] = bones[i].clone();
		}

		var skeleton:Skeleton = new Skeleton(newBones);
		var skeletonControl:SkeletonControl = new SkeletonControl(skeleton);
		var animationControl:SkeletonAnimControl = new SkeletonAnimControl(skeleton);
		animationControl.addAnimation("default", animation);

		ninjaNode.addControl(skeletonControl);
		ninjaNode.addControl(animationControl);
		
		var channel:AnimChannel = animationControl.createChannel();
		channel.playAnimation("default", LoopMode.Cycle, speed , 0);
		

		return ninjaNode;
	}

	private var angle:Float = -1.5;

	override public function simpleUpdate(tpf:Float):Void
	{
		angle += 0.03;
		angle %= FastMath.TWO_PI();
		
		if (angle > FastMath.TWO_PI())
		{
			//pl.color = new Color(Math.random(), Math.random(), Math.random());
			//fillMaterial.color = pl.color.getColor();
		}

		//camera.location.setTo(Math.cos(angle) * 100, 15, Math.sin(angle) * 100);
		//camera.lookAt(_center, Vector3f.Y_AXIS);
		
		pointLightNode.setTranslationXYZ(Math.cos(angle) * 50, 10, Math.sin(angle) * 50);
	}
}
