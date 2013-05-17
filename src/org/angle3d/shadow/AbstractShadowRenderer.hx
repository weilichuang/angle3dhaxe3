package org.angle3d.shadow;
import org.angle3d.texture.FrameBuffer;
import org.angle3d.renderer.queue.RenderQueue;
import org.angle3d.renderer.ViewPort;

import org.angle3d.material.post.SceneProcessor;
import org.angle3d.renderer.RenderManager;

/**
 * ...
 * @author 
 */
class AbstractShadowRenderer implements SceneProcessor
{
	public var isInitialized(get, set):Bool;
	

	public function new() 
	{
		
	}
	
	/* INTERFACE org.angle3d.material.post.SceneProcessor */
	
	private function get_isInitialized():Bool 
	{
		return _isInitialized;
	}
	
	private function set_isInitialized(value:Bool):Bool 
	{
		return _isInitialized = value;
	}

	public function initialize(rm:RenderManager, vp:ViewPort):Void 
	{
		
	}
	
	public function reshape(vp:ViewPort, w:Int, h:Int):Void 
	{
		
	}
	
	public function preFrame(tpf:Float):Void 
	{
		
	}
	
	public function postQueue(rq:RenderQueue):Void 
	{
		
	}
	
	public function postFrame(out:FrameBuffer):Void 
	{
		
	}
	
	public function cleanup():Void 
	{
		
	}
	
}