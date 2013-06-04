package org.angle3d.shadow;

/**
 * ...
 * @author 
 */
class DirectionalLightShadowFilter extends AbstractShadowFilter
{

	public function new(shadowMapSize:Int,shadowRenderer:AbstractShadowRenderer) 
	{
		super(shadowMapSize, shadowRenderer);
	}
	
}