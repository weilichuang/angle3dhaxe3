package angle3d.material;

/**
 * <code>FaceCullMode</code> specifies the criteria for faces to be culled.
 *
 * @see RenderState#setFaceCullMode(com.jme3.material.RenderState.FaceCullMode)
 */
@:enum abstract FaceCullMode(Int) {
	/**
	 * Face culling is disabled.
	 */
	var Off = 0;
	/**
	 * Cull front faces
	 */
	var Front = 1;
	/**
	 * Cull back faces
	 */
	var Back = 2;
	/**
	 * Cull both front and back faces.
	 */
	var FrontAndBack = 3;
}