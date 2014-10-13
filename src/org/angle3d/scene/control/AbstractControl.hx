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
	private var _enabled:Bool;
	private var _spatial:Spatial;

	public function new()
	{
		_enabled = true;
	}

	
	public function setSpatial(value:Spatial):Void
	{
		#if debug
		if (_spatial != null && value != null)
		{
			Assert.assert(false,"This control has already been added to a Spatial");
		}
		#end

		_spatial = value;
	}

	public function getSpatial():Spatial
	{
		return _spatial;
	}

	
	public function setEnabled(value:Bool):Void
	{
		_enabled = value;
	}

	public function isEnabled():Bool
	{
		return _enabled;
	}

	public function update(tpf:Float):Void
	{
		if (!isEnabled())
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
		if (!isEnabled())
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
		var c:Control = new AbstractControl();
		c.setSpatial(newSpatial);
		return c;
	}

	public function clone():Control
	{
		return new AbstractControl();
	}
}

