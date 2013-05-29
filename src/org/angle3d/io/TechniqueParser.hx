package org.angle3d.io;

import org.angle3d.material.TechniqueDef;

class TechniqueParser
{
	public function new()
	{
	}

	public function parse(technique:Dynamic):TechniqueDef
	{
		var def:TechniqueDef = new TechniqueDef(technique.name);
		def.vertLanguage = technique.vs;
		def.fragLanguage = technique.fs;
		//if (technique.worldparameters != null)
		//{
			//var params:Array = technique.worldparameters;
			//for (i in 0...params.length)
			//{
				//def.addWorldParam(params[i]);
			//}
		//}

		if (technique.defines != null)
		{
			var defines:Array<Dynamic> = technique.defines;
			for (i in 0...defines.length)
			{
				var define:Dynamic = defines[i];
				def.addShaderParamDefine(define.param, define.define);
			}
		}
		return def;
	}
}
