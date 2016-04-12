package org.angle3d.material.logic;

import org.angle3d.light.DirectionalLight;
import org.angle3d.light.LightList;
import org.angle3d.light.LightType;
import org.angle3d.light.PointLight;
import org.angle3d.light.SpotLight;
import org.angle3d.material.TechniqueDef;
import org.angle3d.material.shader.DefineList;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.shader.Uniform;
import org.angle3d.math.Color;
import org.angle3d.math.Vector3f;
import org.angle3d.math.Vector4f;
import org.angle3d.renderer.RenderManager;
import org.angle3d.renderer.RendererBase;
import org.angle3d.scene.Geometry;

/**
 * ...
 * @author weilichuang
 */
class SinglePassLightingLogic extends DefaultTechniqueDefLogic
{

	private static var ADDITIVE_LIGHT:RenderState;
	
	/**
	 * 特殊函数，用于执行一些static变量的定义等(有这个函数时，static变量预先赋值必须也放到这里面)
	 */
	static function __init__():Void
	{
		ADDITIVE_LIGHT = new RenderState();
		ADDITIVE_LIGHT.setBlendMode(BlendMode.AlphaAdditive);
		ADDITIVE_LIGHT.setDepthWrite(false);
	}
	
	
	private var ambientLightColor:Color = new Color(0, 0, 0, 1);
	
	public function new(techniqueDef:TechniqueDef) 
	{
		super(techniqueDef);
		
	}
	
	override public function makeCurrent(renderManager:RenderManager, rendererCaps:Array<Caps>, lights:LightList, defines:DefineList):Shader 
	{
		return techniqueDef.getShader(rendererCaps, defines);
	}
	
