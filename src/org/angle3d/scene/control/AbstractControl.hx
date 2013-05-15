package org.angle3d.scene.control;

import org.angle3d.renderer.RenderManager;
import org.angle3d.renderer.ViewPort;
import org.angle3d.scene.Spatial;
import org.angle3d.utils.Assert;

/**
 * An abstract implementation of the Control interface.
 *
 * @author Kirill Vainer
 */

class AbstractControl implements Control
{
	public var spatial(get, set):Spatial;
	public var enabled(get,set):Bool;
	
	private var _enabled:Bool;
	private var _spatial:Spatial;

	public function new()
	{
		_enabled = true;
	}

	
	private function set_spatial(value:Spatial):Spatial
	{
		#if debug
		if (_spatial != null && value != null)
		{
			Assert.assert(false,"This control has already been added to a Spatial");
		}
		#end

		return _spatial = value;
	}

	private function get_spatial():Spatial
	{
		return _spatial;
	}

	
	private function set_enabled(value:Bool):Bool
	{
		return _enabled = value;
	}

	private function get_enabled():Bool
	{
		return _enabled;
	}

	public function update(tpf:Float):Void
	{
		if (!enabled)
			return;

		controlUpdate(tpf);
	}

	/**
	 * To be implemented in subclass.
	 */
	private function controlUpdate(tpf:Float):Void
	{

	}

	public function render(rm:RenderManager, vp:ViewPort):Void
	{
		if (!enabled)
			return;

		controlRender(rm, vp);
	}

	/**
	 * To be implemented in subclass.
	 */
	private function controlRender(rm:RenderManager, vp:ViewPort):Void
	{

	}

	/**
	 *  Default implementation of cloneForSpatial() that
	 *  simply clones the control and sets the spatial.
	 *  <pre>
	 *  AbstractControl c = clone();
	 *  c.spatial = null;
	 *  c.setSpatial(spatial);
	 *  </pre>
	 *
	 *  Controls that wish to be persisted must be Cloneable.
	 */
	public function cloneForSpatial(newSpatial:Spatial):Control
	{
		var c:Control = clone();
		c.spatial = null;
		return c;
	}

	public function clone():Control
	{
		return new AbstractControl();
	}
}

