package org.angle3d.particles.attribute;


/* This class generates random values within a given minimum and maximum interval.
*/
class DynamicAttributeRandom extends DynamicAttribute
{
	private var mMin:Float;
	private var mMax:Float;

	public function new()
	{
		super();

		type = DynamicAttributeType.DAT_RANDOM;
	}

	public function setMin(min:Float):Void
	{
		mMin = min;
	}

	public function getMin():Float
	{
		return mMin;
	}

	public function setMax(max:Float):Void
	{
		mMax = max;
	}

	public function getMax():Float
	{
		return mMax;
	}

	public function setMinMax(min:Float, max:Float):Void
	{
		mMin = min;
		mMax = max;
	}

	override public function getValue(x:Float):Float
	{
		return mMin + (mMax - mMin) * Math.random();
	}

	override public function copyAttributesTo(dynamicAttribute:DynamicAttribute):Void
	{
		if (dynamicAttribute == null || dynamicAttribute.type != DynamicAttributeType.DAT_RANDOM)
			return;

		var dynAttr:DynamicAttributeRandom = cast(dynamicAttribute,DynamicAttributeRandom);
		dynAttr.mMin = mMin;
		dynAttr.mMax = mMax;
	}
}
