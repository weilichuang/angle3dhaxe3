package org.angle3d.renderer.queue;

import org.angle3d.renderer.Camera;
import org.angle3d.scene.Geometry;


/**
 * `GeometryComparator` is a special version of {Comparator}
 * that is used to sort geometries for rendering in the {RenderQueue}.
 *
 * 
 */
interface GeometryComparator
{
	/**
	 * set_the camera to use for sorting.
	 *
	 * @param cam The camera to use for sorting
	 */
	function setCamera(cam:Camera):Void;

	function compare(o1:Geometry, o2:Geometry):Int;

}

