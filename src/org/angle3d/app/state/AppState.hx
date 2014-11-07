package org.angle3d.app.state;

import org.angle3d.app.Application;
import org.angle3d.renderer.RenderManager;

/**
 * AppState represents continously executing code inside the main loop.
 * 
 * An <code>AppState</code> can track when it is attached to the 
 * {@link AppStateManager} or when it is detached. 
 * 
 * <br/><code>AppState</code>s are initialized in the render thread, upon a call to 
 * {@link AppState#initialize(com.jme3.app.state.AppStateManager, com.jme3.app.Application) }
 * and are de-initialized upon a call to {@link AppState#cleanup()}. 
 * Implementations should return the correct value with a call to 
 * {@link AppState#isInitialized() } as specified above.<br/>
 * 
 * <ul>
 * <li>If a detached AppState is attached then <code>initialize()</code> will be called
 * on the following render pass.
 * </li>
 * <li>If an attached AppState is detached then <code>cleanup()</code> will be called
 * on the following render pass.
 * </li>
 * <li>If you attach an already-attached <code>AppState</code> then the second attach
 * is a no-op and will return false.
 * </li>
 * <li>If you both attach and detach an <code>AppState</code> within one frame then
 * neither <code>initialize()</code> or <code>cleanup()</code> will be called,
 * although if either is called both will be.
 * </li>
 * <li>If you both detach and then re-attach an <code>AppState</code> within one frame
 * then on the next update pass its <code>cleanup()</code> and <code>initialize()</code>
 * methods will be called in that order.
 * </li>
 * </ul>
 * @author Kirill Vainer
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
	function isInitialized():Bool;

	/**
	 * Enable or disable the functionality of the <code>AppState</code>.
	 * The effect of this call depends on implementation. An
	 * <code>AppState</code> starts as being enabled by default.
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

