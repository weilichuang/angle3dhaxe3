package org.angle3d.particles.attribute;


class DynamicAttributeHelper
{
	public function new()
	{
	}

	public function calculate(dyn:DynamicAttribute, x:Float, defaultValue:Float):Float
	{
		if (dyn != null)
		{
			return dyn.getValue(x);
		}

		return defaultValue;
	}
}
