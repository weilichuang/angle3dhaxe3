package org.angle3d.material.logic;

import org.angle3d.light.DirectionalLight;
import org.angle3d.light.Light;
import org.angle3d.light.LightList;
import org.angle3d.light.LightType;
import org.angle3d.light.PointLight;
import org.angle3d.light.SpotLight;
import org.angle3d.material.TechniqueDef;
import org.angle3d.shader.DefineList;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.shader.Uniform;
import org.angle3d.math.Color;
import org.angle3d.math.Matrix4f;
import org.angle3d.math.Vector3f;
import org.angle3d.math.Vector4f;
import org.angle3d.renderer.Caps;
import org.angle3d.renderer.RenderManager;
import org.angle3d.renderer.Renderer;
import org.angle3d.scene.Geometry;
import org.angle3d.shader.VarType;

/**
 * SinglePassLightingLogic
 */
class SinglePassLightingLogic extends DefaultTechniqueDefLogic {
	private static inline var DEFINE_NB_LIGHTS:String = "NB_LIGHTS";

	private static inline var SINGLE_PASS_LIGHTING1:String = "SINGLE_PASS_LIGHTING1";
	private static inline var SINGLE_PASS_LIGHTING2:String = "SINGLE_PASS_LIGHTING2";
	private static inline var SINGLE_PASS_LIGHTING3:String = "SINGLE_PASS_LIGHTING3";

	private static var ADDITIVE_LIGHT:RenderState;

	private static var BLACK_COLOR:Color;

	/**
	 * 特殊函数，用于执行一些static变量的定义等(有这个函数时，static变量预先赋值必须也放到这里面)
	 */
	static function __init__():Void {
		ADDITIVE_LIGHT = new RenderState();
		ADDITIVE_LIGHT.setBlendMode(BlendMode.AlphaAdditive);
		ADDITIVE_LIGHT.setDepthWrite(false);

		BLACK_COLOR = new Color(0, 0, 0, 1);
	}

	private var ambientLightColor:Color = new Color(0, 0, 0, 1);
	private var nbLightsDefineId:Int;

	private var lightPassDefineId1:Int;
	private var lightPassDefineId2:Int;
	private var lightPassDefineId3:Int;

	private var tmpVec:Vector4f = new Vector4f();

	public function new(techniqueDef:TechniqueDef) {
		super(techniqueDef);

		nbLightsDefineId = techniqueDef.addShaderUnmappedDefine(DEFINE_NB_LIGHTS, VarType.INT);

		lightPassDefineId1 = techniqueDef.addShaderUnmappedDefine(SINGLE_PASS_LIGHTING1, VarType.BOOL);
		lightPassDefineId2 = techniqueDef.addShaderUnmappedDefine(SINGLE_PASS_LIGHTING2, VarType.BOOL);
		lightPassDefineId3 = techniqueDef.addShaderUnmappedDefine(SINGLE_PASS_LIGHTING3, VarType.BOOL);
	}

	override public function makeCurrent(renderManager:RenderManager, material:Material, rendererCaps:Array<Caps>, lights:LightList, defines:DefineList):Shader {
		var batchSize:Int = renderManager.getSinglePassLightBatchSize();

		defines.set(nbLightsDefineId, batchSize * 3);
		defines.setBool(lightPassDefineId1, batchSize >= 2);
		defines.setBool(lightPassDefineId2, batchSize >= 3);
		defines.setBool(lightPassDefineId3, batchSize >= 4);
		return super.makeCurrent(renderManager, material, rendererCaps, lights, defines);
	}

