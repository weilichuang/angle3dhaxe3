package org.angle3d.particles;

/**
 * A VisualParticle is the most obvious implementation of a particle. It represents that particles that can be
 * visualised on the screen.
 */
class VisualParticle extends Particle
{
	/** Current and original color */
	public var color:UInt;
	public var originalColor:UInt;

	/** zRotation is used to rotate the particle in 2D (around the Z-axis)
	 @remarks
	 There is no relation between zRotation and orientation.
	 rotationSpeed in combination with orientation are used for 3D rotation of the particle, while
	 zRotation means the rotation around the Z-axis. This type of rotation is typically used for
	 rotating textures. This also means that both types of rotation can be used together.
	 */
	public var zRotation:Float;

	/** The zRotationSpeed is used in combination with zRotation and defines tha actual rotationspeed
	 in 2D. */
	public var zRotationSpeed:Float;

	/** Does this particle have it's own dimensions? */
	public var ownDimensions:Bool;

	/** Own width
	 */
	public var width:Float;

	/** Own height
	 */
	public var height:Float;

	//TODO 这个好像不需要
	/** Own depth
	 */
	public var depth:Float;

	/** Radius of the particle, to be used for inter-particle collision and such.
	 */
	public var radius:Float;

	/** Animation attributes
	 */
	public var textureAnimationTimeStep:Float;
	public var textureAnimationTimeStepCount:Float;
	public var textureCoordsCurrent:Int;
	public var textureAnimationDirectionUp:Bool;

	public function new()
	{
		super(ParticleType.PT_VISUAL);

		mMarkedForEmission = true; // Default is false, but visual particles are always emitted.

		originalColor = color = 0xFFFFFFFF;
		zRotation = 0;
		zRotationSpeed = 0;
		ownDimensions = false;
		width = height = depth = 1;
		radius = 0.87;

		textureAnimationTimeStep = 0.1;
		textureAnimationTimeStepCount = 0.1;
		textureCoordsCurrent = 0;
		textureAnimationDirectionUp = true;
	}

	override public function _initForEmission():Void
	{
		super._initForEmission();
		textureAnimationTimeStep = 0.1;
		textureAnimationTimeStepCount = 0.0;
		textureCoordsCurrent = 0;
		textureAnimationDirectionUp = true;
	}

	public function setOwnDimensions(newWidth:Float, newHeight:Float, newDepth:Float):Void
	{
		ownDimensions = true;
		width = newWidth;
		height = newHeight;
		depth = newDepth;

		_calculateBoundingSphereRadius();

		parentEmitter.technique._notifyParticleResized();
	}

	public function _calculateBoundingSphereRadius():Void
	{
		radius = 0.5 * Math.max(depth, Math.max(width, height)); // approximation
	}
}
