package org.angle3d.scene;


/**
 * CullHint
 * @author andy
 */
enum CullHint
{
	/**
	 * Do whatever our parent does. If no parent, we'll default to dynamic.
	 */
	Inherit;
	/**
	 * Do not draw if we are not at least partially within the view frustum
	 * of the renderer's camera.
	 */
	Auto;
	/**
	 * Always cull this from view.
	 */
	Always;
	/**
	 * Never cull this from view. Note that we will still get_culled if our
	 * parent is culled.
	 */
	Never;

}

