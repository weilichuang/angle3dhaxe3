package examples.effect.cpu;

import flash.display.BitmapData;
import org.angle3d.app.SimpleApplication;
import org.angle3d.effect.cpu.ParticleEmitter;
import org.angle3d.material.Material;
import org.angle3d.material.VarType;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.texture.Texture2D;
import org.angle3d.utils.Stats;


class MovingParticleTest extends SimpleApplication
{
	static function main() 
	{
		flash.Lib.current.addChild(new MovingParticleTest());
	}
	
	private var emit:ParticleEmitter;
	private var angle:Float;

	public function new()
	{
		super();

		angle = 0;
	}

	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);
		
		flyCam.setDragToRotate(true);

		emit = new ParticleEmitter("Emitter", 1000);
		emit.setGravity(new Vector3f(0, 0.3, 0));
		emit.setLowLife(1);
		emit.setHighLife(5);
		emit.setStartColor(new Color(1.0,0.0,0.0));
		emit.setEndColor(new Color(1.0,1.0,0.0));
		emit.setStartAlpha(0.4);
		emit.setEndAlpha(0.0);
		
		emit.setStartSize(0.5);
		emit.setEndSize(2);
		emit.particleInfluencer.setVelocityVariation(0.1);
		emit.particleInfluencer.setInitialVelocity(new Vector3f(0, 2.5, 0));
		//emit.setImagesX(15);
		
		var bitmapData:BitmapData = Type.createInstance(EMBED_SMOKE, [0, 0]);
		var texture:Texture2D = new Texture2D(bitmapData, false);
		
		var material:Material = new Material();
		material.load("assets/material/cpuparticle.mat");
		material.setTextureParam("s_texture", VarType.TEXTURE2D, texture);

		emit.setMaterial(material);

		scene.attachChild(emit);
		
		start();
		Stats.show(stage);
	}

	override public function simpleUpdate(tpf:Float):Void
	{
		angle += tpf;
		angle %= FastMath.TWO_PI();
		var fx:Float = Math.cos(angle) * 2;
		var fy:Float = Math.sin(angle) * 2;
		emit.setTranslationXYZ(fx, 0, fy);
	}
}

@:bitmap("../assets/embed/particle/flare.png") class EMBED_SMOKE extends BitmapData { }