package org.angle3d.particles;
import flash.Vector;

/**
 * A ParticleSystem is the most top level of a particle structure, that consists of Particles, ParticleEmitters,
 * ParticleAffectors, ParticleObservers, etc.
 * The ParticleSystem can be seen as the container that includes the components that are needed to create,
 * display and move particles.
 */
class ParticleSystem
{
	public var numTechniques(get, null):Int;
	private var _techniques:Vector<ParticleTechnique>;
	private var _numTechniques:Int;

	public function new()
	{
		_techniques = new Vector<ParticleTechnique>();
		_numTechniques = 0;
	}

	public function addTechnique(technique:ParticleTechnique):Void
	{
		_techniques.push(technique);
		_numTechniques++;
	}

	public function removeTechnique(technique:ParticleTechnique):Void
	{
		var index:Int = _techniques.indexOf(technique);
		if (index > -1)
		{
			_techniques.splice(index, 1);
			_numTechniques--;
		}
	}

	public function getTechniqueAt(index:Int):ParticleTechnique
	{
		return _techniques[index];
	}

	public function getTechnique(name:String):ParticleTechnique
	{
		for (i in 0..._numTechniques)
		{
			if (_techniques[i].name == name)
			{
				return _techniques[i];
			}
		}
		return null;
	}

	private function get_numTechniques():Int
	{
		return _numTechniques;
	}

	public function destroyTechnique(technique:ParticleTechnique):Void
	{

	}

	public function destroyAllTechniques():Void
	{

	}

	public function prepare():Void
	{

	}

	/**
	 * Starts the particle system and stops after a period of time.
	 */
	public function start(stopTime:Int = -1):Void
	{

	}

	/**
	 * Stops the particle system.
	 * Only if a particle system has been attached to a SceneNode and started it can be stopped.
	 */
	public function stop():Void
	{

	}

	public function pause():Void
	{

	}

	public function resume():Void
	{

	}
}
