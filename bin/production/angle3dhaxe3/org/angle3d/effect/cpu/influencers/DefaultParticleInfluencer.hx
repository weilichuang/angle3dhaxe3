package org.angle3d.effect.cpu.influencers;

import org.angle3d.effect.cpu.Particle;
import org.angle3d.effect.cpu.shape.EmitterShape;
import org.angle3d.math.Vector3f;

/**
 * This emitter influences the particles so that they move all in the same direction.
 * The direction may vary a little if the velocity variation is non zero.
 * This influencer is default for the particle emitter.
 * @author Marcin Roguski (Kaelthas)
 */
class DefaultParticleInfluencer implements IParticleInfluencer
{
	/**
	 * Temporary variable used to help with calculations.
	 */
	private var temp:Vector3f;
	/**
	 * The initial velocity of the particles.
	 */
	private var initialVelocity:Vector3f;
	/**
	 * The velocity's variation of the particles.
	 */
	private var velocityVariation:Float;

	public function new()
	{
		temp = new Vector3f();
		initialVelocity = new Vector3f();
		velocityVariation = 0.2;
	}

	public function influenceParticle(particle:Particle, emitterShape:EmitterShape):Void
	{
		emitterShape.getRandomPoint(particle.position);
		this.applyVelocityVariation(particle);
	}

	/**
	 * This method applies the variation to the particle with already set velocity.
	 * @param particle
	 *        the particle to be affected
	 */
	private function applyVelocityVariation(particle:Particle):Void
	{
		particle.velocity.copyFrom(initialVelocity);

		var length:Float = initialVelocity.length;
		temp.x = (Math.random() * 2 - 1) * length;
		temp.y = (Math.random() * 2 - 1) * length;
		temp.z = (Math.random() * 2 - 1) * length;

		particle.velocity.lerp(particle.velocity, temp, velocityVariation);
	}


	public function clone():IParticleInfluencer
	{
		var result:DefaultParticleInfluencer = new DefaultParticleInfluencer();
		result.initialVelocity.copyFrom(initialVelocity);
		result.velocityVariation = velocityVariation;

		return result;
	}


	public function setInitialVelocity(initialVelocity:Vector3f):Void
	{
		this.initialVelocity.copyFrom(initialVelocity);
	}


	public function getInitialVelocity():Vector3f
	{
		return initialVelocity;
	}

	public function setVelocityVariation(variation:Float):Void
	{
		this.velocityVariation = variation;
	}

	public function getVelocityVariation():Float
	{
		return velocityVariation;
	}
}

