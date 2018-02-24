package examples.effect.cpu;

import flash.display.BitmapData;
import angle3d.Angle3D;
import angle3d.app.SimpleApplication;
import angle3d.effect.cpu.ParticleEmitter;
import angle3d.effect.cpu.shape.EmitterSphereShape;
import angle3d.material.Material;
import angle3d.shader.VarType;
import angle3d.math.Color;
import angle3d.math.FastMath;
import angle3d.math.Quaternion;
import angle3d.math.Vector3f;
import angle3d.scene.Node;
import angle3d.texture.BitmapTexture;
import angle3d.utils.Stats;


class ExplosionEffectTest extends BasicExample
{
	static function main() 
	{
		flash.Lib.current.addChild(new ExplosionEffectTest());
	}
	
	private static inline var COUNT_FACTOR:Int = 1;
	private static inline var COUNT_FACTOR_F:Float = 1.0;

	private var emit:ParticleEmitter;
	private var angle:Float;

	private var flame:ParticleEmitter;
	private var flashPE:ParticleEmitter;
	private var spark:ParticleEmitter;
	private var roundspark:ParticleEmitter;
	private var smoketrail:ParticleEmitter;
	private var debris:ParticleEmitter;
	private var shockwave:ParticleEmitter;

	private var explosionEffect:Node;

	public function new()
	{
		super();

		angle = 0;
	}

	private function createMat(cls:Class<Dynamic>):Material
	{
		var bitmapData:BitmapData = Type.createInstance(cls,[0,0]);
		var texture:BitmapTexture = new BitmapTexture(bitmapData, false);
		
		var material:Material = new Material();
		material.load(Angle3D.materialFolder + "material/cpuparticle.mat");
		material.setTextureParam("u_DiffuseMap", VarType.TEXTURE2D, texture);

		return material;
	}

	private function createFlame():Void
	{
		flame = new ParticleEmitter("Flame", 32 * COUNT_FACTOR);
		flame.randomImage = true;
		flame.setStartColor(new Color(1, 0.4, 0.05));
		flame.setEndColor(new Color(.4, .22, .12));
		flame.setStartAlpha(1 / COUNT_FACTOR_F);
		flame.setEndAlpha(0.0);
		flame.setStartSize(1.3);
		flame.setEndSize(2);
		flame.setShape(new EmitterSphereShape(new Vector3f(), 1));
		flame.setParticlesPerSec(0);
		flame.setGravity(new Vector3f(0, -5, 0));
		flame.setLowLife(.4);
		flame.setHighLife(.5);
		flame.particleInfluencer.setInitialVelocity(new Vector3f(0, 7, 0));
		flame.particleInfluencer.setVelocityVariation(1);
		flame.setImagesX(2);
		flame.setImagesY(2);

		var mat:Material = createMat(EMBED_FLAME);
		flame.setMaterial(mat);
		explosionEffect.attachChild(flame);
	}

	private function createFlash():Void
	{
		flashPE = new ParticleEmitter("Flash", 24 * COUNT_FACTOR);
		flashPE.randomImage = true;
		flashPE.setStartColor(new Color(1, 0.8, 0.36));
		flashPE.setEndColor(new Color(1, 0.8, 0.36));
		flashPE.setStartAlpha(1 / COUNT_FACTOR_F);
		flashPE.setEndAlpha(0.0);
		flashPE.setStartSize(.1);
		flashPE.setEndSize(3.0);
		flashPE.setShape(new EmitterSphereShape(new Vector3f(), .05));
		flashPE.setParticlesPerSec(0);
		flashPE.setGravity(new Vector3f(0, 0, 0));
		flashPE.setLowLife(.2);
		flashPE.setHighLife(.2);
		flashPE.particleInfluencer.setInitialVelocity(new Vector3f(0, 5, 0));
		flashPE.particleInfluencer.setVelocityVariation(1);
		flashPE.setImagesX(2);
		flashPE.setImagesY(2);


		var mat:Material = createMat(EMBED_FLASH);
		flashPE.setMaterial(mat);
		explosionEffect.attachChild(flashPE);
	}

