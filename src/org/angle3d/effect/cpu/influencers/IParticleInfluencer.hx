package org.angle3d.effect.cpu.influencers;

import org.angle3d.effect.cpu.Particle;
import org.angle3d.effect.cpu.shape.EmitterShape;
import org.angle3d.math.Vector3f;

/**
 * An interface that defines the methods to affect initial velocity of the particles.
 * 用于影响粒子初次的速度
 */
interface IParticleInfluencer
{
	/**
	 * This method influences the particle.
	 * @param particle
	 *        particle to be influenced
	 * @param emitterShape
	 *        the shape of it emitter
	 */
	function influenceParticle(particle:Particle, emitterShape:EmitterShape):Void;

	/**
	 * This method clones the influencer instance.
	 * @return cloned instance
	 */
	function clone():IParticleInfluencer;

	/**
	 * @param initialVelocity
	 *        Set the initial velocity a particle is spawned with,
	 *        the initial velocity given in the parameter will be varied according
	 *        to the velocity variation set in {@link ParticleEmitter#setVelocityVariation(float) }.
	 *        A particle will move toward its velocity unless it is effected by the
	 *        gravity.
	 */
	function setInitialVelocity(initialVelocity:Vector3f):Void;

	/**
	 * This method returns the initial velocity.
	 * @return the initial velocity
	 */
	function getInitialVelocity():Vector3f;

	/**
	 * @param variation
	 *        Set the variation by which the initial velocity
	 *        of the particle is determined. <code>variation</code> should be a value
	 *        from 0 to 1, where 0 means particles are to spawn with exactly
	 *        the velocity given in {@link ParticleEmitter#setStartVel(com.jme3.math.Vector3f) },
	 *        and 1 means particles are to spawn with a completely random velocity.
	 */
	function setVelocityVariation(variation:Float):Void;

	/**
	 * This method returns the velocity variation.
	 * @return the velocity variation
	 */
	function getVelocityVariation():Float;

}

