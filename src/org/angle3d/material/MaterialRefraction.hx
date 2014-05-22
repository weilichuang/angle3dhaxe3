package org.angle3d.material;

import org.angle3d.material.technique.TechniqueRefraction;
import org.angle3d.texture.CubeTextureMap;
import org.angle3d.texture.TextureMapBase;

/**
 * Refraction mapping
 * @author andy
 */
class MaterialRefraction extends Material
{
	private var _technique:TechniqueRefraction;

	/**
	 *
	 * @param decalMap
	 * @param environmentMap
	 * @param etaRatio
	 * @param transmittance
	 *
	 */
	public function new(decalMap:TextureMapBase, environmentMap:CubeTextureMap, etaRatio:Float = 1.5, transmittance:Float = 0.5)
	{
		super();

		_technique = new TechniqueRefraction(decalMap, environmentMap, etaRatio, transmittance);
		addTechnique(_technique);
	}
}

