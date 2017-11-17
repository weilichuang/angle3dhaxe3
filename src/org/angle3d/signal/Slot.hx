package org.angle3d.signal;

import org.angle3d.signal.Signal;

/**
	A convenience type describing any kind of slot.
**/
typedef AnySlot = Slot<Dynamic, Dynamic>;

/**
	Defines the basic properties of a listener associated with a Signal.
**/
class Slot<TSignal:org.angle3d.signal.Signal.AnySignal, TListener> {
	/**
		The listener associated with this slot.
	**/
	@:isVar
	public var listener(default, set):TListener;

	/**
		Whether this slot is automatically removed after it has been used once.
	**/
	public var once(default, null):Bool;

	/**
		The priority of this slot should be given in the execution order.
		An Signal will call higher numbers before lower ones.
		Defaults to 0.
	**/
	public var priority(default, null):Int;

	/**
		Whether the listener is called on execution. Defaults to true.
	**/
	public var enabled:Bool;

	var signal:TSignal;

	function new(signal:TSignal, listener:TListener, ?once:Bool=false, ?priority:Int=0) {
		this.signal = signal;
		this.listener = listener;
		this.once = once;
		this.priority = priority;
		this.enabled = true;
	}

	/**
		Removes the slot from its signal.
	**/
	public function remove() {
		signal.remove(listener);
	}

	function set_listener(value:TListener):TListener {
		#if debug
		if (value == null) throw "listener cannot be null";
		#end
		return listener = value;
	}
}

/**
	A slot that executes a listener with no arguments.
**/
class Slot0 extends Slot<Signal0, Void -> Void> {
	public function new(signal:Signal0, listener:Void -> Void, ?once:Bool=false, ?priority:Int=0) {
		super(signal, listener, once, priority);
	}

	/**
		Executes a listener with no arguments.
	**/
	public function execute() {
		if (!enabled) return;
		if (once) remove();
		listener();
	}
}

/**
	A slot that executes a listener with one argument.
**/
class Slot1<TValue> extends Slot<Signal1<TValue>, TValue -> Void> {
	/**
		Allows the slot to inject the argument to dispatch.
	**/
	public var param:TValue;

	public function new(signal:Signal1<TValue>, listener:TValue -> Void, ?once:Bool=false, ?priority:Int=0) {
		super(signal, listener, once, priority);
	}

	/**
		Executes a listener with one argument.
		If `param` is not null, it overrides the value provided.
	**/
	public function execute(value1:TValue) {
		if (!enabled) return;
		if (once) remove();
		if (param != null) value1 = param;
		listener(value1);
	}
}

/**
	A slot that executes a listener with two arguments.
**/
class Slot2<TValue1, TValue2> extends Slot<Signal2<TValue1, TValue2>, TValue1 -> TValue2 -> Void> {
	/**
		Allows the slot to inject the first argument to dispatch.
	**/
	public var param1:TValue1;

	/**
		Allows the slot to inject the second argument to dispatch.
	**/
	public var param2:TValue2;

	public function new(signal:Signal2<TValue1, TValue2>, listener:TValue1 -> TValue2 -> Void, ?once:Bool=false, ?priority:Int=0) {
		super(signal, listener, once, priority);
	}

	/**
		Executes a listener with two arguments.
		If `param1` or `param2` is set,
		they override the values provided.
	**/
	public function execute(value1:TValue1, value2:TValue2) {
		if (!enabled) return;
		if (once) remove();

		if (param1 != null) value1 = param1;
		if (param2 != null) value2 = param2;

		listener(value1, value2);
	}
}

/**
	A slot that executes a listener with two arguments.
**/
class Slot3<TValue1, TValue2, TValue3> extends Slot<Signal3<TValue1, TValue2, TValue3>, TValue1 -> TValue2 -> TValue3-> Void> {
	/**
		Allows the slot to inject the first argument to dispatch.
	**/
	public var param1:TValue1;

	/**
		Allows the slot to inject the second argument to dispatch.
	**/
	public var param2:TValue2;

	/**
		Allows the slot to inject the second argument to dispatch.
	**/
	public var param3:TValue3;

	public function new(signal:Signal3<TValue1, TValue2, TValue3>, listener:TValue1 -> TValue2 -> TValue3 -> Void, ?once:Bool=false, ?priority:Int=0) {
		super(signal, listener, once, priority);
	}

	/**
		Executes a listener with two arguments.
		If `param1` or `param2` is set,
		they override the values provided.
	**/
	public function execute(value1:TValue1, value2:TValue2, value3:TValue3) {
		if (!enabled) return;
		if (once) remove();

		if (param1 != null) value1 = param1;
		if (param2 != null) value2 = param2;
		if (param3 != null) value3 = param3;

		listener(value1, value2, value3);
	}
}
