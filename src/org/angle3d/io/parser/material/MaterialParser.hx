package org.angle3d.io.parser.material;

import flash.Vector;
import org.angle3d.material.BlendMode;
import org.angle3d.material.FaceCullMode;
import org.angle3d.material.LightMode;
import org.angle3d.material.MatParam;
import org.angle3d.material.MaterialDef;
import org.angle3d.material.RenderState;
import org.angle3d.material.TechniqueDef;
import org.angle3d.material.TechniqueShadowMode;
import org.angle3d.material.TestFunction;
import org.angle3d.material.VarType;
import org.angle3d.material.logic.DefaultTechniqueDefLogic;
import org.angle3d.material.logic.MultiPassLightingLogic;
import org.angle3d.material.logic.SinglePassAndImageBasedLightingLogic;
import org.angle3d.material.logic.SinglePassLightingLogic;
import org.angle3d.material.logic.StaticPassLightingLogic;
import org.angle3d.math.Color;
import org.angle3d.math.Matrix3f;
import org.angle3d.math.Matrix4f;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector2f;
import org.angle3d.math.Vector3f;
import org.angle3d.math.Vector4f;
import org.angle3d.utils.Logger;
import org.angle3d.utils.StringUtil;

class MaterialParser
{
	public function new()
	{
	}

	public static function parse(name:String,jsonObj:Dynamic):MaterialDef
	{
		var materialDef:MaterialDef = new MaterialDef();
		materialDef.assetName = name;
		
		if(jsonObj.name != null)
			materialDef.name = jsonObj.name;
		else
			materialDef.name = name;

		var parameters:Array<Dynamic> = jsonObj.parameters;
		if (parameters != null)
		{
			for (param in parameters)
			{
				var type:VarType = VarType.getVarTypeBy(param.type);
				var value:Dynamic = null;
				switch(type)
				{
					case VarType.COLOR:
						if (param.value != null)
							value = new Color(param.value[0], param.value[1], param.value[2], param.value[3]);
					case VarType.VECTOR2:
						if (param.value != null)
							value = new Vector2f(param.value[0], param.value[1]);
					case VarType.VECTOR3:
						if (param.value != null)
							value = new Vector3f(param.value[0], param.value[1], param.value[2]);
					case VarType.VECTOR4:
						if (param.value != null)
							value = new Vector4f(param.value[0], param.value[1], param.value[2], param.value[3]);
					case VarType.QUATERNION:
						if (param.value != null)
							value = new Quaternion(param.value[0], param.value[1], param.value[2], param.value[3]);
					case VarType.MATRIX3:
						if (param.value != null)
							value = new Matrix3f().setArray(param.value);
					case VarType.MATRIX4:
						if (param.value != null)
							value = new Matrix4f().setArray(param.value);
					case VarType.Vector4Array:
						if (param.value != null)
						{
							value = new Vector<Float>();
							for (i in 0...param.value.length)
							{
								value[i] = param.value[i];
							}
						}
					case VarType.FLOAT, VarType.INT:
						if (param.value == null)
						{
							value = Math.NaN;
						}
						else
						{
							value = param.value;
						}
					default:
						value = param.value;
				}
				materialDef.addMaterialParam(type, param.name, value);
			}
		}

		var techniques:Array<Dynamic> = jsonObj.techniques;
		if (techniques != null)
		{
			for (i in 0...techniques.length)
			{
				materialDef.addTechniqueDef(parseTechnique(techniques[i],materialDef));
			}
		}

		return materialDef;
	}
	
	public static function parseTechnique(technique:Dynamic,materialDef:MaterialDef):TechniqueDef
	{
		var techniqueUniqueName:String = materialDef.name + "@" + technique.name;
		
		var techniqueDef:TechniqueDef = new TechniqueDef();
		techniqueDef.init(technique.name, StringUtil.hashCode(techniqueUniqueName));

		if (technique.lightMode == null)
			technique.lightMode = "Disable";

		techniqueDef.lightMode = LightMode.getLightModeBy(technique.lightMode);

		if (technique.shadowMode != null)
		{
			techniqueDef.shadowMode = Type.createEnum(TechniqueShadowMode, technique.shadowMode);
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
				
				var matParam:MatParam = materialDef.getMaterialParam(define.paramName);
				if (matParam == null)
				{
					Logger.warn('In technique ${techniqueDef.name} \n Define ${define.name} mapped to non-existent material parameter ${define.paramName}');
					continue;
				}
				
				techniqueDef.addShaderParamDefine(define.paramName, matParam.type, define.name);
			}
		}
		
		techniqueDef.setShaderFile(technique.vs, technique.fs, technique.version);
		
		switch(techniqueDef.lightMode)
		{
			case LightMode.Disable:
				techniqueDef.setLogic(new DefaultTechniqueDefLogic(techniqueDef));
			case LightMode.SinglePass:
				techniqueDef.setLogic(new SinglePassLightingLogic(techniqueDef));
			case LightMode.MultiPass:
				techniqueDef.setLogic(new MultiPassLightingLogic(techniqueDef));
			case LightMode.StaticPass:
				techniqueDef.setLogic(new StaticPassLightingLogic(techniqueDef));
			case LightMode.SinglePassAndImageBased:
				techniqueDef.setLogic(new SinglePassAndImageBasedLightingLogic(techniqueDef));
		}
		
		return techniqueDef;
	}
	
	private static function readRenderStateStatement(renderState:RenderState,statement:Dynamic):Void
	{
		switch(statement.type)
		{
			case "CullMode":
				renderState.setCullMode(statement.value);
			case "BlendMode":
				renderState.setBlendMode(BlendMode.getBlendModeBy(statement.value));
			case "DepthFunc":
				renderState.setDepthFunc(statement.value);
			case "DepthTest":
				renderState.setDepthTest(statement.value);
			case "ColorWrite":
				renderState.setColorWrite(statement.value);
			case "DepthWrite":
				renderState.setDepthWrite(statement.value);	
		}
	}
}
