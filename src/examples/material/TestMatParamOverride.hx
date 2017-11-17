package examples.material;
import examples.BasicExample;

import flash.ui.Keyboard;
import org.angle3d.Angle3D;
import org.angle3d.input.controls.KeyTrigger;
import org.angle3d.material.MatParamOverride;
import org.angle3d.material.Material;
import org.angle3d.shader.VarType;
import org.angle3d.math.Color;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.shape.Box;

/**
 * ...
 * @author 
 */
class TestMatParamOverride extends BasicExample
{
	static function main() 
	{
		flash.Lib.current.addChild(new TestMatParamOverride());
	}

	private var box:Box;
	private var matOverride:MatParamOverride;
	public function new() 
	{
		super();
	}
	
	private function createBox(location:Float, color:Color):Void
	{
		var geom:Geometry = new Geometry("Box", box);
		var mat:Material = new Material();
		mat.load(Angle3D.materialFolder + "material/unshaded.mat");
		mat.setColor("u_MaterialColor", color);
		geom.setMaterial(mat);
		geom.move(location, 0, 0);
		scene.attachChild(geom);
	}
	
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);
		
		box = new Box(1, 1, 1);
		matOverride = new MatParamOverride(VarType.COLOR, "u_MaterialColor", Color.Yellow());
		
		createBox( -3, Color.Red());
		createBox(0, Color.Green());
		createBox(3, Color.Blue());
		
		mInputManager.addTrigger("override", new KeyTrigger(Keyboard.SPACE));
		mInputManager.addListener(this, ["override"]);
		
		start();
	}
	
	override public function onAction(name:String, isPressed:Bool, tpf:Float):Void
	{
		super.onAction(name, isPressed, tpf);
		
		if (name == "override" && isPressed)
		{
			if (scene.getLocalMatParamOverrides().length != 0)
			{
				scene.clearMatParamOverrides();
			}
			else
			{
				scene.addMatParamOverride(matOverride);
			}
        }
	}
	
}