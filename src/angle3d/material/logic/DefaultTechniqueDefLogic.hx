package angle3d.material.logic;

import angle3d.light.AmbientLight;
import angle3d.light.Light;
import angle3d.light.LightList;
import angle3d.material.TechniqueDef;
import angle3d.shader.DefineList;
import angle3d.shader.Shader;
import angle3d.math.Color;
import angle3d.renderer.Caps;
import angle3d.renderer.RenderManager;
import angle3d.renderer.Renderer;
import angle3d.scene.Geometry;
import angle3d.scene.mesh.Mesh;

class DefaultTechniqueDefLogic implements TechniqueDefLogic {
	private var techniqueDef:TechniqueDef;

	public function new(techniqueDef:TechniqueDef) {
		this.techniqueDef = techniqueDef;
	}

	public function makeCurrent(renderManager:RenderManager, material:Material, rendererCaps:Array<Caps>, lights:LightList, defines:DefineList):Shader {
		return techniqueDef.getShader(material, defines, rendererCaps);
	}

	public function render(renderManager:RenderManager, shader:Shader, geometry:Geometry, lights:LightList):Void {
		var renderer:Renderer = renderManager.getRenderer();
		renderer.setShader(shader);
		renderMeshFromGeometry(renderer, geometry);
	}

	public static inline function renderMeshFromGeometry(renderer:Renderer, geom:Geometry):Void {
		var mesh:Mesh = geom.getMesh();
		var lodLevel:Int = geom.getLodLevel();
		renderer.renderMesh(mesh, lodLevel);
	}

	public static function getAmbientColor(lightList:LightList, removeLights:Bool, ambientLightColor:Color):Color {
		ambientLightColor.setTo(0, 0, 0, 1);

		var size:Int = lightList.getSize();
		var j:Int = 0;
		while (j < size) {
			var light:Light = lightList.getLightAt(j);
			if (Std.is(light, AmbientLight)) {
				ambientLightColor.addLocal(light.color);
				if (removeLights) {
					lightList.removeLight(light);
					j--;
					size--;
				}
			}
			j++;
		}
		ambientLightColor.a = 1.0;
		return ambientLightColor;
	}

	public static function calcAmbientColor(lightList:LightList, newLights:Array<Light>, ambientLightColor:Color):Color {
		ambientLightColor.setTo(0, 0, 0, 1);

		var size:Int = lightList.getSize();
		var j:Int = 0;
		while (j < size) {
			var light:Light = lightList.getLightAt(j);
			if (Std.is(light, AmbientLight)) {
				ambientLightColor.addLocal(light.color);
			} else {
				newLights[newLights.length] = light;
			}
			j++;
		}
		ambientLightColor.a = 1.0;
		return ambientLightColor;
	}
}