	private function createRoundSpark():Void
	{
		roundspark = new ParticleEmitter("RoundSpark", 20 * COUNT_FACTOR);
		roundspark.setStartColor(new Color(1, 0.29, 0.34));
		roundspark.setEndColor(new Color(0, 0, 0));
		roundspark.setStartAlpha(1 / COUNT_FACTOR_F);
		roundspark.setEndAlpha(0.5 / COUNT_FACTOR_F);
		roundspark.setStartSize(1.2);
		roundspark.setEndSize(1.8);
		roundspark.setShape(new EmitterSphereShape(new Vector3f(), 2));
		roundspark.setParticlesPerSec(0);
		roundspark.setGravity(new Vector3f(0, -.5, 0));
		roundspark.setLowLife(1.8);
		roundspark.setHighLife(2);
		roundspark.particleInfluencer.setInitialVelocity(new Vector3f(0, 3, 0));
		roundspark.particleInfluencer.setVelocityVariation(.5);
		roundspark.setImagesX(1);
		roundspark.setImagesY(1);

		var mat:Material = createMat(EMBED_ROUNDSPARK);
		roundspark.setMaterial(mat);
		explosionEffect.attachChild(roundspark);
	}

	private function createSpark():Void
	{
		spark = new ParticleEmitter("Spark", 30 * COUNT_FACTOR);
		spark.setStartColor(new Color(1, 0.8, 0.36, (1.0 / COUNT_FACTOR_F)));
		spark.setEndColor(new Color(1, 0.8, 0.36, 0));
		spark.setStartSize(.5);
		spark.setEndSize(.5);
		spark.setFacingVelocity(true);
		spark.setParticlesPerSec(0);
		spark.setGravity(new Vector3f(0, 5, 0));
		spark.setLowLife(1.1);
		spark.setHighLife(1.5);
		spark.particleInfluencer.setInitialVelocity(new Vector3f(0, 20, 0));
		spark.particleInfluencer.setVelocityVariation(1);
		spark.setImagesX(1);
		spark.setImagesY(1);

		var mat:Material = createMat(EMBED_SPARK);
		spark.setMaterial(mat);
		explosionEffect.attachChild(spark);
	}

	private function createSmokeTrail():Void
	{
		smoketrail = new ParticleEmitter("SmokeTrail", 22 * COUNT_FACTOR);
		smoketrail.setStartColor(new Color(1, 0.8, 0.36, (1.0 / COUNT_FACTOR_F)));
		smoketrail.setEndColor(new Color(1, 0.8, 0.36, 0));
		smoketrail.setStartSize(.2);
		smoketrail.setEndSize(1);

		//        smoketrail.setShape(new EmitterSphereShape(Vector3f.ZERO, 1f));
		smoketrail.setFacingVelocity(true);
		smoketrail.setParticlesPerSec(0);
		smoketrail.setGravity(new Vector3f(0, 1, 0));
		smoketrail.setLowLife(.4);
		smoketrail.setHighLife(.5);
		smoketrail.particleInfluencer.setInitialVelocity(new Vector3f(0, 12, 0));
		smoketrail.particleInfluencer.setVelocityVariation(1);
		smoketrail.setImagesX(1);
		smoketrail.setImagesY(3);

		var mat:Material = createMat(EMBED_SMOKETRAIL);
		smoketrail.setMaterial(mat);
		explosionEffect.attachChild(smoketrail);
	}

	private function createDebris():Void
	{
		debris = new ParticleEmitter("Debris", 15 * COUNT_FACTOR);
		debris.randomImage = true;
		debris.randomAngle = true;
		debris.setRotateSpeed(FastMath.TWO_PI * 4);
		debris.setStartColor(new Color(1, 0.59, 0.28, (1.0 / COUNT_FACTOR_F)));
		debris.setEndColor(new Color(.5, 0.5, 0.5, 0));
		debris.setStartSize(.2);
		debris.setEndSize(.2);

		//debris.setShape(new EmitterSphereShape(new Vector3f(), .05));
		debris.setParticlesPerSec(0);
		debris.setGravity(new Vector3f(0, 12, 0));
		debris.setLowLife(1.4);
		debris.setHighLife(1.5);
		debris.particleInfluencer.setInitialVelocity(new Vector3f(0, 15, 0));
		debris.particleInfluencer.setVelocityVariation(.60);
		debris.setImagesX(3);
		debris.setImagesY(3);

		var mat:Material = createMat(EMBED_DEBRIS);
		debris.setMaterial(mat);
		explosionEffect.attachChild(debris);
	}

