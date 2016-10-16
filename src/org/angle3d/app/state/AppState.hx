package org.angle3d.app.state;

import org.angle3d.app.LegacyApplication;
import org.angle3d.renderer.RenderManager;

/**
 * AppState represents continously executing code inside the main loop.
 * 
 * An `AppState` can track when it is attached to the 
 * {AppStateManager} or when it is detached. 
 * 
 * <br/>`AppState`s are initialized in the render thread, upon a call to 
 * {AppState#initialize(org.angle3d.app.state.AppStateManager, org.angle3d.app.Application) }
 * and are de-initialized upon a call to {AppState#cleanup()}. 
 * Implementations should return the correct value with a call to 
 * {AppState#isInitialized() } as specified above.<br/>
 * 
 * <ul>
 * <li>If a detached AppState is attached then `initialize()` will be called
 * on the following render pass.
 * </li>
 * <li>If an attached AppState is detached then `cleanup()` will be called
 * on the following render pass.
 * </li>
 * <li>If you attach an already-attached `AppState` then the second attach
 * is a no-op and will return false.
 * </li>
 * <li>If you both attach and detach an `AppState` within one frame then
 * neither `initialize()` or `cleanup()` will be called,
 * although if either is called both will be.
 * </li>
 * <li>If you both detach and then re-attach an `AppState` within one frame
 * then on the next update pass its `cleanup()` and `initialize()`
 * methods will be called in that order.
 * </li>
 * </ul>
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
	function initialize(stateManager:AppStateManager, app:LegacyApplication):Void;

	/**
	 * @return True if `initialize()` was called on the state,
	 * false otherwise.
	 */
	function isInitialized():Bool;

	/**
	 * Enable or disable the functionality of the `AppState`.
	 * The effect of this call depends on implementation. An
	 * `AppState` starts as being enabled by default.
	 *
	 * @param value active the AppState or not.
	 */
	function setEnabled(value:Bool):Void;
	
	function isEnabled():Bool;
	
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

