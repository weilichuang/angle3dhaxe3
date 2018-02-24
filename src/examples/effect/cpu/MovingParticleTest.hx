package examples.effect.cpu;

import flash.display.BitmapData;
import angle3d.Angle3D;
import angle3d.app.SimpleApplication;
import angle3d.effect.cpu.ParticleEmitter;
import angle3d.material.Material;
import angle3d.shader.VarType;
import angle3d.math.Color;
import angle3d.math.FastMath;
import angle3d.math.Vector3f;
import angle3d.texture.BitmapTexture;
import angle3d.utils.Stats;


class MovingParticleTest extends BasicExample
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
		var texture:BitmapTexture = new BitmapTexture(bitmapData, false);
		
		var material:Material = new Material();
		material.load(Angle3D.materialFolder + "material/cpuparticle.mat");
		material.setTextureParam("u_DiffuseMap", VarType.TEXTURE2D, texture);

		emit.setMaterial(material);

		scene.attachChild(emit);
		
		start();
		
	}

	override public function simpleUpdate(tpf:Float):Void
	{
		super.simpleUpdate(tpf);
		
		angle += tpf;
		angle %= FastMath.TWO_PI;
		var fx:Float = Math.cos(angle) * 2;
		var fy:Float = Math.sin(angle) * 2;
		emit.setTranslationXYZ(fx, 0, fy);
	}
}

@:bitmap("../assets/embed/particle/flare.png") class EMBED_SMOKE extends BitmapData { }