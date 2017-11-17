package examples.material;
import flash.events.Event;
import flash.events.MouseEvent;

import org.angle3d.Angle3D;
import org.angle3d.app.SimpleApplication;
import org.angle3d.material.Material;
import org.angle3d.shader.VarType;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.shape.Box;
import org.angle3d.scene.shape.Sphere;
import org.angle3d.scene.shape.WireframeShape;
import org.angle3d.scene.shape.WireframeUtil;
import org.angle3d.scene.WireframeGeometry;
import org.angle3d.utils.Stats;

class MaterialWireframeTest extends BasicExample
{
	static function main()
	{
		Lib.current.addChild(new MaterialWireframeTest());
	}

	public function new() 
	{
		super();
	}
	
	private var angle:Float = 0;
	private var mat:Material;
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);
		
		flyCam.setDragToRotate(true);
		
		camera.location.setTo(0, 0, 300);
        mCamera.lookAt(Vector3f.ZERO, Vector3f.UNIT_Y);

		mat = new Material();
		mat.load(Angle3D.materialFolder + "material/wireframe.mat");
		mat.setParam("u_color", VarType.COLOR, new Color(1, 0, 0, 1));
		mat.setParam("u_thickness", VarType.FLOAT, 0.001);
		
		//setup main scene
		var wireBox:WireframeShape = WireframeUtil.generateWireframe(new Sphere(50));
        var quad:WireframeGeometry = new WireframeGeometry("box", wireBox);
		
        quad.setMaterial(mat);
        mScene.attachChild(quad);

		this.stage.addEventListener(MouseEvent.CLICK, onClick);
		
		
		start();
	}
	
	private function onClick(event:Event):Void
	{
		if(mat != null)
			mat.setColor("u_color", new Color(Math.random(), Math.random(), Math.random(), 1));
	}
	
	override public function simpleUpdate(tpf:Float):Void
	{
		angle += 0.03;
		angle %= FastMath.TWO_PI;


		camera.location.setTo(Math.cos(angle) * 300, 0, Math.sin(angle) * 300);
		camera.lookAt(new Vector3f(), Vector3f.UNIT_Y);
	}
}