package org.angle3d.material.technique;

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
		var vb:ByteArray = new DirLightVS();
		return vb.readUTFBytes(vb.length);
	}

	override private function getFragmentSource():String
	{
		var fb:ByteArray = new DirLightFS();
		return fb.readUTFBytes(fb.length);
	}
}

@:file("org/angle3d/material/technique/data/PhongDirectionalLighting.vs") 
class DirLightVS extends flash.utils.ByteArray{}
@:file("org/angle3d/material/technique/data/PhongDirectionalLighting.fs") 
class DirLightFS extends flash.utils.ByteArray{}