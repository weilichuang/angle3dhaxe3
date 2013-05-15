package org.angle3d.io;

import flash.utils.JSON;
import org.angle3d.material.MaterialDef;

class MaterialLoader
{
	public function new()
	{
	}

	public function parse(json:String):MaterialDef
	{
		var jsonObj:Dynamic = JSON.parse(json);

		var def:MaterialDef = new MaterialDef();

		if (jsonObj.parameters != null)
		{
			for (var key:String in jsonObj.parameters)
			{
				var obj:Dynamic = jsonObj.parameters[key];
				def.addMaterialParam(obj.type, key, obj.value);
			}
		}

		if (jsonObj.techniques != null)
		{
			var techniqueParse:TechniqueParser = new TechniqueParser();
			var techniques:Array = jsonObj.techniques;
			for (i in 0...techniques.length)
			{
				def.addTechniqueDef(techniqueParse.parse(techniques[i]));
			}
		}

		return def;
	}
}
