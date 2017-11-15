package org.angle3d.effect.cpu.influencers;

import org.angle3d.effect.cpu.Particle;
import org.angle3d.effect.cpu.shape.EmitterShape;
import org.angle3d.math.FastMath;
import org.angle3d.math.Matrix3f;

/**
 * This influencer calculates initial velocity with the use of the emitter's shape.
 */
class NewtonianParticleInfluencer extends DefaultParticleInfluencer {

	/** Normal to emitter's shape factor. */
	private var normalVelocity:Float;
	/** Emitter's surface tangent factor. */
	private var surfaceTangentFactor:Float;
	/** Emitters tangent rotation factor. */
	private var surfaceTangentRotation:Float;

	public function new() {
		super();
		this.velocityVariation = 0.0;
	}

	override public function influenceParticle(particle:Particle, emitterShape:EmitterShape):Void {
		emitterShape.getRandomPointAndNormal(particle.position, particle.velocity);

		// influencing the particle's velocity
		if (surfaceTangentFactor == 0.0) {
			particle.velocity.scaleLocal(normalVelocity);
		} else
		{
			// calculating surface tangent (velocity contains the 'normal' value)
			temp.setTo(particle.velocity.z * surfaceTangentFactor, particle.velocity.y * surfaceTangentFactor, -particle.velocity.x * surfaceTangentFactor);
			if (surfaceTangentRotation != 0.0) {
				// rotating the tangent
				var m:Matrix3f = new Matrix3f();
				m.fromAngleNormalAxis(Math.PI * surfaceTangentRotation, particle.velocity);
				temp = m.multVec(temp);
			}
			// applying normal factor (this must be done first)
			particle.velocity.scaleLocal(normalVelocity);
			// adding tangent vector
			particle.velocity.addLocal(temp);
		}

		if (velocityVariation != 0.0) {
			this.applyVelocityVariation(particle);
		}
	}

	/**
	 * This method returns the normal velocity factor.
	 * @return the normal velocity factor
	 */
	public function getNormalVelocity():Float {
		return normalVelocity;
	}

	/**
	 * This method sets the normal velocity factor.
	 * @param normalVelocity
	 *        the normal velocity factor
	 */
	public function setNormalVelocity(normalVelocity:Float):Void {
		this.normalVelocity = normalVelocity;
	}

	/**
	 * This method sets the surface tangent factor.
	 * @param surfaceTangentFactor
	 *        the surface tangent factor
	 */
	public function setSurfaceTangentFactor(surfaceTangentFactor:Float):Void {
		this.surfaceTangentFactor = surfaceTangentFactor;
	}

	/**
	 * This method returns the surface tangent factor.
	 * @return the surface tangent factor
	 */
	public function getSurfaceTangentFactor():Float {
		return surfaceTangentFactor;
	}

	/**
	 * This method sets the surface tangent rotation factor.
	 * @param surfaceTangentRotation
	 *        the surface tangent rotation factor
	 */
	public function setSurfaceTangentRotation(surfaceTangentRotation:Float):Void {
		this.surfaceTangentRotation = surfaceTangentRotation;
	}

	/**
	 * This method returns the surface tangent rotation factor.
	 * @return the surface tangent rotation factor
	 */
	public function getSurfaceTangentRotation():Float {
		return surfaceTangentRotation;
	}

	override private function applyVelocityVariation(particle:Particle):Void {
		temp.setTo(Math.random() * velocityVariation, Math.random() * velocityVariation, Math.random() * velocityVariation);
		particle.velocity.addLocal(temp);
	}

	override public function clone():IParticleInfluencer {
		var result:NewtonianParticleInfluencer = new NewtonianParticleInfluencer();
		result.initialVelocity.copyFrom(initialVelocity);
		result.normalVelocity = normalVelocity;
		result.velocityVariation = velocityVariation;
		result.surfaceTangentFactor = surfaceTangentFactor;
		result.surfaceTangentRotation = surfaceTangentRotation;
		return result;
	}
}

