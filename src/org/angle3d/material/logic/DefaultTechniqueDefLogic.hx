package org.angle3d.material.logic;
import org.angle3d.light.AmbientLight;
import org.angle3d.light.Light;
import org.angle3d.material.TechniqueDef;
import org.angle3d.math.Color;
import org.angle3d.renderer.RendererBase;
import org.angle3d.scene.Geometry;
import org.angle3d.material.shader.DefineList;
import org.angle3d.light.LightList;
import org.angle3d.renderer.Caps;
import org.angle3d.renderer.RenderManager;
import org.angle3d.material.shader.Shader;
import org.angle3d.scene.mesh.Mesh;

/**
 * ...
 * @author weilichuang
 */
class DefaultTechniqueDefLogic implements TechniqueDefLogic
{
	private var techniqueDef:TechniqueDef;

	public function new(techniqueDef:TechniqueDef) 
	{
		this.techniqueDef = techniqueDef;
	}
	
	/* INTERFACE org.angle3d.material.logic.TechniqueDefLogic */
	
	public function makeCurrent(renderManager:RenderManager, rendererCaps:Array<Caps>, lights:LightList, defines:DefineList):Shader 
	{
		return techniqueDef.getShader(rendererCaps, defines);
	}
	
	public function render(renderManager:RenderManager, shader:Shader, geometry:Geometry, lights:LightList):Void 
	{
		var renderer:RendererBase = renderManager.getRenderer();
        renderer.setShader(shader);
        renderMeshFromGeometry(renderer, geometry);
	}
	
	
	public static function renderMeshFromGeometry(renderer:RendererBase, geom:Geometry):Void
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
            var l:Light = lightList.get(j);
            if (Std.is(l, AmbientLight))
			{
                ambientLightColor.addLocal(l.color);
                if (removeLights)
				{
                    lightList.removeLight(l);
                }
            }
        }
        ambientLightColor.a = 1.0;
        return ambientLightColor;
    }
	
}