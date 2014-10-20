package org.angle3d.input;

import flash.display.Stage;
import flash.Lib;
import haxe.ds.IntMap;
import haxe.ds.StringMap;
import org.angle3d.input.controls.ActionListener;
import org.angle3d.input.controls.AnalogListener;
import org.angle3d.input.controls.InputListener;
import org.angle3d.input.controls.KeyTrigger;
import org.angle3d.input.controls.MouseAxisTrigger;
import org.angle3d.input.controls.MouseButtonTrigger;
import org.angle3d.input.controls.Trigger;
import org.angle3d.input.event.InputEvent;
import org.angle3d.input.event.KeyInputEvent;
import org.angle3d.input.event.MouseButtonEvent;
import org.angle3d.input.event.MouseMotionEvent;
import org.angle3d.input.event.MouseWheelEvent;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector2f;
import org.angle3d.utils.Assert;
import org.angle3d.utils.Logger;



using org.angle3d.utils.ArrayUtil;

/**
 * The <code>InputManager</code> is responsible for converting input events
 * received from the Key, Mouse and Joy Input implementations into an
 * abstract, input device independent representation that user code can use.
 * <p>
 * By default an <code>InputManager</code> is included with every Application instance for use
 * in user code to query input, unless the Application is created as headless
 * or with input explicitly disabled.
 * <p>
 * The input manager has two concepts, a {@link Trigger} and a mapping.
 * A trigger represents a specific input trigger, such as a key button,
 * or a mouse axis. A mapping represents a link onto one or several triggers,
 * when the appropriate trigger is activated (e.g. a key is pressed), the
 * mapping will be invoked. Any listeners registered to receive an event
 * from the mapping will have an event raised.
 * <p>
 * There are two types of events that {@link InputListener input listeners}
 * can receive, one is {@link ActionListener#onAction(java.lang.String, Bool, float) action}
 * events and another is {@link AnalogListener#onAnalog(java.lang.String, float, float) analog}
 * events.
 * <p>
 * <code>onAction</code> events are raised when the specific input
 * activates or deactivates. For a digital input such as key press, the <code>onAction()</code>
 * event will be raised with the <code>isPressed</code> argument equal to true,
 * when the key is released, <code>onAction</code> is called again but this time
 * with the <code>isPressed</code> argument set_to false.
 * For analog inputs, the <code>onAction</code> method will be called any time
 * the input is non-zero, however an exception to this is for joystick axis inputs,
 * which are only called when the input is above the {@link InputManager#setAxisDeadZone(float) dead zone}.
 * <p>
 * <code>onAnalog</code> events are raised every frame while the input is activated.
 * For digital inputs, every frame that the input is active will cause the
 * <code>onAnalog</code> method to be called, the argument <code>value</code>
 * argument will equal to the frame's time per frame (TPF) value but only
 * for digital inputs. For analog inputs however, the <code>value</code> argument
 * will equal the actual analog value.
 */
class InputManager implements RawInputListener
{
	public var cursorPosition:Vector2f;
	
	private var mInitialized:Bool;
	private var mStage:Stage;

	private var mKeyInput:KeyInput;
	private var mMouseInput:MouseInput;

	private var frameTPF:Float;
	private var lastLastUpdateTime:Float;
	private var lastUpdateTime:Float;
	private var frameDelta:Float;
	private var firstTime:Int;

	private var eventsPermitted:Bool;
	private var mouseVisible:Bool;
	private var safeMode:Bool;
	private var axisDeadZone:Float;

	private var bindings:IntMap<Array<InputMapping>>;
	private var mappings:StringMap<InputMapping>;

	private var pressedButtons:IntMap<Float>;
	private var axisValues:IntMap<Float>;
	private var rawListeners:Array<RawInputListener>;
	private var inputQueue:Array<InputEvent>;

