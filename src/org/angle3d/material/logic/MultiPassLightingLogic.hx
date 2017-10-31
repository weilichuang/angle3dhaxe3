package org.angle3d.material.logic;

import org.angle3d.error.Assert;

import org.angle3d.light.Light;
import org.angle3d.light.DirectionalLight;
import org.angle3d.light.LightList;
import org.angle3d.light.LightType;
import org.angle3d.light.PointLight;
import org.angle3d.light.SpotLight;
import org.angle3d.material.TechniqueDef;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.shader.Uniform;
import org.angle3d.math.Color;
import org.angle3d.math.Matrix4f;
import org.angle3d.math.Vector3f;
import org.angle3d.math.Vector4f;
import org.angle3d.renderer.RenderManager;
import org.angle3d.renderer.Stage3DRenderer;
import org.angle3d.scene.Geometry;

/**
 * ...
 * @author weilichuang
 */
class MultiPassLightingLogic extends DefaultTechniqueDefLogic
{
	private static var ADDITIVE_LIGHT:RenderState;
	
	private static var NULL_DIR_LIGHT:Array<Float>;

	private static var BLACK_COLOR:Color;
	
	/**
	 * 特殊函数，用于执行一些static变量的定义等(有这个函数时，static变量预先赋值必须也放到这里面)
	 */
	static function __init__():Void
	{
		NULL_DIR_LIGHT = Vector.ofArray([0.0, -1.0, 0.0, -1.0]);
		NULL_DIR_LIGHT.fixed = true;

		ADDITIVE_LIGHT = new RenderState();
		ADDITIVE_LIGHT.setBlendMode(BlendMode.AlphaAdditive);
		ADDITIVE_LIGHT.setDepthWrite(false);
		
		BLACK_COLOR = new Color(0, 0, 0, 1);
	}
	
	private var ambientLightColor:Color = new Color(0, 0, 0, 1);
	
	private var tmpLightDirection:Array<Float>;
	private var tmpLightPosition:Array<Float>;
	private var tmpLightColor:Array<Float>;
	private var tmpVec:Vector4f;

	public function new(techniqueDef:TechniqueDef) 
	{
		super(techniqueDef);
		
		tmpLightDirection = new Array<Float>(4, true);
		tmpLightPosition = new Array<Float>(4, true);
		tmpLightColor = new Array<Float>(4, true);
		tmpVec = new Vector4f();
	}
	
	override public function render(renderManager:RenderManager, shader:Shader, geometry:Geometry, lights:LightList):Void 
	{
		var r:Stage3DRenderer = renderManager.getRenderer();

		var lightDir:Uniform = shader.getUniform("gu_LightDirection");
		var lightColor:Uniform = shader.getUniform("gu_LightColor");
		var lightPos:Uniform = shader.getUniform("gu_LightPosition");
		var ambientColor:Uniform = shader.getUniform("gu_AmbientLightColor");
		
		var isFirstLight:Bool = true;
		var isSecondLight:Bool = false;
		
		DefaultTechniqueDefLogic.getAmbientColor(lights, false, ambientLightColor);
		
		var viewMatrix:Matrix4f = renderManager.getCurrentCamera().getViewMatrix();
		
		var numLight:Int = lights.getSize();
		for (i in 0...numLight)
		{
			var light:Light = lights.getLightAt(i);
			//TODO 是否需要检查Probe
			if (light.type == LightType.Ambient)
			{
				continue;
			}
			
			if (isFirstLight)
			{
				// set ambient color for first light only
				ambientColor.setColor(ambientLightColor);
				isFirstLight = false;
				isSecondLight = true;
			}
			else if (isSecondLight)
			{
				ambientColor.setColor(BLACK_COLOR);
				// apply additive blending for 2nd and future lights
				r.applyRenderState(ADDITIVE_LIGHT);
				isSecondLight = false;
			}
			
			
			light.color.toVector(tmpLightColor);
			tmpLightColor[3] = light.type.toInt();
			lightColor.setVector(tmpLightColor);
			
			switch(light.type)
			{
				case LightType.Directional:
					var dl:DirectionalLight = cast light;
					var dir:Vector3f = dl.direction;
					
					//FIXME : there is an inconstency here due to backward
                    //compatibility of the lighting shader.
                    //The directional light direction is passed in the
                    //LightPosition uniform. The lighting shader needs to be
                    //reworked though in order to fix this.
					tmpLightPosition[0] = dir.x;
					tmpLightPosition[1] = dir.y;
					tmpLightPosition[2] = dir.z;
					tmpLightPosition[3] = -1;
					lightPos.setVector(tmpLightPosition);
					
					tmpLightDirection[0] = 0;
					tmpLightDirection[1] = 0;
					tmpLightDirection[2] = 0;
					tmpLightDirection[3] = 0;
					lightDir.setVector(tmpLightDirection);
					
				case LightType.Point:
					var pl:PointLight = cast light;
					var pos:Vector3f = pl.position;
					tmpLightPosition[0] = pos.x;
					tmpLightPosition[1] = pos.y;
					tmpLightPosition[2] = pos.z;
					tmpLightPosition[3] = pl.invRadius;
					lightPos.setVector(tmpLightPosition);
					
					tmpLightDirection[0] = 0;
					tmpLightDirection[1] = 0;
					tmpLightDirection[2] = 0;
					tmpLightDirection[3] = 0;
					lightDir.setVector(tmpLightDirection);
					
				case LightType.Spot:
					var sl:SpotLight = cast light;
					var pos:Vector3f = sl.position;
					var dir:Vector3f = sl.direction;
					
					tmpLightPosition[0] = pos.x;
					tmpLightPosition[1] = pos.y;
					tmpLightPosition[2] = pos.z;
					tmpLightPosition[3] = sl.invSpotRange;
					lightPos.setVector(tmpLightPosition);
					
					tmpVec.setTo(dir.x, dir.y, dir.z, 0);
					viewMatrix.multVec4(tmpVec, tmpVec);
					
					//We transform the spot directoin in view space here to save 5 varying later in the lighting shader
                    //one vec4 less and a vec4 that becomes a vec3
                    //the downside is that spotAngleCos decoding happen now in the frag shader.
					tmpLightDirection[0] = tmpVec.x;
					tmpLightDirection[1] = tmpVec.y;
					tmpLightDirection[2] = tmpVec.z;
					tmpLightDirection[3] = sl.packedAngleCos;
					
					lightDir.setVector(tmpLightDirection);
				case LightType.Probe:	
				default:
					Assert.assert(false, "Unknown type of light: " + light.type);
			}
			
			r.setShader(shader);
			DefaultTechniqueDefLogic.renderMeshFromGeometry(r, geometry);
		}
		
		// Either there are no lights at all, or only ambient lights.
		// Render a dummy "normal light" so we can see the ambient color.
		if (isFirstLight)
		{
			ambientColor.setColor(ambientLightColor);
			lightColor.setColor(BLACK_COLOR);
			lightPos.setVector(NULL_DIR_LIGHT);
			
			r.setShader(shader);
			DefaultTechniqueDefLogic.renderMeshFromGeometry(r, geometry);
		}
	}
}