package org.angle3d.terrain.geomipmap ;
import org.angle3d.scene.Spatial;

import org.angle3d.scene.control.AbstractControl;
import org.angle3d.scene.control.Control;
import org.angle3d.terrain.Terrain;

/**
 * Handles the normal vector updates when the terrain changes heights.
 */
class NormalRecalcControl extends AbstractControl
{
	private var terrain:TerrainQuad;

	public function new(terrain:TerrainQuad) 
	{
		super();
		this.terrain = terrain;
	}
	
	override function controlUpdate(tpf:Float):Void 
	{
		terrain.updateNormals();
	}
	
	public function setTerrain(terrain:TerrainQuad):Void
	{
		this.terrain = terrain;
	}
	
	public function getTerrain():TerrainQuad
	{
		return this.terrain;
	}
	
	override public function cloneForSpatial(newSpatial:Spatial):Control 
	{
		var control:NormalRecalcControl = new NormalRecalcControl(terrain);
        control.setSpatial(spatial);
        control.setEnabled(true);
        return control;
	}
	
	override public function setSpatial(value:Spatial):Void 
	{
		super.setSpatial(value);
		if (Std.is(value,TerrainQuad))
            this.terrain = cast spatial;
	}
}