	public function new()
	{
		mKeyInput = new KeyInput();
		mMouseInput = new MouseInput();

		mKeyInput.setInputListener(this);
		mMouseInput.setInputListener(this);

		lastLastUpdateTime = 0;
		lastUpdateTime = 0;
		frameDelta = 0;
		eventsPermitted = true;
		mouseVisible = true;
		safeMode = false;
		axisDeadZone = 0.05;

		cursorPosition = new Vector2f();

		bindings = new IntMap<Array<InputMapping>>();
		mappings = new StringMap<InputMapping>();

		pressedButtons = new IntMap<Float>();
		axisValues = new IntMap<Float>();
		rawListeners = new Array<RawInputListener>();
		inputQueue = new Array<InputEvent>();

		mInitialized = false;
	}

	public function initialize(stage:Stage):Void
	{
		mStage = stage;

		mKeyInput.initialize(stage);
		mMouseInput.initialize(stage);

		firstTime = Lib.getTimer();

		mInitialized = true;
	}

	public function destroy():Void
	{
		if (mKeyInput != null)
		{
			mKeyInput.destroy();
			mKeyInput = null;
		}

		if (mMouseInput != null)
		{
			mMouseInput.destroy();
			mMouseInput = null;
		}
	}


	/**
	 * Called before a batch of input will be sent to this
	 * <code>RawInputListener</code>.
	 */
	public function beforeInput():Void
	{

	}

	/**
	 * Called after a batch of input was sent to this
	 * <code>RawInputListener</code>.
	 *
	 * The listener should set_the {@link InputEvent#setConsumed() consumed flag}
	 * on any events that have been consumed either at this call or previous calls.
	 */
	public function afterInput():Void
	{

	}

	/**
	 * Invoked on mouse movement/motion events.
	 *
	 * @param evt
	 */
	public function onMouseMotionEvent(evt:MouseMotionEvent):Void
	{
		//if (!eventsPermitted) 
		//{
		//throw new Error("MouseInput has raised an event at an illegal time.");
		//}

		cursorPosition.setTo(evt.x, mStage.stageHeight - evt.y);
		inputQueue.push(evt);
	}

	public function onMouseWheelEvent(evt:MouseWheelEvent):Void
	{
		//if (!eventsPermitted) 
		//{
		//throw new Error("MouseInput has raised an event at an illegal time.");
		//}
		inputQueue.push(evt);
	}

	/**
	 * Callback from RawInputListener. Do not use.
	 */
	public function onMouseButtonEvent(evt:MouseButtonEvent):Void
	{
		//if (!eventsPermitted) 
		//{
		//throw new Error("MouseInput has raised an event at an illegal time.");
		//}

		inputQueue.push(evt);
	}

	/**
	 * Invoked on keyboard key press or release events.
	 *
	 * @param evt
	 */
	public function onKeyEvent(evt:KeyInputEvent):Void
	{
		//if (!eventsPermitted) 
		//{
		//throw new Error("KeyInput has raised an event at an illegal time.");
		//}

		inputQueue.push(evt);
	}



	/**
	 * set_the deadzone for joystick axes.
	 *
	 * <p>{@link ActionListener#onAction(java.lang.String, Bool, float) }
	 * events will only be raised if the joystick axis value is greater than
	 * the <code>deadZone</code>.
	 *
	 * @param deadZone the deadzone for joystick axes.
	 */
	public function setAxisDeadZone(deadZone:Float):Void
	{
		this.axisDeadZone = deadZone;
	}

	/**
	 * Returns the deadzone for joystick axes.
	 *
	 * @return the deadzone for joystick axes.
	 */
	public function getAxisDeadZone():Float
	{
		return axisDeadZone;
	}

