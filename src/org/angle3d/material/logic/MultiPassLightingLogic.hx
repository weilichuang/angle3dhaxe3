package org.angle3d.material.logic;

import de.polygonal.ds.error.Assert;
import flash.Vector;
import org.angle3d.light.DirectionalLight;
import org.angle3d.light.LightList;
import org.angle3d.light.PointLight;
import org.angle3d.light.SpotLight;
import org.angle3d.material.TechniqueDef;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.shader.Uniform;
import org.angle3d.math.Color;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.RenderManager;
import org.angle3d.renderer.RendererBase;
import org.angle3d.scene.Geometry;

/**
 * ...
 * @author weilichuang
 */
class MultiPassLightingLogic extends DefaultTechniqueDefLogic
{
	private static var ADDITIVE_LIGHT:RenderState;
	
	private static var NULL_DIR_LIGHT:Vector<Float>;
	
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
	}
	
	private var ambientLightColor:Color = new Color(0, 0, 0, 1);

	public function new(techniqueDef:TechniqueDef) 
	{
		super(techniqueDef);
		
	}
	
	
	/**
	 * 多重灯光渲染
	 * @param	shader
	 * @param	g
	 * @param	rm
	 */
	private var tmpLightDirection:Vector<Float>;
	private var tmpLightPosition:Vector<Float>;
	private var tmpColors:Vector<Float>;
	override public function render(renderManager:RenderManager, shader:Shader, geometry:Geometry, lights:LightList):Void 
	{
		var r:RendererBase = rm.getRenderer();

		var lightDir:Uniform = shader.getUniform("gu_LightDirection");
		var lightColor:Uniform = shader.getUniform("gu_LightColor");
		var lightPos:Uniform = shader.getUniform("gu_LightPosition");
		var ambientColor:Uniform = shader.getUniform("gu_AmbientLightColor");
		
		var isFirstLight:Bool = true;
		var isSecondLight:Bool = false;
		
		getAmbientColor(lightList, false, ambientLightColor);
		
		var numLight:Int = lightList.getSize();
		for (i in 0...numLight)
		{
			var l:Light = lightList.getLightAt(i);
			if (l.type == LightType.Ambient)
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
				ambientColor.setColor(Color.Black());
				// apply additive blending for 2nd and future lights
				r.applyRenderState(ADDITIVE_LIGHT);
				isSecondLight = false;
			}
			
			if(tmpLightDirection == null)
				tmpLightDirection = new Vector<Float>(4, true);
			if(tmpLightPosition == null)
			    tmpLightPosition = new Vector<Float>(4, true);
			if (tmpColors == null)
				tmpColors = new Vector<Float>(4, true);

			l.color.toVector(tmpColors);
			tmpColors[3] = l.type.toInt();
			lightColor.setVector(tmpColors);
			
			switch(l.type)
			{
				case LightType.Directional:
					var dl:DirectionalLight = cast l;
					var dir:Vector3f = dl.direction;
					
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
					var pl:PointLight = cast l;
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
					var sl:SpotLight = cast l;
					var pos:Vector3f = sl.position;
					var dir:Vector3f = sl.direction;
					
					tmpLightPosition[0] = pos.x;
					tmpLightPosition[1] = pos.y;
					tmpLightPosition[2] = pos.z;
					tmpLightPosition[3] = sl.invSpotRange;
					lightPos.setVector(tmpLightPosition);
					
					var tmpVec:Vector4f = new Vector4f();
					tmpVec.setTo(dir.x, dir.y, dir.z, 0);
					
					rm.getCurrentCamera().getViewMatrix().multVec4(tmpVec, tmpVec);
					
					//We transform the spot directoin in view space here to save 5 varying later in the lighting shader
                    //one vec4 less and a vec4 that becomes a vec3
                    //the downside is that spotAngleCos decoding happen now in the frag shader.
					tmpLightDirection[0] = tmpVec.x;
					tmpLightDirection[1] = tmpVec.y;
					tmpLightDirection[2] = tmpVec.z;
					tmpLightDirection[3] = sl.packedAngleCos;
					
					lightDir.setVector(tmpLightDirection);
					
				default:
					Assert.assert(false, "Unknown type of light: " + l.type);
			}
			
			r.setShader(shader);
			renderMeshFromGeometry(r, g);
		}
		
		if (isFirstLight)
		{
			// Either there are no lights at all, or only ambient lights.
            // Render a dummy "normal light" so we can see the ambient color.
			ambientColor.setVector(getAmbientColor(lightList,false,ambientLightColor).toVector());
			lightColor.setVector(Color.BlackNoAlpha().toVector());
			lightPos.setVector(nullDirLight);
			
			r.setShader(shader);
			renderMeshFromGeometry(r, g);
		}
	}
}