package org.angle3d.io.parser.material;

import flash.Vector;
import haxe.Json;
import org.angle3d.material.CullMode;
import org.angle3d.material.BlendMode;
import org.angle3d.material.LightMode;
import org.angle3d.material.MaterialDef;
import org.angle3d.material.RenderState;
import org.angle3d.material.ShadowMode;
import org.angle3d.material.TechniqueDef;
import org.angle3d.material.VarType;
import org.angle3d.math.Color;
import org.angle3d.math.Matrix3f;
import org.angle3d.math.Matrix4f;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector2f;
import org.angle3d.math.Vector3f;
import org.angle3d.math.Vector4f;

class MaterialParser
{
	public function new()
	{
	}

	public static function parse(jsonObj:Dynamic):MaterialDef
	{
		var materialDef:MaterialDef = new MaterialDef();

		var parameters:Array<Dynamic> = jsonObj.parameters;
		if (parameters != null)
		{
			for (param in parameters)
			{
				var value:Dynamic = null;
				switch(param.type)
				{
					case VarType.COLOR:
						value = new Color(param.value[0], param.value[1], param.value[2], param.value[3]);
					case VarType.VECTOR2:
						value = new Vector2f(param.value[0], param.value[1]);
					case VarType.VECTOR3:
						value = new Vector3f(param.value[0], param.value[1], param.value[2]);
					case VarType.VECTOR4:
						value = new Vector4f(param.value[0], param.value[1], param.value[2], param.value[3]);
					case VarType.QUATERNION:
						value = new Quaternion(param.value[0], param.value[1], param.value[2], param.value[3]);
					case VarType.MATRIX3:
						value = new Matrix3f().setArray(param.value);
					case VarType.MATRIX4:
						value = new Matrix4f().setArray(param.value);
					case VarType.Vector4Array:
						value = Vector.ofArray(param.value);
					default:
						value = param.value;
				}
				materialDef.addMaterialParam(param.type, param.name, value);
			}
		}

		var techniques:Array<Dynamic> = jsonObj.techniques;
		if (techniques != null)
		{
			for (i in 0...techniques.length)
			{
				materialDef.addTechniqueDef(parseTechnique(techniques[i]));
			}
		}

		return materialDef;
	}
	
	public static function parseTechnique(technique:Dynamic):TechniqueDef
	{
		var techniqueDef:TechniqueDef = new TechniqueDef();
		techniqueDef.name = technique.name;
		techniqueDef.vertName = technique.vs;
		techniqueDef.fragName = technique.fs;
		
		if (technique.lightMode != null)
		{
			techniqueDef.lightMode = Type.createEnum(LightMode, technique.lightMode);
		}
		
		if (technique.shadowMode != null)
		{
			techniqueDef.shadowMode = Type.createEnum(ShadowMode, technique.shadowMode);
		}
		
		if (technique.worldParams != null)
		{
			var worldParams:Array<Dynamic> = technique.worldParams;
			for (i in 0...worldParams.length)
			{
				techniqueDef.addWorldParam(worldParams[i]);
			}
		}

		if (technique.renderState != null)
		{
			var renderState:RenderState = new RenderState();
			var statements:Array<Dynamic> = technique.renderState;
			for (i in 0...statements.length)
			{
				var statement:Dynamic = statements[i];
				readRenderStateStatement(renderState, statement);
			}
			techniqueDef.renderState = renderState;
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
			techniqueDef.forcedRenderState = forcedRenderState;
		}
		
		if (technique.defines != null)
		{
			var defines:Array<Dynamic> = technique.defines;
			for (i in 0...defines.length)
			{
				var define:Dynamic = defines[i];
				if (define.condition == null || define.condition == true)
				{
					techniqueDef.addShaderPresetDefine(define.name, VarType.BOOL, true);
				}
				else if (define.condition == "" || define.condition == false)
				{
					techniqueDef.addShaderPresetDefine(define.name, VarType.BOOL, false);
				}
				else
				{
					techniqueDef.addShaderParamDefine(define.condition, define.name);
				}
			}
		}
		
		return techniqueDef;
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