	/**
	 * Adds a new listener to receive events on the given mappings.
	 *
	 * <p>The given InputListener will be registered to receive events
	 * on the specified mapping names. When a mapping raises an event, the
	 * listener will have its appropriate method invoked, either
	 * {@link ActionListener#onAction(java.lang.String, Bool, float) }
	 * or {@link AnalogListener#onAnalog(java.lang.String, float, float) }
	 * depending on which interface the <code>listener</code> implements.
	 * If the listener implements both interfaces, then it will receive the
	 * appropriate event for each method.
	 *
	 * @param listener The listener to register to receive input events.
	 * @param mappingNames The mapping names which the listener will receive
	 * events from.
	 *
	 * @see InputManager#removeListener(com.jme3.input.controls.InputListener)
	 */
	public function addListener(listener:InputListener, mappingNames:Array<String>):Void
	{
		for (mappingName in mappingNames)
		{
			var im:InputMapping = mappings.get(mappingName);
			if (im == null)
			{
				im = new InputMapping(mappingName);
				mappings.set(mappingName, im);
			}

			if (!im.listeners.contains(listener))
			{
				im.listeners.push(listener);
			}
		}
	}

	/**
	 * Removes a listener from receiving events.
	 *
	 * <p>This will unregister the listener from any mappings that it
	 * was previously registered with via
	 * {@link InputManager#addListener(com.jme3.input.controls.InputListener, java.lang.String[]) }.
	 *
	 * @param listener The listener to unregister.
	 *
	 * @see InputManager#addListener(com.jme3.input.controls.InputListener, java.lang.String[])
	 */
	public function removeListener(listener:InputListener):Void
	{
		for (map in mappings)
		{
			map.listeners.remove(listener);
		}
	}

	/**
	 * Create a new mapping to the given triggers.
	 *
	 * <p>
	 * The given mapping will be assigned to the given triggers, when
	 * any of the triggers given raise an event, the listeners
	 * registered to the mappings will receive appropriate events.
	 *
	 * @param mappingName The mapping name to assign.
	 * @param triggers The triggers to which the mapping is to be registered.
	 *
	 * @see InputManager#deleteMapping(java.lang.String)
	 */
	public function addMapping(mappingName:String, triggers:Array<Trigger>):Void
	{
		var mapping:InputMapping = mappings.get(mappingName);
		if (mapping == null)
		{
			mapping = new InputMapping(mappingName);
			mappings.set(mappingName, mapping);
		}

		for (trigger in triggers)
		{
			var hash:Int = trigger.triggerHashCode();
			var names:Array<InputMapping> = bindings.get(hash);
			if (names == null)
			{
				names = [];
				bindings.set(hash,names);
			}

			if (!names.contains(mapping))
			{
				names.push(mapping);
				mapping.triggers.push(hash);
			}
			else
			{
				Logger.log("Attempted to add mapping \"" + mappingName + "\" twice to trigger.");
			}
		}
	}

	public function addSingleMapping(mappingName:String, trigger:Trigger):Void
	{
		var mapping:InputMapping = mappings.get(mappingName);
		if (mapping == null)
		{
			mapping = new InputMapping(mappingName);
			mappings.set(mappingName,mapping);
		}

		var hash:Int = trigger.triggerHashCode();
		var names:Array<InputMapping> = bindings.get(hash);
		if (names == null)
		{
			names = [];
			bindings.set(hash,names);
		}

		if (!names.contains(mapping))
		{
			names.push(mapping);
			mapping.triggers.push(hash);
		}
		else
		{
			Logger.log("Attempted to add mapping \"" + mappingName + "\" twice to trigger.");
		}
	}

	/**
	 * Deletes a mapping from receiving trigger events.
	 *
	 * <p>
	 * The given mapping will no longer be assigned to receive trigger
	 * events.
	 *
	 * @param mappingName The mapping name to unregister.
	 *
	 * @see InputManager#addMapping(java.lang.String, com.jme3.input.controls.Trigger[])
	 */
	public function deleteMapping(mappingName:String):Void
	{
		var mapping:InputMapping = mappings.get(mappingName);
		if (mapping == null)
		{
			Logger.log("Cannot find mapping to be removed, skipping: $mappingName");
			return;
		}

		var triggers:Array<Int> = mapping.triggers;
		var i:Int = triggers.length;
		while (--i >= 0)
		{
			var hash:Int = triggers[i];
			var maps:Array<InputMapping> = bindings.get(hash);
			maps.remove(mapping);
		}
	}

