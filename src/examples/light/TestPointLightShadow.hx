package examples.light;

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
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.queue.ShadowMode;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.shape.Box;
import org.angle3d.scene.shape.Sphere;
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
	private var pl:PointLight;
	private var lightMdl:Geometry;
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
		
		pl = new PointLight();
		pl.color = Color.Random();
		pl.radius = 1500;
		pl.position = new Vector3f(0, 35, 0);
		scene.addLight(pl);
		
		var lightMat:Material = new Material();
		lightMat.load(Angle3D.materialFolder + "material/unshaded.mat");
        lightMat.setColor("u_MaterialColor",  pl.color);
		
		lightMdl = new Geometry("Light", new Sphere(1, 10, 10));
        lightMdl.setMaterial(lightMat);
        lightMdl.setLocalTranslation(new Vector3f(0, 35, 0));
        scene.attachChild(lightMdl);
        
        var plsr:PointLightShadowRenderer = new PointLightShadowRenderer(512);
        plsr.setLight(pl);
		plsr.setShadowInfo(0.0003, 0.5);
        plsr.setEdgeFilteringMode(EdgeFilteringMode.Nearest);
        plsr.showShadowMap(true);
		//plsr.showFrustum(true);
        viewPort.addProcessor(plsr);
		
		reshape(mContextWidth, mContextHeight);
		
		mInputManager.addSingleMapping("DistanceUp", new KeyTrigger(Keyboard.UP));
		mInputManager.addSingleMapping("DistanceDown", new KeyTrigger(Keyboard.DOWN));
		mInputManager.addSingleMapping("MoveLeft", new KeyTrigger(Keyboard.LEFT));
		mInputManager.addSingleMapping("MoveRight", new KeyTrigger(Keyboard.RIGHT));
		mInputManager.addListener(this, ["DistanceUp", "DistanceDown","MoveLeft", "MoveRight"]);

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
		//mat.setColor("u_MaterialColor", Color.Random());
		mat.load(Angle3D.materialFolder + "material/lighting.mat");
		mat.setFloat("u_Shininess", 1);
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
		switch(name)
		{
			case "DistanceUp":
				pl.position.y += 1;
				lightMdl.setLocalTranslation(pl.position);
			case "DistanceDown":
				pl.position.y -= 1;
				lightMdl.setLocalTranslation(pl.position);
			case "MoveLeft":
				pl.position.x -= 1;
				lightMdl.setLocalTranslation(pl.position);
			case "MoveRight":
				pl.position.x += 1;
				lightMdl.setLocalTranslation(pl.position);
		}
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