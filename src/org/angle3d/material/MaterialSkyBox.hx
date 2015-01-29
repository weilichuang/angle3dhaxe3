package org.angle3d.material;

import org.angle3d.material.technique.TechniqueSkyBox;
import org.angle3d.texture.CubeTextureMap;

/**
 * andy
 * @author weilichuang
 */

class MaterialSkyBox extends Material
{
	private var _technique:TechniqueSkyBox;

	public function new(cubeTexture:CubeTextureMap)
	{
		super();

		_technique = new TechniqueSkyBox(cubeTexture);

		setTechnique(_technique);
	}

}


