package org.angle3d.io;

import flash.utils.JSON;
import org.angle3d.material.MaterialDef;

class MaterialParser
{
	public function new()
	{
	}

	public static function parse(json:String):MaterialDef
	{
		var jsonObj:Dynamic = JSON.parse(json);

		var def:MaterialDef = new MaterialDef();

		var parameters:Array<Dynamic> = jsonObj.parameters;
		if (parameters != null)
		{
			for (param in parameters)
			{
				def.addMaterialParam(param.type, param.name, param.value);
			}
		}

		var techniques:Array<Dynamic> = jsonObj.techniques;
		if (techniques != null)
		{
			for (i in 0...techniques.length)
			{
				def.addTechniqueDef(TechniqueParser.parse(techniques[i]));
			}
		}

		return def;
	}
}
