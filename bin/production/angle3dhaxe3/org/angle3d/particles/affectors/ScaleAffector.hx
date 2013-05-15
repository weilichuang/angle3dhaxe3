package org.angle3d.particles.affectors;

import org.angle3d.particles.attribute.DynamicAttribute;
import org.angle3d.particles.Particle;

class ScaleAffector extends ParticleAffector
{
	public static inline var DEFAULT_X_SCALE:Float = 1.0;
	public static inline var DEFAULT_Y_SCALE:Float = 1.0;
	public static inline var DEFAULT_Z_SCALE:Float = 1.0;
	public static inline var DEFAULT_XYZ_SCALE:Float = 1.0;

	private var mDynScaleX:DynamicAttribute;
	private var mDynScaleY:DynamicAttribute;
	private var mDynScaleZ:DynamicAttribute;
	private var mDynScaleXYZ:DynamicAttribute;
	private var mDynScaleXSet:Bool;
	private var mDynScaleYSet:Bool;
	private var mDynScaleZSet:Bool;
	private var mDynScaleXYZSet:Bool;

	private var mSinceStartSystem:Bool;

	private var mLatestTimeElapsed:Float;

	public function new()
	{
		super();
	}

	/** Returns the scale value for the dynamic Scale.
	 */
	private function _calculateScale(dynScale:DynamicAttribute, particle:Particle):Float
	{
		return 0.0;
	}
}
