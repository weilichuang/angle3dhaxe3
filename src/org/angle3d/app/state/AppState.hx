package org.angle3d.app.state;

import org.angle3d.app.Application;
import org.angle3d.renderer.RenderManager;

/**
 * AppState represents a continously executing code inside the main loop.
 * An <code>AppState</code> can track when it is attached to the
 * {@link AppStateManager} or when it is detached. <br/><code>AppState</code>s
 * are initialized in the render thread, upon a call to {@link AppState#initialize(org.angle3d.app.state.AppStateManager, org.angle3d.app.Application) }
 * and are de-initialized upon a call to {@link AppState#cleanup()}.
 * Implementations should return the correct value with a call to
 * {@link AppState#isInitialized() } as specified above.<br/>
 *
 *
 */
interface AppState
{
	/**
	 * Called to initialize the AppState.
	 *
	 * @param stateManager The state manager
	 * @param app
	 */
	function initialize(stateManager:AppStateManager, app:Application):Void;

	/**
	 * @return True if <code>initialize()</code> was called on the state,
	 * false otherwise.
	 */
	var isInitialized(get,null):Bool;

	/**
	 * Enable or disable the functionality of the <code>AppState</code>.
	 * The effect of this call depends on implementation. An
	 * <code>AppState</code> starts as being enabled by default.
	 *
	 * @param value active the AppState or not.
	 */
	var enabled(get, set):Bool;
	
	/**
	 * Called when the state was attached.
	 *
	 * @param stateManager State manager to which the state was attached to.
	 */
	function stateAttached(stateManager:AppStateManager):Void;

	/**
	 * Called when the state was detached.
	 *
	 * @param stateManager The state manager from which the state was detached from.
	 */
	function stateDetached(stateManager:AppStateManager):Void;

	/**
	 * Called to update the state.
	 *
	 * @param tpf Time per frame.
	 */
	function update(tpf:Float):Void;

	/**
	 * Render the state.
	 *
	 * @param rm RenderManager
	 */
	function render(rm:RenderManager):Void;

	/**
	 * Called after all rendering commands are flushed.
	 */
	function postRender():Void;

	/**
	 * Cleanup the game state.
	 */
	function cleanup():Void;
}

