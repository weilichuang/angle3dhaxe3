package org.angle3d.material.logic;
import org.angle3d.light.AmbientLight;
import org.angle3d.light.Light;
import org.angle3d.light.LightList;
import org.angle3d.material.TechniqueDef;
import org.angle3d.material.shader.DefineList;
import org.angle3d.material.shader.Shader;
import org.angle3d.math.Color;
import org.angle3d.renderer.Caps;
import org.angle3d.renderer.RenderManager;
import org.angle3d.renderer.Stage3DRenderer;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.mesh.Mesh;

class DefaultTechniqueDefLogic implements TechniqueDefLogic
{
	private var techniqueDef:TechniqueDef;

	public function new(techniqueDef:TechniqueDef) 
	{
		this.techniqueDef = techniqueDef;
	}
	
	public function makeCurrent(renderManager:RenderManager, rendererCaps:Array<Caps>, lights:LightList, defines:DefineList):Shader 
	{
		return techniqueDef.getShader(defines,rendererCaps);
	}
	
	public function render(renderManager:RenderManager, shader:Shader, geometry:Geometry, lights:LightList, lastTexUnit:Int):Void 
	{
		var renderer:Stage3DRenderer = renderManager.getRenderer();
        renderer.setShader(shader);
        renderMeshFromGeometry(renderer, geometry);
	}
	
	public static inline function renderMeshFromGeometry(renderer:Stage3DRenderer, geom:Geometry):Void
	{
        var mesh:Mesh = geom.getMesh();
        var lodLevel:Int = geom.getLodLevel();
		renderer.renderMesh(mesh, lodLevel);
    }

    public static function getAmbientColor(lightList:LightList, removeLights:Bool, ambientLightColor:Color):Color
	{
        ambientLightColor.setTo(0, 0, 0, 1);
		
        for (j in 0...lightList.getSize())
		{
            var light:Light = lightList.getLightAt(j);
            if (Std.is(light, AmbientLight))
			{
                ambientLightColor.addLocal(light.color);
                if (removeLights)
				{
                    lightList.removeLight(light);
                }
            }
        }
        ambientLightColor.a = 1.0;
        return ambientLightColor;
    }
	
}