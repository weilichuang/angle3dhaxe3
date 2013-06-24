package org.angle3d.particles.attribute;

import org.angle3d.math.FastMath;

class DynamicAttributeOscillate extends DynamicAttribute
{
	private var mOscillationType:Int;
	private var mFrequency:Float;
	private var mPhase:Float;
	private var mBase:Float;
	private var mAmplitude:Float;

	public function new()
	{
		super();

		type = DynamicAttributeType.DAT_OSCILLATE;

		mOscillationType = OscillationType.OSCT_SINE;
		mFrequency = 1.0;
		mPhase = 0.0;
		mBase = 0.0;
		mAmplitude = 1.0;
	}

	public function getOscillationType():Int
	{
		return mOscillationType;
	}

	public function setOscillationType(value:Int):Void
	{
		mOscillationType = value;
	}

	public function getFrequency():Float
	{
		return mFrequency;
	}

	public function setFrequency(value:Float):Void
	{
		mFrequency = value;
	}

	public function getPhase():Float
	{
		return mPhase;
	}

	public function setPhase(value:Float):Void
	{
		mPhase = value;
	}

	public function getBase():Float
	{
		return mBase;
	}

	public function setBase(value:Float):Void
	{
		mBase = value;
	}

	public function getAmplitude():Float
	{
		return mAmplitude;
	}

	public function setAmplitude(value:Float):Void
	{
		mAmplitude = value;
	}

	override public function getValue(x:Float):Float
	{
		switch (mOscillationType)
		{
			case OscillationType.OSCT_SINE:
				return mBase + mAmplitude * Math.sin(mPhase + mFrequency * x * Math.PI * 2);
			case OscillationType.OSCT_SQUARE:
				return mBase + mAmplitude * FastMath.signum(Math.sin(mPhase + mFrequency * x * Math.PI * 2));
		}

		return 0;
	}

	override public function copyAttributesTo(dynamicAttribute:DynamicAttribute):Void
	{
		if (dynamicAttribute == null || dynamicAttribute.type != DynamicAttributeType.DAT_OSCILLATE)
			return;

		var dynAttr:DynamicAttributeOscillate = Std.instance(dynamicAttribute,DynamicAttributeOscillate);
		dynAttr.mOscillationType = mOscillationType;
		dynAttr.mFrequency = mFrequency;
		dynAttr.mPhase = mPhase;
		dynAttr.mBase = mBase;
		dynAttr.mAmplitude = mAmplitude;
	}
}