	private function createShockwave():Void
	{
		shockwave = new ParticleEmitter("Shockwave", 1 * COUNT_FACTOR);
		//        shockwave.setRandomAngle(true);
		shockwave.setFaceNormal(Vector3f.UNIT_Y);
		shockwave.setStartColor(new Color(.48, 0.17, 0.01, (.8 / COUNT_FACTOR_F)));
		shockwave.setEndColor(new Color(.48, 0.17, 0.01, 0));

		shockwave.setStartSize(0);
		shockwave.setEndSize(7);

		shockwave.setParticlesPerSec(0);
		shockwave.setGravity(new Vector3f(0, 0, 0));
		shockwave.setLowLife(0.5);
		shockwave.setHighLife(0.5);
		shockwave.particleInfluencer.setInitialVelocity(new Vector3f(0, 0, 0));
		shockwave.particleInfluencer.setVelocityVariation(0);
		shockwave.setImagesX(1);
		shockwave.setImagesY(1);

		var mat:Material = createMat(EMBED_SHOCKWAVE);
		shockwave.setMaterial(mat);
		explosionEffect.attachChild(shockwave);
	}

	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);
		
		explosionEffect = new Node("explosionFX");

		flyCam.setDragToRotate(true);

		createFlame();
		createFlash();
		createSpark();
		createRoundSpark();
		createSmokeTrail();
		createDebris();
		createShockwave();
		explosionEffect.setLocalScaleXYZ(0.5, 0.5, 0.5);

		camera.location = new Vector3f(0, 3.5135868, 10);
		camera.rotation = new Quaternion(1.5714673E-4, 0.98696727, -0.16091813, 9.6381607E-4);

		scene.attachChild(explosionEffect);
		
		start();
		
	}

	private var time:Float = 0;
	private var state:Int = 0;

	override public function simpleUpdate(tpf:Float):Void
	{
		super.simpleUpdate(tpf);
		
		time += tpf;
		if (time > 1 && state == 0)
		{
			flashPE.emitAllParticles();
			spark.emitAllParticles();
			smoketrail.emitAllParticles();
			debris.emitAllParticles();
			shockwave.emitAllParticles();
			state++;
		}
		if (time > 1 + .05 && state == 1)
		{
			flame.emitAllParticles();
			roundspark.emitAllParticles();
			state++;
		}

		// rewind the effect
		if (time > 5 && state == 2)
		{
			state = 0;
			time = 0;

			flashPE.killAllParticles();
			spark.killAllParticles();
			smoketrail.killAllParticles();
			debris.killAllParticles();
			flame.killAllParticles();
			roundspark.killAllParticles();
			shockwave.killAllParticles();
		}

		angle += 0.03;
		angle %= FastMath.TWO_PI;

//			cam.location.setTo(Math.cos(angle) * 20, 10, Math.sin(angle) * 20);
//			cam.lookAt(new Vector3f(), Vector3f.Y_AXIS);
	}
}


@:bitmap("../assets/embed/particle/explosion/Debris.png") class EMBED_DEBRIS extends BitmapData { }
@:bitmap("../assets/embed/particle/explosion/flame.png") class EMBED_FLAME extends BitmapData { }
@:bitmap("../assets/embed/particle/explosion/flash.png") class EMBED_FLASH extends BitmapData { }
@:bitmap("../assets/embed/particle/explosion/roundspark.png") class EMBED_ROUNDSPARK extends BitmapData { }
@:bitmap("../assets/embed/particle/explosion/shockwave.png") class EMBED_SHOCKWAVE extends BitmapData { }
@:bitmap("../assets/embed/particle/explosion/smoketrail.png") class EMBED_SMOKETRAIL extends BitmapData {}
@:bitmap("../assets/embed/particle/explosion/spark.png") class EMBED_SPARK extends BitmapData { }