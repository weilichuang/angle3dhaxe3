package org.angle3d.post.filter;
import org.angle3d.material.Material;
import org.angle3d.renderer.ViewPort;
import org.angle3d.post.Filter;
import org.angle3d.renderer.RenderManager;

/**
 *
 * Fade Filter allows you to make an animated fade effect on a scene.
 */
class FadeFilter extends Filter
{
	private var fadeValue:Float = 1.0;
	private var playing:Bool = false;
	public var direction:Float = 1;
	public var duration:Float = 1;

	public function new(duration:Float) 
	{
		super("Fade In/Out");
		this.duration = duration;
	}
	
	override public function getMaterial():Material 
	{
		return material;
	}
	
	override function initFilter(renderManager:RenderManager, vp:ViewPort, w:Int, h:Int):Void 
	{
		super.initFilter(renderManager, vp, w, h);
		
		material = new Material();
		material.load(Angle3D.materialFolder + "material/fade.mat");
		material.setFloat("u_FadeValue", fadeValue);
	}
	
	override public function preFrame(tpf:Float):Void 
	{
		super.preFrame(tpf);
		
		if (playing)
		{
			fadeValue += tpf * direction / duration;
			
			if (direction > 0 && fadeValue > 1)
			{
				fadeValue = 1;
				playing = false;
			}
			
			if (direction < 0 && fadeValue < 0)
			{
				fadeValue = 0;
				playing = false;
			}
			
			material.setFloat("u_FadeValue", fadeValue);
		}
	}
	
	public function setFadeValue(value:Float):Void
	{
		this.fadeValue = value;
		if (material != null)
			material.setFloat("u_FadeValue", fadeValue);
	}
	
	public function fadeIn():Void
	{
		setEnabled(true);
		direction = 1;
		playing = true;
	}
	
	public function fadeOut():Void
	{
		setEnabled(true);
		direction = -1;
		playing = true;
	}
	
	public function pause():Void
	{
		playing = false;
	}
}