package org.angle3d.scene;


/**
 * Specifies how frustum culling should be handled by 
 
 */
@:enum abstract CullHint(Int)  
{
	/**
	 * Do whatever our parent does. If no parent, we'll default to dynamic.
	 */
	var Inherit = 0;
	/**
	 * Do not draw if we are not at least partially within the view frustum
	 * of the renderer's camera.
	 */
	var Auto = 1;
	/**
	 * Always cull this from view.
	 */
	var Always = 2;
	/**
	 * Never cull this from view. Note that we will still culled if our
	 * parent is culled.
	 */
	var Never = 3;
	
	inline function new(v:Int)
        this = v;

    public inline function toInt():Int
    	return this;

}