	/**
	 * Deletes a specific trigger registered to a mapping.
	 *
	 * <p>
	 * The given mapping will no longer receive events raised by the
	 * trigger.
	 *
	 * @param mappingName The mapping name to cease receiving events from the
	 * trigger.
	 * @param trigger The trigger to no longer invoke events on the mapping.
	 */
	public function deleteTrigger(mappingName:String, trigger:Trigger):Void
	{
		var mapping:InputMapping = mappings.get(mappingName);

		Assert.assert(mapping != null, "Cannot find mapping: " + mappingName);

		var maps:Array<InputMapping> = bindings.get(trigger.triggerHashCode());
		maps.remove(mapping);
	}

	/**
	 * Clears all the input mappings from this InputManager.
	 * Consequently, also clears all of the
	 * InputListeners as well.
	 */
	public function clearMappings():Void
	{
		mappings = new StringMap<InputMapping>();
		bindings = new IntMap<Array<InputMapping>>();
		reset();
	}

	/**
	 * Do not use.
	 * Called to reset_pressed keys or buttons when focus is restored.
	 */
	public function reset():Void
	{
		pressedButtons = new IntMap<Float>();
		axisValues = new IntMap<Float>();
	}

	/**
	 * Returns whether the mouse cursor is visible or not.
	 *
	 * <p>By default the cursor is visible.
	 *
	 * @return whether the mouse cursor is visible or not.
	 *
	 * @see InputManager#setCursorVisible(Bool)
	 */
	public function isCursorVisible():Bool
	{
		return mouseVisible;
	}

	/**
	 * set_whether the mouse cursor should be visible or not.
	 *
	 * @param visible whether the mouse cursor should be visible or not.
	 */
	public function setCursorVisible(visible:Bool):Void
	{
		if (mouseVisible != visible)
		{
			mouseVisible = visible;
			mMouseInput.setCursorVisible(mouseVisible);
		}
	}

	/**
	 * Adds a {@link RawInputListener} to receive raw input events.
	 *
	 * <p>
	 * Any raw input listeners registered to this <code>InputManager</code>
	 * will receive raw input events first, before they get_handled
	 * by the <code>InputManager</code> itself. The listeners are
	 * each processed in the order they were added, e.g. FIFO.
	 * <p>
	 * If a raw input listener has handled the event and does not wish
	 * other listeners down the list to process the event, it may set_the
	 * {@link InputEvent#setConsumed() consumed flag} to indicate the
	 * event was consumed and shouldn't be processed any further.
	 * The listener may do this either at each of the event callbacks
	 * or at the {@link RawInputListener#endInput() } method.
	 *
	 * @param listener A listener to receive raw input events.
	 *
	 * @see RawInputListener
	 */
	public function addRawInputListener(listener:RawInputListener):Void
	{
		rawListeners.push(listener);
	}

	/**
	 * Removes a {@link RawInputListener} so that it no longer
	 * receives raw input events.
	 *
	 * @param listener The listener to cease receiving raw input events.
	 *
	 * @see InputManager#addRawInputListener(com.jme3.input.RawInputListener)
	 */
	public function removeRawInputListener(listener:RawInputListener):Void
	{
		var index:Int = rawListeners.indexOf(listener);

		if (index > -1)
		{
			rawListeners.splice(index, 1);
		}
	}

	/**
	 * Clears all {@link RawInputListener}s.
	 *
	 * @see InputManager#addRawInputListener(com.jme3.input.RawInputListener)
	 */
	public function clearRawInputListeners():Void
	{
		rawListeners = [];
	}

