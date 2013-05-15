package org.angle3d.particles.observers;


/** ParticleObservers are used to observe whether a certain condition occurs. This condition is often related to
 the state of a Particle, but also certain situations regarding a ParticleTechnique, ParticleEmitter or even
 the ParticleSystem can be validated.
 ParticleEventHandlers can be added to a ParticleObserve to handle the condition that is registered by the
 ParticleObserver. This mechanism provides a extendable framework for determination of events and processing
 these events.
 ParticleObservers are defined on the same level as a ParticleEmitter and not as part of a ParticleEmitter.
 This is because the ParticleObserver observes ALL particles in the ParticleTechniques?Particle pool.
 A ParticleObserver can contain one or more ParticleEventHandlers.
 */
/**
 * 粒子观察器用于检测某些情况发生时触发一些事件，需要配合ParticleEventHandler使用
 */
class ParticleObserver
{
	public function new()
	{
	}
}