	/**
	 * Uploads the lights in the light list as two uniform arrays.<br/>
	 * <p>
	 * `uniform vec4 g_LightColor[numLights];`<br/>
	 * g_LightColor.rgb is the diffuse/specular color of the light.<br/>
	 * g_Lightcolor.a is the type of light, 0 = Directional, 1 = Point, 2 = Spot. <br/>
	 * `uniform vec4 g_LightPosition[numLights];`<br/>
	 * g_LightPosition.xyz is the position of the light (for point lights)<br/>
	 * or the direction of the light (for directional lights).<br/>
	 * g_LightPosition.w is the inverse radius (1/r) of the light (for attenuation) <br/> </p>
	 */
	private function updateLightListUniforms(shader:Shader, g:Geometry, lights:Array<Light>, batchSize:Int, rm:RenderManager, startIndex:Int):Int {
		// this shader does not do lighting, ignore.
		if (batchSize == 0) {
			return 0;
		}

		var lightData:Uniform = shader.getUniform("gu_LightData");
		lightData.setVector4Length(batchSize * 3);//4 lights * max 3

		var ambientColorUniform:Uniform = shader.getUniform("gu_AmbientLightColor");
		if (startIndex != 0) {
			// apply additive blending for 2nd and future passes
			rm.getRenderer().applyRenderState(ADDITIVE_LIGHT);
			ambientColorUniform.setColor(BLACK_COLOR);
		} else
		{
			ambientColorUniform.setColor(ambientLightColor);
		}

		var viewMatrix:Matrix4f = rm.getCurrentCamera().getViewMatrix();

		var lightDataIndex:Int = 0;

		var lightCount:Int = lights.length;
		var curIndex:Int = startIndex;
		var endIndex:Int = batchSize + startIndex;
		while (curIndex < endIndex && curIndex < lightCount) {
			var light:Light = lights[curIndex];
			//if (light.type == LightType.Ambient)
			//{
			//endIndex++;
			//curIndex++;
			//continue;
			//}

			var color:Color = light.color;
			//Color
			lightData.setVector4InArray(color.r, color.g, color.b, light.type.toInt(), lightDataIndex);
			lightDataIndex++;

			switch (light.type) {
				case LightType.Directional:
					var dl:DirectionalLight = cast light;
					var dir:Vector3f = dl.direction;
					//Data directly sent in view space to avoid a matrix mult for each pixel
					tmpVec.setTo(dir.x, dir.y, dir.z, 0.0);
					viewMatrix.multVec4(tmpVec, tmpVec);
//                        tmpVec.divideLocal(tmpVec.w);
//                        tmpVec.normalizeLocal();
					lightData.setVector4InArray(tmpVec.x, tmpVec.y, tmpVec.z, -1, lightDataIndex);
					lightDataIndex++;
					//PADDING
					lightData.setVector4InArray(0, 0, 0, 0, lightDataIndex);
					lightDataIndex++;

				case LightType.Point:
					var pl:PointLight = cast light;
					var pos:Vector3f = pl.position;
					tmpVec.setTo(pos.x, pos.y, pos.z, 1.0);
					viewMatrix.multVec4(tmpVec, tmpVec);
					//tmpVec.divideLocal(tmpVec.w);
					lightData.setVector4InArray(tmpVec.x, tmpVec.y, tmpVec.z, pl.invRadius, lightDataIndex);
					lightDataIndex++;
					//PADDING
					lightData.setVector4InArray(0, 0, 0, 0, lightDataIndex);
					lightDataIndex++;

				case LightType.Spot:
					var sl:SpotLight = cast light;

					var pos:Vector3f = sl.position;
					tmpVec.setTo(pos.x, pos.y, pos.z,  1.0);

					viewMatrix.multVec4(tmpVec, tmpVec);
					// tmpVec.divideLocal(tmpVec.w);
					lightData.setVector4InArray(tmpVec.x, tmpVec.y, tmpVec.z, sl.invSpotRange, lightDataIndex);
					lightDataIndex++;

					//We transform the spot direction in view space here to save 5 varying later in the lighting shader
					//one vec4 less and a vec4 that becomes a vec3
					//the downside is that spotAngleCos decoding happens now in the frag shader.
					var dir:Vector3f = sl.direction;
					tmpVec.setTo(dir.x, dir.y, dir.z,  0.0);
					viewMatrix.multVec4(tmpVec, tmpVec);
					tmpVec.normalize();
					lightData.setVector4InArray(tmpVec.x, tmpVec.y, tmpVec.z, sl.packedAngleCos, lightDataIndex);
					lightDataIndex++;
				case LightType.Probe:
				default:
					throw ("Unknown type of light: " + light.type);
			}
			curIndex++;
		}

		//Padding of unsued buffer space
		while (lightDataIndex < batchSize * 3) {
			lightData.setVector4InArray(0, 0, 0, 0, lightDataIndex);
			lightDataIndex++;
		}
		return curIndex;
	}

	private var tmpLights:Array<Light> = new Array<Light>();
	override public function render(renderManager:RenderManager, shader:Shader, geometry:Geometry, lights:LightList):Void {
		var renderer:Renderer = renderManager.getRenderer();
		var batchSize:Int = renderManager.getSinglePassLightBatchSize();

		tmpLights.length = 0;
		DefaultTechniqueDefLogic.calcAmbientColor(lights, tmpLights, ambientLightColor);

		if (tmpLights.length == 0) {
			updateLightListUniforms(shader, geometry, tmpLights, batchSize, renderManager, 0);
			renderer.setShader(shader);
			DefaultTechniqueDefLogic.renderMeshFromGeometry(renderer, geometry);
		} else
		{
			var nbRenderedLights:Int = 0;
			//如果灯光数量超过上限，则会分成多次渲染
			while (nbRenderedLights < tmpLights.length) {
				nbRenderedLights = updateLightListUniforms(shader, geometry, tmpLights, batchSize, renderManager, nbRenderedLights);
				renderer.setShader(shader);
				DefaultTechniqueDefLogic.renderMeshFromGeometry(renderer, geometry);
			}
		}
	}
}