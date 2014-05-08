package org.angle3d.material.technique;
import flash.utils.ByteArray;
import org.angle3d.utils.FileUtil;

/**
 * ...
 * @author 
 */
class TechniquePointLight extends Technique
{

	public function new() 
	{
		super();
	}

	override private function getVertexSource():String
	{
		return FileUtil.getFileContent("shader/PhongPointLighting.vs");
	}

	override private function getFragmentSource():String
	{
		return FileUtil.getFileContent("shader/PhongPointLighting.fs");
	}
}