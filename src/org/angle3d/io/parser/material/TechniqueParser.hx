package org.angle3d.io.parser.material;

import flash.display3D.Context3DCompareMode;
import org.angle3d.material.BlendMode;
import org.angle3d.material.CullMode;
import org.angle3d.material.LightMode;
import org.angle3d.material.RenderState;
import org.angle3d.material.TechniqueDef;
import org.angle3d.material.TestFunction;

class TechniqueParser
{
	public function new()
	{
	}

	public static function parse(technique:Dynamic):TechniqueDef
	{
		var def:TechniqueDef = new TechniqueDef();
		def.name = technique.name;
		def.vertLanguage = technique.vs;
		def.fragLanguage = technique.fs;
		
		if (technique.lightMode != null)
		{
			def.lightMode = Type.createEnum(LightMode, technique.lightMode);
		}

		if (technique.defines != null)
		{
			var defines:Array<Dynamic> = technique.defines;
			for (i in 0...defines.length)
			{
				var define:Dynamic = defines[i];
				def.addShaderParamDefine(define.name, define.condition);
			}
		}
		
		if (technique.renderstate != null)
		{
			var renderState:RenderState = new RenderState();
			var statements:Array<Dynamic> = technique.renderstate;
			for (i in 0...statements.length)
			{
				var statement:Dynamic = statements[i];
				readRenderStateStatement(renderState, statement);
			}
			def.renderState = renderState;
		}
		
		if (technique.forcedRenderState != null)
		{
			var forcedRenderState:RenderState = new RenderState();
			var statements:Array<Dynamic> = technique.forcedRenderState;
			for (i in 0...statements.length)
			{
				var statement:Dynamic = statements[i];
				readRenderStateStatement(forcedRenderState, statement);
			}
			def.forcedRenderState = forcedRenderState;
		}
		
		return def;
	}
	
	private static function readRenderStateStatement(renderState:RenderState,statement:Dynamic):Void
	{
		switch(statement.type)
		{
			case "cullMode":
				renderState.cullMode = Type.createEnum(CullMode, statement.value);
			case "blendMode":
				renderState.blendMode = Type.createEnum(BlendMode, statement.value);
			case "depthTest":
				renderState.depthTest = statement.value;
				renderState.depthFunc = statement.compareMode;
			case "colorWrite":
				renderState.colorWrite = statement.value;
		}
	}
}
