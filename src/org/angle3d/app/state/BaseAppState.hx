package org.angle3d.app.state;
import org.angle3d.renderer.RenderManager;
import org.angle3d.app.LegacyApplication;
import org.angle3d.app.state.AppStateManager;

/**
 *  A base app state implementation the provides more built-in
 *  management convenience than AbstractAppState, including methods
 *  for enable/disable/initialize state management.
 *  The abstract enable() and disable() methods are called
 *  appropriately during initialize(), terminate(), or setEnabled()
 *  depending on the mutual state of "initialized" and "enabled".
 *  
 *  <p>initialize() and terminate() can be used by subclasses to
 *  manage resources that should exist the entire time that the 
 *  app state is attached.  This is useful for resources that might
 *  be expensive to create or load.</p>
 *
 *  <p>enable()/disable() can be used for managing things that
 *  should only exist while the state is enabled.  Prime examples
 *  would be scene graph attachment or input listener attachment.</p>
 *
 *  <p>The base class logic is such that disable() will always be called
 *  before cleanup() if the state is enabled.  Likewise, enable()
 *  will always be called after initialize() if the state is enable().
 *  enable()/disable() are also called appropriate when setEnabled()
 *  is called that changes the enabled state AND if the state is attached.
 *  In other words, enable()/disable() are only ever called on an already 
 *  attached state.</p>
 *
 *  <p>It is technically safe to do all initialization and cleanup in
 *  the enable()/disable() methods.  Choosing to use initialize()
 *  and cleanup() for this is a matter of performance specifics for the
 *  implementor.</p>
 *
 */
class BaseAppState implements AppState
{
	private var app:LegacyApplication;
	private var initialized:Bool;
	private var enabled:Bool = true;

	public function new() 
	{
		
	}
	
	public function isInitialized():Bool 
	{
		return initialized;
	}
	
	public function isEnabled():Bool 
	{
		return enabled;
	}
	
	public function setEnabled(value:Bool):Void 
	{
		if( this.enabled == value )
            return;
			
        this.enabled = value;
		
        if( !isInitialized() )
            return;
			
        if ( enabled ) 
		{
            onEnable();
        }
		else
		{
            onDisable();
        }
	}
	
	private function internalInitialize(app:LegacyApplication):Void
	{
		
	}
	
	private function internalCleanup(app:LegacyApplication):Void
	{
		
	}
	
	/**
     *  Called when the state is fully enabled, ie: is attached
     *  and isEnabled() is true or when the setEnabled() status
     *  changes after the state is attached.
     */
	private function onEnable():Void
	{
		
	}
	
	/**
     *  Called when the state was previously enabled but is
     *  now disabled either because setEnabled(false) was called
     *  or the state is being cleaned up.
     */
	private function onDisable():Void
	{
		
	}
	
	public function initialize(stateManager:AppStateManager, app:LegacyApplication):Void 
	{
		this.app = app;
		initialized = true;
		internalInitialize(app);
		if (enabled)
		{
			onEnable();
		}
	}
	
	public function getApplication():LegacyApplication
	{
		return app;
	}
	
	public function getStateManager():AppStateManager
	{
		return app.getStateManager();
	}
	
	public function getState(type:Class<AppState>):AppState
	{
		return getStateManager().getState(type);
	}
	
	public function stateAttached(stateManager:AppStateManager):Void 
	{
		
	}
	
	public function stateDetached(stateManager:AppStateManager):Void 
	{
		
	}
	
	public function update(tpf:Float):Void 
	{
		
	}
	
	public function render(rm:RenderManager):Void 
	{
		
	}
	
	public function postRender():Void 
	{
		
	}
	
	public function cleanup():Void 
	{
		if ( isEnabled() )
		{
            onDisable();
        }
        internalCleanup(app);
        initialized = false;
	}
	
}