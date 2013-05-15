package org.angle3d.particles;

import org.angle3d.math.Vector3f;
import org.angle3d.particles.emitters.ParticleEmitter;

/**
 * Particle is the abstract/virtual class that represents the object to be emitted.
 * Several types of particles are distinguished, where the visual particle is the most obvious one.
 * Other types of particles are also possible. ParticleAffectors, ParticleEmitters, ParticleTechniques
 * and even ParticleSystems can act as a particle.
 */
class Particle implements IParticle
{
	public static inline var DEFAULT_TTL:Float = 10.0;
	public static inline var DEFAULT_MASS:Float = 1.0;

	/**
	 * Pointer to emitter that has emitted the particle.
	 * Since the particle can be reused by several emitters, this values can change.
	 */
	public var parentEmitter:ParticleEmitter;

	/**
	 * Position.
	 */
	public var position:Vector3f;

	// Direction (and speed)
	public var direction:Vector3f;

	/*  Mass of a particle.
	@remarks
	In case of simulations where mass of a particle is needed (i.e. exploding particles of different
	mass) this attribute can be used.
	*/
	public var mass:Float;

	// Time to live, number of seconds left of particles natural life
	public var timeToLive:Float;

	// Total Time to live, number of seconds of particles natural life
	public var totalTimeToLive:Float;

	// The timeFraction is calculated every update. It is used in other observers, affectors, etc. so it is
	// better to calculate it once at the Particle level.
	public var timeFraction:Float;

	// Determine type of particle, to prevent Realtime type checking
	public var particleType:Int;

	// Values that are assigned as soon as the particle is emitted (non-transformed)
	public var originalPosition:Vector3f;
	public var originalDirection:Vector3f;
	public var originalVelocity:Float;
	public var originalDirectionLength:Float; // Length of the direction that has been set
	public var originalScaledDirectionLength:Float; // Length of the direction after multiplication with the velocity

	// Keep latest position
	public var latestPosition:Vector3f;

	/**
	 * Flags that can be used to determine whether a certain condition occurs.
	 * This attribute is used to assign a certain condition to a particle. During processing of the particle
	 * (process all affectors) a certain condition may occur. A particle may expire, reach a certain
	 * threshold, etc. Some of these conditions are determined by a ParticleObserver, but there are
	 * situations where this condition has been determined even before the ParticleObserver has done its
	 * validation. One example is the determination of an expired particle. Since we want to prevent that
	 * a ParticleObserver validates the same condition, a flag can be set.
	 */
	private var mEventFlags:UInt;

	/**
	 * Determines whether the particle is marked for emission.
	 * This means that the particle is emitted. This is obvious for visual particles, but
	 * a ParticleEmitter for instance is also a Particle; this means that is can be emitted also.
	 */
	private var mMarkedForEmission:Bool;

	/**
	 * Determines whether a particle is activated.
	 * This attribute is particularly used for child classes that must have a capability to be
	 * enabled or disabled (emitters, affectors, ...). There is no need for disabling a visual particle,
	 * because expiring a particle seems sufficient. The default value of this attribute is true.
	 */
	private var mEnabled:Bool;

	/**
	 * Determines whether a particle is 'freezed'. This means that the particle doesnt move anymore.
	 */
	private var mFreezed:Bool;

	/**
	 * Original setting.
	 */
	private var mOriginalEnabled:Bool;

	/**
	 * Original may be set only once.
	 */
	private var mOriginalEnabledSet:Bool;

	/**
	 * Because the public attribute position is sometimes used for both localspace and worldspace
	 * position, the mDerivedPosition attribute is introduced.
	 */
	private var mDerivedPosition:Vector3f;

	public function new(type:Int)
	{
		particleType = type;

		mMarkedForEmission = false;
		position = new Vector3f();
		mDerivedPosition = new Vector3f();
		direction = new Vector3f();
		timeToLive = DEFAULT_TTL;
		totalTimeToLive = DEFAULT_TTL;
		timeFraction = 0.0;
		particleType = ParticleType.PT_VISUAL;

		mass = DEFAULT_MASS;
		mEventFlags = 0;
		mEnabled = true;
		mFreezed = false;
		mOriginalEnabled = true;
		mOriginalEnabledSet = false;
		originalPosition = new Vector3f();
		latestPosition = new Vector3f();
		originalDirection = new Vector3f();
		originalDirectionLength = 0.0;
		originalScaledDirectionLength = 0.0;
		originalVelocity = 0.0;
		parentEmitter = null;
	}

	public function _isMarkedForEmission():Bool
	{
		return mMarkedForEmission;
	}

