package org.angle3d.material.technique;
import flash.utils.ByteArray;
import org.angle3d.utils.FileUtil;

/**
 * ...
 * @author 
 */
class TechniqueDirectionalLight extends Technique
{

	public function new() 
	{
		super();
	}

	override private function getVertexSource():String
	{
		return FileUtil.getFileContent("shader/PhongDirectionalLighting.vs");
	}

	override private function getFragmentSource():String
	{
		return FileUtil.getFileContent("shader/PhongDirectionalLighting.fs");
	}
}