package org.angle3d.particles.attribute;


/*	This class is an implementation of the DynamicAttribute class in its most simple form. It just returns a value
that has previously been set.
@remarks
Although use of a regular attribute within the class that needs it is preferred, its benefit is that it makes
use of the generic 'getValue' mechanism of a DynamicAttribute.
*/
class DynamicAttributeFixed extends DynamicAttribute
{
	private var mValue:Float;

	public function new()
	{
		super();

		type = DynamicAttributeType.DAT_FIXED;
	}

	public function setValue(value:Float):Void
	{
		mValue = value;
	}

	override public function getValue(x:Float):Float
	{
		return mValue;
	}

	override public function copyAttributesTo(dynamicAttribute:DynamicAttribute):Void
	{
		if (dynamicAttribute == null || 
			dynamicAttribute.type != DynamicAttributeType.DAT_FIXED)
			return;

		var dynAttr:DynamicAttributeFixed = cast(dynamicAttribute,DynamicAttributeFixed);
		dynAttr.mValue = mValue;
	}

}