	public function _setMarkedForEmission(markedForEmission:Bool):Void
	{
		mMarkedForEmission = markedForEmission;
	}

	/** Perform initialising activities as soon as the particle is emitted.
	 */
	public function _initForEmission():Void
	{
		mEventFlags = 0;
		timeFraction = 0.0;

		/*	Note, that this flag must only be set as soon as the particle is emitted. As soon as the particle has
		been moved once, the flag must be removed again.
		*/
		addEventFlags(ParticleEventFlags.PEF_EMITTED);

		// Reset freeze flag
		mFreezed = false;

	}

	/** Todo
	 */
	public function isEnabled():Bool
	{
		return mEnabled;
	}

	/** Todo
	 */
	public function setEnabled(enabled:Bool):Void
	{
		mEnabled = enabled;
		if (!mOriginalEnabledSet)
		{
			// Only one time is permitted
			mOriginalEnabled = enabled;
			mOriginalEnabledSet = true;
		}
	}

	/** This function sets the original 'enabled' value of the particle.
	 @remarks
	 Only use this function if you really know what you're doing. Otherwise it shouldn't be used for regular usage.
	 */
	public function _setOriginalEnabled(originalEnabled:Bool):Void
	{
		mOriginalEnabled = originalEnabled;
		mOriginalEnabledSet = true;
	}

	/** Returns the original 'enabled' value of the particle
	 */
	public function _getOriginalEnabled():Bool
	{
		return mOriginalEnabled;
	}

	/** Returns true if the particle is freezed and doesn't move anymore.
	 @remarks
	 Although it is freezed, repositioning the particle is still possible.
	 */
	public function isFreezed():Bool
	{
		return mFreezed;
	}

	/** Freeze the particle, so it doesn't move anymore.
	 */
	public function setFreezed(freezed:Bool):Void
	{
		mFreezed = freezed;
	}

	/** Sets the event flags.
	 */
	public function setEventFlags(flags:UInt):Void
	{
		mEventFlags = flags;
	}

	/** As setEventFlags, except the flags passed as parameters are appended to the
	 existing flags on this object.
	 */
	public function addEventFlags(flags:UInt):Void
	{
		mEventFlags |= flags;
	}

	/** The flags passed as parameters are removed from the existing flags.
	 */
	public function removeEventFlags(flags:UInt):Void
	{
		mEventFlags &= ~flags;
	}

	/** Return the event flags.
	 */
	public function getEventFlags():UInt
	{
		return mEventFlags;
	}

	/** Determines whether it has certain flags set.
	 */
	public function hasEventFlags(flags:UInt):Bool
	{
		return (mEventFlags & flags) != 0;
	}

	/**
	 * Perform actions on the particle itself during the update loop of a ParticleTechnique.
	 * Active particles may want to do some processing themselves each time the ParticleTechnique is updated.
	 * One example is to perform actions by means of the registered ParticleBehaviour objects.
	 * ParticleBehaviour objects apply internal behaviour of each particle individually. They add both
	 * data and behaviour to a particle, which means that each particle can be extended with functionality.
	 */
	public function _process(technique:ParticleTechnique, timeElapsed:Float):Void
	{
		// Calculate the time fraction, because it is used in different other components
		timeFraction = (totalTimeToLive - timeToLive) / totalTimeToLive;
	}

	/** Calculates the velocity, based on the direction vector.
	 */
	public function calculateVelocity():Float
	{
		if (originalScaledDirectionLength != 0)
		{
			return originalVelocity * (direction.length / originalScaledDirectionLength);
		}
		else
		{
			// Assume originalScaledDirectionLength to be 1.0 (unit vector)
			return originalVelocity * direction.length;
		}
	}

	public function copyAttributesTo(particle:Particle):Void
	{
		// Copy attributes
		particle.position = position;
		particle.originalPosition = originalPosition;
		particle.mDerivedPosition = mDerivedPosition;
		particle.direction = direction;
		particle.originalDirection = originalDirection;
		particle.originalDirectionLength = originalDirectionLength;
		particle.originalScaledDirectionLength = originalScaledDirectionLength;
		particle.originalVelocity = originalVelocity;
		particle.mass = mass;
		particle.timeToLive = timeToLive;
		particle.totalTimeToLive = totalTimeToLive;
		particle.mEventFlags = mEventFlags;
		particle.mMarkedForEmission = mMarkedForEmission;
		particle.mEnabled = mEnabled;
		particle.mOriginalEnabled = mOriginalEnabled;
		particle.mOriginalEnabledSet = mOriginalEnabledSet;
		particle.mFreezed = mFreezed;
		particle.timeFraction = timeFraction;
	}
}
