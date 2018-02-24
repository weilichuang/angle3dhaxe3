package angle3d.scene.control;

import angle3d.renderer.RenderManager;
import angle3d.renderer.ViewPort;
import angle3d.scene.Spatial;

/**
 * An interface for scene-graph controls.
 * <p>
 * `Control`s are used to specify certain update and render logic
 * for a {Spatial}.
 *
 *
 */
interface Control {

	/**
	 * Creates a clone of the Control, the given Spatial is the cloned
	 * version of the spatial to which this control is attached to.
	 * @param spatial
	 * @return
	 */
	function cloneForSpatial(spatial:Spatial):Control;

	/**
	 * @param spatial the spatial to be controlled. This should not be called
	 * from user code.
	 */
	function setSpatial(spatial:Spatial):Void;

	/**
	 * @param enabled Enable or disable the control. If disabled, update()
	 * should do nothing.
	 */
	function isEnabled():Bool;

	function setEnabled(value:Bool):Void;

	/**
	 * Updates the control. This should not be called from user code.
	 * @param tpf Time per frame.
	 */
	function update(tpf:Float):Void;

	/**
	 * Should be called prior to queuing the spatial by the RenderManager. This
	 * should not be called from user code.
	 *
	 * @param rm
	 * @param vp
	 */
	function render(rm:RenderManager, vp:ViewPort):Void;

	function dispose():Void;
}

