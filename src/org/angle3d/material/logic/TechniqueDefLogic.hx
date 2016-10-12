package org.angle3d.material.logic;
import org.angle3d.light.LightList;
import org.angle3d.material.shader.DefineList;
import org.angle3d.material.shader.Shader;
import org.angle3d.renderer.Caps;
import org.angle3d.renderer.RenderManager;
import org.angle3d.scene.Geometry;

/**
 * `TechniqueDefLogic` is used to customize how 
 * a material should be rendered.
 * 
 * Typically used to implement lighting modes.
 * Implementations can register 
 * {@link TechniqueDef#addShaderUnmappedDefine(java.lang.String) unmapped defines} 
 * in their constructor and then later set them based on the geometry 
 * or light environment being rendered.
 * 
 */
interface TechniqueDefLogic 
{
  /**
     * Determine the shader to use for the given geometry / material combination.
     * 
     * @param assetManager The asset manager to use for loading shader source code,
     * shader nodes, and and lookup textures.
     * @param renderManager The render manager for which rendering is to be performed.
     * @param rendererCaps Renderer capabilities. The returned shader must
     * support these capabilities.
     * @param lights The lights with which the geometry shall be rendered. This
     * list must not include culled lights.
     * @param defines The define list used by the technique, any 
     * {@link TechniqueDef#addShaderUnmappedDefine(java.lang.String) unmapped defines}
     * should be set here to change shader behavior.
     * 
     * @return The shader to use for rendering.
     */
	function makeCurrent(renderManager:RenderManager, material:Material, 
						rendererCaps:Array<Caps>, 
						lights:LightList, defines:DefineList):Shader;
    
    /**
     * Requests that the <code>TechniqueDefLogic</code> renders the given geometry.
     * 
     * Fixed material functionality such as {@link RenderState}, 
     * {@link MatParam material parameters}, and 
     * {@link UniformBinding uniform bindings}
     * have already been applied by the material, however, 
     * {@link RenderState}, {@link Uniform uniforms}, {@link Texture textures},
     * can still be overriden.
     * 
     * @param renderManager The render manager to perform the rendering against.
     * * @param shader The shader that was selected by this logic in 
     * {@link #makeCurrent(com.jme3.asset.AssetManager, com.jme3.renderer.RenderManager, java.util.EnumSet, com.jme3.shader.DefineList)}.
     * @param geometry The geometry to render
     * @param lights Lights which influence the geometry.
     */
    function render(renderManager:RenderManager, shader:Shader, geometry:Geometry, lights:LightList, lastTexUnit:Int):Void;
}