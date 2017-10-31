package org.angle3d.material.logic;
import org.angle3d.light.Light;
import org.angle3d.light.LightType;
import org.angle3d.material.shader.DefineList;
import org.angle3d.light.LightList;
import org.angle3d.material.shader.Uniform;
import org.angle3d.math.Matrix4f;
import org.angle3d.renderer.Caps;
import org.angle3d.renderer.RenderManager;
import org.angle3d.renderer.Stage3DRenderer;
import org.angle3d.scene.Geometry;

import org.angle3d.material.TechniqueDef;
import org.angle3d.material.shader.Shader;
import org.angle3d.math.Color;
import org.angle3d.math.Vector3f;

import org.angle3d.light.DirectionalLight;
import org.angle3d.light.PointLight;
import org.angle3d.light.SpotLight;



/**
 * Rendering logic for static pass.
 *
 */
class StaticPassLightingLogic extends DefaultTechniqueDefLogic
{
	
	private static inline var DEFINE_NUM_DIR_LIGHTS:String = "NUM_DIR_LIGHTS";
    private static inline var DEFINE_NUM_POINT_LIGHTS:String = "NUM_POINT_LIGHTS";
    private static inline var DEFINE_NUM_SPOT_LIGHTS:String = "NUM_SPOT_LIGHTS";

    private var numDirLightsDefineId:Int;
    private var numPointLightsDefineId:Int;
    private var numSpotLightsDefineId:Int;

    private var tempDirLights:Vector<DirectionalLight> = new Vector<DirectionalLight>();
    private var tempPointLights:Vector<PointLight> = new Vector<PointLight>();
    private var tempSpotLights:Vector<SpotLight> = new Vector<SpotLight>();

    private var ambientLightColor:Color = new Color(0, 0, 0, 1);
    private var tempPosition:Vector3f = new Vector3f();
    private var tempDirection:Vector3f = new Vector3f();

    public function new(techniqueDef:TechniqueDef) 
	{
        super(techniqueDef);

        numDirLightsDefineId = techniqueDef.addShaderUnmappedDefine(DEFINE_NUM_DIR_LIGHTS, VarType.INT);
        numPointLightsDefineId = techniqueDef.addShaderUnmappedDefine(DEFINE_NUM_POINT_LIGHTS, VarType.INT);
        numSpotLightsDefineId = techniqueDef.addShaderUnmappedDefine(DEFINE_NUM_SPOT_LIGHTS, VarType.INT);
    }
	
	override public function makeCurrent(renderManager:RenderManager, material:Material, rendererCaps:Array<Caps>, lights:LightList, defines:DefineList):Shader 
	{
        // TODO: if it ever changes that render isn't called
        // right away with the same geometry after makeCurrent, it would be
        // a problem.
        // Do a radix sort.
        tempDirLights.length = 0;
        tempPointLights.length = 0;
        tempSpotLights.length = 0;
		
        var numLight:Int = lights.getSize();
		for (i in 0...numLight)
		{
			var light:Light = lights.getLightAt(i);

            switch (light.type)
			{
                case LightType.Directional:
                    tempDirLights.push(cast light);
                case LightType.Point:
                    tempPointLights.push(cast light);
                case LightType.Spot:
                    tempSpotLights.push(cast light);
				default:
            }
        }

        defines.set(numDirLightsDefineId, tempDirLights.length);
        defines.set(numPointLightsDefineId, tempPointLights.length);
        defines.set(numSpotLightsDefineId, tempSpotLights.length);

        return techniqueDef.getShader(material, defines, rendererCaps);
    }

    private function transformDirection(viewMatrix:Matrix4f, direction:Vector3f):Void
	{
        viewMatrix.multNormal(direction, direction);
    }

    private function transformPosition(viewMatrix:Matrix4f, location:Vector3f):Void
	{
        viewMatrix.multVec(location, location);
    }

    private function updateLightListUniforms(viewMatrix:Matrix4f,  shader:Shader,  lights:LightList):Void
	{
        var ambientColor:Uniform = shader.getUniform("gu_AmbientLightColor");
        ambientColor.setColor(DefaultTechniqueDefLogic.getAmbientColor(lights, true, ambientLightColor));

        var lightData:Uniform = shader.getUniform("gu_LightData");

        var totalSize:Int = tempDirLights.length* 2
                + tempPointLights.length * 2
                + tempSpotLights.length * 3;
        lightData.setVector4Length(totalSize);

        var index:Int = 0;
        for ( light in tempDirLights)
		{
            var color:Color = light.color;
            tempDirection.copyFrom(light.direction);
            transformDirection(viewMatrix, tempDirection);
            lightData.setVector4InArray(color.r, color.g, color.b, 1, index++);
            lightData.setVector4InArray(tempDirection.x, tempDirection.y, tempDirection.z, 1, index++);
        }

        for (light in tempPointLights) 
		{
            var color:Color = light.color;
            tempPosition.copyFrom(light.position);
            var invRadius:Float = light.invRadius;
            transformPosition(viewMatrix, tempPosition);
            lightData.setVector4InArray(color.r, color.g, color.b, 1, index++);
            lightData.setVector4InArray(tempPosition.x, tempPosition.y, tempPosition.z, invRadius, index++);
        }

        for ( light in tempSpotLights) 
		{
            var color:Color = light.color;
            var pos:Vector3f = light.position;
            var dir:Vector3f = light.direction;

            tempPosition.copyFrom(light.position);
            tempDirection.copyFrom(light.direction);
            transformPosition(viewMatrix, tempPosition);
            transformDirection(viewMatrix, tempDirection);

            var invRange:Float = light.invSpotRange;
            var spotAngleCos:Float = light.packedAngleCos;
            lightData.setVector4InArray(color.r, color.g, color.b, 1, index++);
            lightData.setVector4InArray(tempPosition.x, tempPosition.y, tempPosition.z, invRange, index++);
            lightData.setVector4InArray(tempDirection.x, tempDirection.y, tempDirection.z, spotAngleCos, index++);
        }
    }
	
	override public function render(renderManager:RenderManager, shader:Shader, geometry:Geometry, lights:LightList):Void 
	{
		var renderer:Stage3DRenderer = renderManager.getRenderer();
        var viewMatrix:Matrix4f = renderManager.getCurrentCamera().getViewMatrix();
        updateLightListUniforms(viewMatrix, shader, lights);
        renderer.setShader(shader);
        DefaultTechniqueDefLogic.renderMeshFromGeometry(renderer, geometry);
	}
}