	/**
     * Uploads the lights in the light list as two uniform arrays.<br/><br/> *
     * <p>
     * `uniform vec4 g_LightColor[numLights];`<br/> //
     * g_LightColor.rgb is the diffuse/specular color of the light.<br/> //
     * g_Lightcolor.a is the type of light, 0 = Directional, 1 = Point, <br/> //
     * 2 = Spot. <br/> <br/>
     * `uniform vec4 g_LightPosition[numLights];`<br/> //
     * g_LightPosition.xyz is the position of the light (for point lights)<br/>
     * // or the direction of the light (for directional lights).<br/> //
     * g_LightPosition.w is the inverse radius (1/r) of the light (for
     * attenuation) <br/> </p>
     */
    private function updateLightListUniforms(shader:Shader, g:Geometry, lightList:LightList, numLights:Int, rm:RenderManager, startIndex:Int):Int
	{
		// this shader does not do lighting, ignore.
        if (numLights == 0) 
		{ 
            return 0;
        }

        var lightData:Uniform = shader.getUniform("gu_LightData");     
        lightData.setVector4Length(numLights * 3);//4 lights * max 3        
        var ambientColorUniform:Uniform = shader.getUniform("gu_AmbientLightColor");
        
        if (startIndex != 0)
		{        
            // apply additive blending for 2nd and future passes
            rm.getRenderer().applyRenderState(additiveLight);
            ambientColorUniform.setColor(Color.Black());            
        }
		else
		{
            ambientColorUniform.setColor(getAmbientColor(lightList,true,ambientLightColor));
        }
        
        var lightDataIndex:Int = 0;
        var tmpVec:Vector4f = new Vector4f();
        var curIndex:Int = startIndex;
        var endIndex:Int = numLights + startIndex;
        while (curIndex < endIndex && curIndex < lightList.getSize())
		{    
			var l:Light = lightList.getLightAt(curIndex);              
			if (l.type == LightType.Ambient)
			{
				endIndex++;   
				curIndex++;
				continue;
			}
			
			var color:Color = l.color;
			//Color
			lightData.setVector4InArray(color.r, color.g, color.b, l.type.toInt(), lightDataIndex);
			lightDataIndex++;
			
			switch (l.type)
			{
				case LightType.Directional:
					var dl:DirectionalLight = cast l;
					var dir:Vector3f = dl.direction;                      
					//Data directly sent in view space to avoid a matrix mult for each pixel
					tmpVec.setTo(dir.x, dir.y, dir.z, 0.0);
					rm.getCurrentCamera().getViewMatrix().multVec4(tmpVec, tmpVec);      
//                        tmpVec.divideLocal(tmpVec.w);
//                        tmpVec.normalizeLocal();
					lightData.setVector4InArray(tmpVec.x, tmpVec.y, tmpVec.z, -1, lightDataIndex);
					lightDataIndex++;
					//PADDING
					lightData.setVector4InArray(0, 0, 0, 0, lightDataIndex);
					lightDataIndex++;
					
				case LightType.Point:
					var pl:PointLight = cast l;
					var pos:Vector3f = pl.position;
					var invRadius:Float = pl.invRadius;
					tmpVec.setTo(pos.x, pos.y, pos.z, 1.0);
					rm.getCurrentCamera().getViewMatrix().multVec4(tmpVec, tmpVec);    
					//tmpVec.divideLocal(tmpVec.w);
					lightData.setVector4InArray(tmpVec.x, tmpVec.y, tmpVec.z, invRadius, lightDataIndex);
					lightDataIndex++;
					//PADDING
					lightData.setVector4InArray(0, 0, 0, 0, lightDataIndex);
					lightDataIndex++;
					
				case LightType.Spot:                      
					var sl:SpotLight = cast l;
					var pos2:Vector3f = sl.position;
					var dir2:Vector3f = sl.direction;
					var invRange:Float = sl.invSpotRange;
					var spotAngleCos:Float = sl.packedAngleCos;
					tmpVec.setTo(pos2.x, pos2.y, pos2.z,  1.0);
					rm.getCurrentCamera().getViewMatrix().multVec4(tmpVec, tmpVec);   
				   // tmpVec.divideLocal(tmpVec.w);
					lightData.setVector4InArray(tmpVec.x, tmpVec.y, tmpVec.z, invRange, lightDataIndex);
					lightDataIndex++;
					
					//We transform the spot direction in view space here to save 5 varying later in the lighting shader
					//one vec4 less and a vec4 that becomes a vec3
					//the downside is that spotAngleCos decoding happens now in the frag shader.
					tmpVec.setTo(dir2.x, dir2.y, dir2.z,  0.0);
					rm.getCurrentCamera().getViewMatrix().multVec4(tmpVec, tmpVec);                           
					tmpVec.normalize();
					lightData.setVector4InArray(tmpVec.x, tmpVec.y, tmpVec.z, spotAngleCos, lightDataIndex);
					lightDataIndex++;                  
				default:
					throw ("Unknown type of light: " + l.type);
			}
			curIndex++;
        }
      
        //Padding of unsued buffer space
        while (lightDataIndex < numLights * 3)
		{
            lightData.setVector4InArray(0, 0, 0, 0, lightDataIndex);
            lightDataIndex++;             
        } 
        return curIndex;
    }
	
	
	override public function render(renderManager:RenderManager, shader:Shader, geometry:Geometry, lights:LightList):Void 
	{
		var renderer:RendererBase = renderManager.getRenderer();

		var nbRenderedLights:Int = 0;
		if (lights.getSize() == 0)
		{
			nbRenderedLights = updateLightListUniforms(shader, geom, lights, rm.getSinglePassLightBatchSize(), rm, 0);
			renderer.setShader(shader);
			renderMeshFromGeometry(renderer, geom);
		} 
		else
		{
			//如果灯光数量超过上限，则会分成多次渲染
			while (nbRenderedLights < lights.getSize())
			{
				nbRenderedLights = updateLightListUniforms(shader, geom, lights, rm.getSinglePassLightBatchSize(), rm, nbRenderedLights);
				renderer.setShader(shader);
				renderMeshFromGeometry(renderer, geom);
			}
		}
	}
}