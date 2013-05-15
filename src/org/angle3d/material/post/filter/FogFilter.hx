package org.angle3d.material.post.filter;

import org.angle3d.material.Material;
import org.angle3d.material.post.Filter;
import org.angle3d.math.Color;
import org.angle3d.renderer.RenderManager;
import org.angle3d.renderer.ViewPort;

class FogFilter extends Filter
{
	private var fogColor:Color;
	private var fogDensity:Float;
	private var fogDistance:Float;

	public function new()
	{
		super("FogFilter");
	}

	override public function isRequiresDepthTexture():Bool
	{
		return true;
	}

	override private function initFilter(renderManager:RenderManager, vp:ViewPort, w:Int, h:Int):Void
	{
		material = new Material();
		material.setColor("FogColor", fogColor);
		material.setFloat("FogDensity", fogDensity);
		material.setFloat("FogDistance", fogDistance);
	}

	override public function getMaterial():Material
	{
		return material;
	}


	/**
	 * returns the fog color
	 * @return
	 */
	public function getFogColor():Color
	{
		return fogColor;
	}

	/**
	 * Sets the color of the fog
	 * @param fogColor
	 */
	public function setFogColor(fogColor:Color):Void
	{
		if (material != null)
		{
			material.setColor("FogColor", fogColor);
		}
		this.fogColor = fogColor;
	}

	/**
	 * returns the fog density
	 * @return
	 */
	public function getFogDensity():Bool
	{
		return fogDensity;
	}

	/**
	 * Sets the density of the fog, a high value gives a thick fog
	 * @param fogDensity
	 */
	public function setFogDensity(fogDensity:Float):Void
	{
		if (material != null)
		{
			material.setFloat("FogDensity", fogDensity);
		}
		this.fogDensity = fogDensity;
	}

	/**
	 * returns the fog distance
	 * @return
	 */
	public function getFogDistance():Float
	{
		return fogDistance;
	}

	/**
	 * the distance of the fog. the higer the value the distant the fog looks
	 * @param fogDistance
	 */
	public function setFogDistance(fogDistance:Float):Void
	{
		if (material != null)
		{
			material.setFloat("FogDistance", fogDistance);
		}
		this.fogDistance = fogDistance;
	}
}