	/**
	 * Updates the <code>InputManager</code>.
	 * This will query current input devices and send
	 * appropriate events to registered listeners.
	 *
	 * @param tpf Time per frame value.
	 */
	public function update(tpf:Float):Void
	{
		if (!mInitialized)
			return;

		frameTPF = tpf;

		// Activate safemode if the TPF value is so small
		// that rounding errors are inevitable
		safeMode = tpf < 0.015;

		var currentTime:Int = flash.Lib.getTimer();
		frameDelta = currentTime - lastUpdateTime;

		eventsPermitted = true;

		mKeyInput.update();
		mMouseInput.update();

		eventsPermitted = false;

		processQueue();
		invokeUpdateActions();

		lastLastUpdateTime = lastUpdateTime;
		lastUpdateTime = currentTime;
	}

	private function invokeActions(hash:Int, pressed:Bool):Void
	{
		var maps:Array<InputMapping> = bindings.get(hash);
		if (maps == null)
		{
			return;
		}

		var size:Int = maps.length;
		var i:Int = size;
		while (--i >= 0)
		{
			var mapping:InputMapping = maps[i];
			var listeners:Array<InputListener> = mapping.listeners;
			var j:Int = listeners.length;
			while (--j >= 0)
			{
				var listener:InputListener = listeners[j];
				if (Std.is(listener,ActionListener))
				{
					Std.instance(listener,ActionListener).onAction(mapping.name, pressed, frameTPF);
				}
			}
		}
	}

	private function computeAnalogValue(timeDelta:Float):Float
	{
		if (safeMode || frameDelta == 0)
		{
			return 1.0;
		}
		else
		{
			return FastMath.clamp(timeDelta / frameDelta, 0, 1);
		}
	}

	private function invokeTimedActions(hash:Int, time:Float, pressed:Bool):Void
	{
		if (!bindings.exists(hash))
		{
			return;
		}

		if (pressed)
		{
			pressedButtons.set(hash,time);
		}
		else
		{
			var pressTime:Float = pressedButtons.get(hash);
			var timeDelta:Float = time - FastMath.max(pressTime, lastLastUpdateTime);
			if (timeDelta > 0)
			{
				invokeAnalogs(hash, computeAnalogValue(timeDelta), false);
			}
		}
	}

	private function processQueue():Void
	{
		for (listener in rawListeners)
		{
			listener.beforeInput();

			for (event in inputQueue)
			{
				if (event.isConsumed())
				{
					continue;
				}

				if (Std.is(event,MouseMotionEvent))
				{
					listener.onMouseMotionEvent(Std.instance(event, MouseMotionEvent));
				}
				else if (Std.is(event,KeyInputEvent))
				{
					listener.onKeyEvent(Std.instance(event, KeyInputEvent));
				}
				else if (Std.is(event,MouseButtonEvent))
				{
					listener.onMouseButtonEvent(Std.instance(event, MouseButtonEvent));
				}
				else if (Std.is(event,MouseWheelEvent))
				{
					listener.onMouseWheelEvent(Std.instance(event, MouseWheelEvent));
				}
				else
				{
					Assert.assert(false, "Can`t find this Event type");
				}
			}

			listener.afterInput();
		}


		for (event in inputQueue)
		{
			if (event.isConsumed())
			{
				continue;
			}

			if (Std.is(event,MouseMotionEvent))
			{
				onMouseMotionEventQueued(Std.instance(event, MouseMotionEvent));
			}
			else if (Std.is(event,KeyInputEvent))
			{
				onKeyEventQueued(Std.instance(event, KeyInputEvent));
			}
			else if (Std.is(event,MouseButtonEvent))
			{
				onMouseButtonEventQueued(Std.instance(event, MouseButtonEvent));
			}
			else if (Std.is(event,MouseWheelEvent))
			{
				onMouseWheelEventQueued(Std.instance(event, MouseWheelEvent));
			}
			else
			{
				Assert.assert(false, "");
			}
		}

		inputQueue = [];
	}

