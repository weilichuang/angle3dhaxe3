package examples.light;

import flash.text.TextField;
import org.angle3d.material.sgsl.SgslCompiler;
import org.angle3d.math.Vector2f;
import flash.Lib;
import flash.ui.Keyboard;
import org.angle3d.Angle3D;
import org.angle3d.app.SimpleApplication;
import org.angle3d.input.controls.AnalogListener;
import org.angle3d.input.controls.KeyTrigger;
import org.angle3d.light.PointLight;
import org.angle3d.material.Material;
import org.angle3d.material.VarType;
import org.angle3d.math.Color;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;
import org.angle3d.post.filter.FogFilter;
import org.angle3d.post.FilterPostProcessor;
import org.angle3d.renderer.queue.QueueBucket;
import org.angle3d.renderer.queue.ShadowMode;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.LightNode;
import org.angle3d.scene.Node;
import org.angle3d.scene.shape.Box;
import org.angle3d.scene.shape.Sphere;
import org.angle3d.scene.ui.Picture;
import org.angle3d.shadow.BasicShadowRenderer;
import org.angle3d.shadow.EdgeFilteringMode;
import org.angle3d.shadow.PointLightShadowRenderer;
import org.angle3d.utils.Stats;

class TestPointLightShadow extends SimpleApplication implements AnalogListener
{
	static function main() 
	{
		Lib.current.addChild(new TestPointLightShadow());
	}
	
	public function new() 
	{
		super();
		Angle3D.maxAgalVersion = 2;
	}
	
	private var _center:Vector3f;
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);
		
		setupFloor();
		
		var hCount:Int = 10;
		var vCount:Int = 10;
		var halfHCount:Float = (hCount / 2);
		var halfVCount:Float = (vCount / 2);
		var index:Int = 0;
		for (i in 0...hCount)
		{
			for (j in 0...vCount)
			{
				var node:Geometry = createBox(i, j);
				node.localShadowMode = ShadowMode.CastAndReceive;
				node.setTranslationXYZ((i - halfHCount) * 15, 5, (j - halfVCount) * 15);
				scene.attachChild(node);
			}
		}
		
		_center = new Vector3f(0, 0, 0);

		camera.location.setTo(0, 40, 80);
		camera.lookAt(_center, Vector3f.Y_AXIS);
		
		flyCam.setMoveSpeed(20);
		
		var pl = new PointLight();
		pl.color = Color.Random();
		pl.radius = 1500;
		pl.position = new Vector3f(0, 25, 0);
		scene.addLight(pl);
		
		var lightMat:Material = new Material();
		lightMat.load(Angle3D.materialFolder + "material/unshaded.mat");
        lightMat.setColor("u_MaterialColor",  pl.color);
		
		var lightMdl:Geometry = new Geometry("Light", new Sphere(1, 10, 10));
        lightMdl.setMaterial(lightMat);
        
        var lightNode:Node = new Node("lightParentNode");
        lightNode.attachChild(lightMdl);  
        lightNode.setLocalTranslation(new Vector3f(0, 25, 0));
        scene.attachChild(lightNode);
        
        var plsr:PointLightShadowRenderer = new PointLightShadowRenderer(512);
        plsr.setLight(pl);
        plsr.setEdgeFilteringMode(EdgeFilteringMode.PCF);
        plsr.showShadowMap(true);
		//plsr.showFrustum(true);
        viewPort.addProcessor(plsr);
		
		reshape(mContextWidth, mContextHeight);

		Stats.show(stage);
		start();
	}
	
	private function setupFloor():Void
	{
		var mat:Material = new Material();
		mat.load(Angle3D.materialFolder + "material/unshaded.mat");
        mat.setColor("u_MaterialColor",  new Color(0.8,0.8,0.8));

		var floor:Box = new Box(150, 1, 150);
		var floorGeom:Geometry = new Geometry("Floor", floor);
		floorGeom.setMaterial(mat);
		floorGeom.setLocalTranslation(new Vector3f(0, 0, 0));
		floorGeom.localShadowMode = ShadowMode.Receive;
		scene.attachChild(floorGeom);
	}
	
	private function createBox(i:Int,j:Int):Geometry
	{
		var geometry:Geometry = new Geometry("box" + i + "" + j, new Box(5, 5, 5));
		
		var mat:Material = new Material();
		//mat.load(Angle3D.materialFolder + "material/unshaded.mat");
		//mat.setParam("u_MaterialColor", VarType.COLOR, new Color(Math.random(),Math.random(),Math.random()));
		mat.load(Angle3D.materialFolder + "material/lighting.mat");
		mat.setFloat("u_Shininess", 32);
        mat.setBoolean("useMaterialColor", false);
		mat.setBoolean("useVertexLighting", false);
		mat.setBoolean("useLowQuality", false);
        mat.setColor("u_Ambient",  Color.White());
        mat.setColor("u_Diffuse",  Color.Random());
        mat.setColor("u_Specular", Color.White());
		
		geometry.setMaterial(mat);
		
		return geometry;
	}
	
	public function onAnalog(name:String, value:Float, tpf:Float):Void
	{
		
	}
	
	override public function onAction(name:String, value:Bool, tpf:Float):Void
	{
		super.onAction(name, value, tpf);
	}
	
	override public function update():Void 
	{
		super.update();
	}
}