package lecture;

import org.angle3d.Angle3D;
import org.angle3d.light.AmbientLight;
import org.angle3d.material.LightMode;
import org.angle3d.material.Material;
import org.angle3d.math.Color;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.shape.Sphere;

/**
 * ...
 * @author 
 */
class TestAmbient extends BasicLecture
{
	static function main() 
	{
		flash.Lib.current.addChild(new TestAmbient());
	}

	private var sphereMesh:Geometry;
	
	public function new() 
	{
		super();
		
	}
	
	override private function initialize(width : Int, height : Int) : Void
	{
		super.initialize(width, height);
		
		flyCam.setDragToRotate(true);
		
		mRenderManager.setPreferredLightMode(LightMode.SinglePass);
		mRenderManager.setSinglePassLightBatchSize(2);
		
		var sphere:Sphere = new Sphere(1.5, 16, 16, true);
		sphereMesh = new Geometry("Sphere Geom", sphere);
		
		var mat:Material = new Material();
		mat.load(Angle3D.materialFolder + "material/lighting.mat");
		mat.setFloat("u_Shininess", 32);
        mat.setBoolean("useMaterialColor", false);
		mat.setBoolean("useVertexLighting", false);
		mat.setBoolean("useLowQuality", false);
        mat.setColor("u_Ambient",  Color.White());
        mat.setColor("u_Diffuse",  new Color(0.8,0.8,0.8));
        mat.setColor("u_Specular", Color.White());
		sphereMesh.setMaterial(mat);
		
		scene.attachChild(sphereMesh);
		
		var al:AmbientLight = new AmbientLight();
		al.color = new Color(0.1, 0.1, 0.1, 1);
		scene.addLight(al);
		
		camera.location.setTo(0, 0, 7);
		camera.lookAt(new Vector3f(), Vector3f.UNIT_Y);
		
		start();
	}
	
}