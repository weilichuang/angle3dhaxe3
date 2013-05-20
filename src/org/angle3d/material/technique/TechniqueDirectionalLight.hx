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
	
	override private function initSouce():Void
	{
		var vb:ByteArray = new DirLightVS();
		mVertexSource =  vb.readUTFBytes(vb.length);
		
		var fb:ByteArray = new DirLightFS();
		mFragmentSource = fb.readUTFBytes(fb.length);
	}
	
}

@:file("org/angle3d/material/technique/data/PhongDirectionalLighting.vs") 
class DirLightVS extends flash.utils.ByteArray{}
@:file("org/angle3d/material/technique/data/PhongDirectionalLighting.fs") 
class DirLightFS extends flash.utils.ByteArray{}