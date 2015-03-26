package examples.light;
import flash.Vector;
import org.angle3d.app.SimpleApplication;
import org.angle3d.material.Material;
import org.angle3d.math.Color;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.Camera;
import org.angle3d.renderer.queue.ShadowMode;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.shape.Box;
import org.angle3d.shadow.BasicShadowRenderer;
import org.angle3d.shadow.ShadowUtil;
import org.angle3d.utils.Stats;

class TestShadow extends SimpleApplication
{
	static function main() 
	{
		flash.Lib.current.addChild(new TestShadow());
	}
	
	private var basicShadowRender:BasicShadowRenderer;
	private var boxGeom:Geometry;
	private var boxGeom2:Geometry;
	private var points:Vector<Vector3f>;

	public function new() 
	{
		super();
	}
	
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);
		
		flyCam.setDragToRotate(true);
		
		points = new Vector<Vector3f>(8, true);
		for (i in 0...8)
		{
			points[i] = new Vector3f();
		}
		
		mCamera.setLocation(new Vector3f(0.7804813, 5.7502685, -6.1556435));
		mCamera.setRotation(new Quaternion(0.1961598, -0.7213164, 0.2266092, 0.6243975));
		mCamera.frustumFar = 20;
		
		var mat:Material = new Material();
		mat.load("assets/material/unshaded.mat");
		mat.setColor("u_MaterialColor", Color.White());
		
		var floor:Box = new Box(3, 0.1, 3);
		var floorGeom:Geometry = new Geometry("Floor", floor);
		floorGeom.setMaterial(mat);
		floorGeom.setLocalTranslation(new Vector3f(0, -0.2, 0));
		floorGeom.localShadowMode = ShadowMode.Receive;
		
		scene.attachChild(floorGeom);
		
		var mat2:Material = new Material();
		mat2.load("assets/material/unshaded.mat");
		mat2.setColor("u_MaterialColor", Color.Red());
		
		var box2:Box = new Box(1.3, 0.3, 1.3);
		boxGeom = new Geometry("Box", box2);
		boxGeom.setMaterial(mat2);
		boxGeom.localShadowMode = ShadowMode.CastAndReceive;
		boxGeom.setLocalTranslation(new Vector3f(-0.5, 1, -2));
		scene.attachChild(boxGeom);
		
		var box3:Box = new Box(1.3, 0.3, 1.3);
		boxGeom2 = new Geometry("Box3", box3);
		boxGeom2.setMaterial(mat2);
		boxGeom2.localShadowMode = ShadowMode.CastAndReceive;
		boxGeom2.setLocalTranslation(new Vector3f(1, 2, 0));
		scene.attachChild(boxGeom2);
		
		mCamera.lookAt(new Vector3f(0, 0, -2), Vector3f.Y_AXIS);
		
		basicShadowRender = new BasicShadowRenderer(512);
		basicShadowRender.setDirection(new Vector3f(0.5, -1, 0).normalizeLocal());// mCamera.getDirection().normalizeLocal());
		viewPort.addProcessor(basicShadowRender);
		
		gui.attachChild(basicShadowRender.getDisplayPicture());
		
		reshape(mContextWidth, mContextHeight);
		
		Stats.show(stage);
		start();
	}
	
	override public function simpleUpdate(tpf:Float):Void
	{
		//var shadowCam:Camera = basicShadowRender.getShadowCamera();
		//
		//ShadowUtil.updateFrustumPoints2(shadowCam, points);
		//
		boxGeom.rotateAngles(0, tpf * 0.25, 0);
		
		boxGeom2.rotateAngles(0, -tpf * 0.25, 0);
	}
}