	private function invokeUpdateActions():Void
	{
		var keys = pressedButtons.keys();
		for (hash in keys)
		{
			var pressTime:Float = pressedButtons.get(hash);
			var timeDelta:Float = lastUpdateTime - FastMath.max(lastLastUpdateTime, pressTime);

			if (timeDelta > 0)
			{
				invokeAnalogs(hash, computeAnalogValue(timeDelta), false);
			}
		}

		var keys = axisValues.keys();
		for (key in keys)
		{
			var value:Float = axisValues.get(key);
			invokeAnalogs(key, value * frameTPF, true);
		}
	}

	private function invokeAnalogs(hash:Int, value:Float, isAxis:Bool):Void
	{
		var maps:Array<InputMapping> = bindings.get(hash);
		if (maps == null)
		{
			return;
		}

		if (!isAxis)
		{
			value *= frameTPF;
		}

		var i:Int = maps.length;
		while (--i >= 0)
		{
			var mapping:InputMapping = maps[i];
			var listeners:Array<InputListener> = mapping.listeners;
			var j:Int = listeners.length;
			while (--j >= 0)
			{
				var listener:InputListener = listeners[j];
				if (Std.is(listener,AnalogListener))
				{
					// NOTE: multiply by TPF for any button bindings
					Std.instance(listener,AnalogListener).onAnalog(mapping.name, value, frameTPF);
				}
			}
		}
	}

	private function invokeAnalogsAndActions(hash:Int, value:Float, applyTpf:Bool):Void
	{
		if (value < axisDeadZone)
		{
			invokeAnalogs(hash, value, !applyTpf);
			return;
		}

		var maps:Array<InputMapping> = bindings.get(hash);
		if (maps == null)
		{
			return;
		}

		var valueChanged:Bool = !axisValues.exists(hash);
		if (applyTpf)
		{
			value *= frameTPF;
		}

		var i:Int = maps.length;
		while (--i >= 0)
		{
			var mapping:InputMapping = maps[i];
			var listeners:Array<InputListener> = mapping.listeners;
			var j:Int = listeners.length;
			while (--j >= 0)
			{
				var listener:InputListener = listeners[j];

				if (Std.is(listener,ActionListener))
				{
					cast(listener,ActionListener).onAction(mapping.name, true, frameTPF);
				}


				if (Std.is(listener,AnalogListener))
				{
					cast(listener,AnalogListener).onAnalog(mapping.name, value, frameTPF);
				}
			}
		}
	}

	private function onMouseMotionEventQueued(evt:MouseMotionEvent):Void
	{
		var val:Float;
		var dx:Float = evt.dx;
		if (dx != 0)
		{
			val = FastMath.abs(dx / 1024);
			invokeAnalogsAndActions(MouseAxisTrigger.mouseAxisHash(MouseInput.AXIS_X, dx < 0), val, false);
		}
		var dy:Float = evt.dy;
		if (dy != 0)
		{
			val = FastMath.abs(dy / 1024);
			invokeAnalogsAndActions(MouseAxisTrigger.mouseAxisHash(MouseInput.AXIS_Y, dy < 0), val, false);
		}
	}

	private function onMouseWheelEventQueued(evt:MouseWheelEvent):Void
	{
		var delta:Int = evt.deltaWheel;
		if (delta != 0)
		{
			//var val:Float = FastMath.fabs(delta / 10);
			invokeAnalogsAndActions(MouseAxisTrigger.mouseAxisHash(MouseInput.AXIS_WHEEL, delta < 0), delta, false);
		}
	}


	private function onKeyEventQueued(evt:KeyInputEvent):Void
	{
		var hash:Int = KeyTrigger.keyHash(evt.keyCode);
		invokeActions(hash, evt.pressed);
		invokeTimedActions(hash, evt.getTime(), evt.pressed);
	}

	private function onMouseButtonEventQueued(evt:MouseButtonEvent):Void
	{
		var hash:Int = MouseButtonTrigger.mouseButtonHash(evt.getButtonIndex());
		invokeActions(hash, evt.pressed);
		invokeTimedActions(hash, evt.getTime(), evt.pressed);
	}
}

