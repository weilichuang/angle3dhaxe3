/*
Copyright (c) 2012-2014 Michael Baczynski, http://www.polygonal.de

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
package de.polygonal.core.event;

import de.polygonal.core.event.Observable;
import de.polygonal.core.fmt.StringUtil;
import de.polygonal.ds.ArrayedStack;
import de.polygonal.ds.Bits;
import de.polygonal.ds.HashableItem;
import de.polygonal.ds.ListSet;
import de.polygonal.ds.pooling.DynamicObjectPool;
import haxe.ds.Vector;
import haxe.ds.IntMap;

/**
	An object with state that is observed by an `IObserver` implementation.
	See <a href="http://en.wikipedia.org/wiki/Observer_pattern" target="_blank">http://en.wikipedia.org/wiki/Observer_pattern</a>.
**/
class Observable extends HashableItem implements IObservable
{
	static var _nextGUID = 1;
	static var _registry:ListSet<Observable>;
	static function _getRegistry()
	{
		if (_registry == null)
			_registry = new ListSet<Observable>();
		return _registry;
	}
	
	/**
		Prints out a list of all installed observers (application-wide).
	**/
	public static function dump():String
	{
		var c = 0;
		var s = "";
		for (observable in _getRegistry())
		{
			c += observable.size();
			s += Printf.format("%-20s -> %s\n", [StringUtil.ellipsis(Std.string(observable), 20, 0), observable.size()]);
		}
		return Printf.format("#observers: %03d\n", [c]) + s;
	}
	
	/**
		Clears all installed observers (application-wide).
	**/
	public static function release()
	{
		try
		{
			for (observable in _getRegistry())
			{
				observable.clear();
				observable.free();
			}
			_getRegistry().clear();
		}
		catch (unknown:Dynamic) {}
	}
	
	/**
		Counts the total number of observers (application-wide).
	**/
	public static function totalObserverCount():Int
	{
		var c = 0;
		for (observable in _getRegistry()) c += observable.size();
		return c;
	}
	
	/**
		Calls the function `func` whenever `source` triggers an update of one type specified in `mask`.
		Example:
		<pre class="prettyprint">
		import de.polygonal.core.event.Observable;
		import de.polygonal.core.time.Timbase;
		import de.polygonal.core.time.TimbaseEvent;
		class Main {
		    static function main() {
		        var func = function(type, userData) {
		            if (type == TimebaseEvent.TICK) {
		                trace("tick");
		                return false; //stop TICK updates, but keep RENDER updates
		            }
		            if (type == TimebaseEvent.RENDER) {
		                trace("render");
		                return true; //keep alive
		            }
		        }
		        Observable.bind(func, Timebase.get(), TimebaseEvent.TICK | TimebaseEvent.RENDER);
		    }
		}
		</pre>
	**/
	public static function bind(func:Int->Dynamic->Bool, source:IObservable, mask = 0)
	{
		source.attach(Bind.get(func, mask), mask);
	}
	
	/**
		Delegates `IObserver.onUpdate()` to the given function `func`, as long as `func` returns true.
		Example:
		<pre class="prettyprint">
		import de.polygonal.core.event.Observable;
		import de.polygonal.core.time.TimbaseEvent;
		class Main
		{
		    static function main() {
		        var func = function(type:Int, source:Observable, userData:Dynamic):Bool {
		            trace(type);
		            return false; //detach from event source
		        }
		        var observable = new Observable();
		        observable.attach(Observable.delegate(func));
		    }
		}
		</pre>
	**/
	public static function delegate(func:Int->IObservable->Dynamic->Bool):IObserver
	{
		return Delegate.get(func);
	}
	
	var _source:IObservable;
	
	var mObserverList:ObserverNode;
	var mObserverCount:Int;
	
	var mPoolHead:ObserverNode;
	var mPoolTail:ObserverNode;
	var mHook:ObserverNode;
	
	var _blacklist:Int;
	var mPoolSize:Int;
	var mPoolCapacity:Int;
	
	var mFreed:Bool;
	var _updating:Bool;
	var _stack:Array<Dynamic>;
	var _stackSize:Int;
	var _type:Int;
	var _userData:Dynamic;
	var mNodeLookup:IntMap<ObserverNode>;
	
	/**
		@param poolSize because observers are stored internally in a linked list it's necessary to create a node object per attached observer.
		Thus it makes sense to reuse a node object when an observer is detached from this object instead of handling it over to the GC.
		A value > 0 sets up node pool capable of reusing up to `poolSize` node objects.
		Once the pool has reached its capacity new node objects are still created but not reused.
		To conserve memory node objects are not pre-allocated up front - instead the pool is filled incrementally when detaching observers.
		To force pre-allocation, call `reserve()`.
	**/
	public function new(poolSize = 0, source:IObservable = null)
	{
		super();
		
		_source        = (source == null) ? this : source;
		mObserverList      = null;
		mObserverCount = 0;
		mPoolHead          =  new ObserverNode();
		mPoolTail          = mPoolHead;
		mHook          = null;
		_blacklist     = 0;
		mPoolSize      = 0;
		mPoolCapacity  = poolSize;
		mFreed         = false;
		_updating      = false;
		_stack         = new Array<Dynamic>();
		_stackSize = 0;
		_type          = 0;
		_userData      = null;
		mNodeLookup    = new IntMap();
	}
	
	/**
		Disposes this object by detaching all observers and explicitly nullifying all nodes, pointers and elements for GC'ing used resources.
		Improves GC efficiency/performance (optional).
	**/
	public function free()
	{
		if (mFreed) return;
		
		clear();
		
		_stack = null;
		
		var n = mPoolHead;
		while (n != null)
		{
			var t      = n.next;
			n.prev     = null;
			n.next     = null;
			n.observer = null;
			n.mask     = null;
			n          = t;
		}
		
		mNodeLookup = null;
		_stack      = null;
		mPoolHead       = null;
		mPoolTail       = null;
		_userData   = null;
		
		mFreed = true;
	}
	
	/**
		Returns the total number of attached observers.
	**/
	public function size():Int
	{
		return mObserverCount;
	}
	
	/**
		Explicitly allocates k node objects up front for storing observers.
		Because observers are stored internally in a linked list it's necessary to create a node object per observer.
		Thus it makes sense to reuse a node object when an observer is detached from this object instead of handing it over to the GC.
		This improves performance when observers are frequently attached and detached.
		This value can be adjusted at any time; a value of zero disables preallocation.
	**/
	public function reserve(k:Int)
	{
		mPoolCapacity = k;
		if (k < mPoolSize)
		{
			//shrink pool by (mPoolSize - k)
			for (i in 0...mPoolSize - k)
				mPoolHead = mPoolHead.next;
		}
		else
		{
			//grow pool by (k - mPoolSize)
			for (i in 0...k - mPoolSize)
			{
				mPoolTail = mPoolTail.next = new ObserverNode();
			}
		}
		mPoolSize = k;
	}
	
	/**
		Removes all attached observers.
		The internal pool defined by `reserve()` is not altered.
		@param purge if true, the pool is emptied.
	**/
	public function clear(purge = false)
	{
		if (mObserverCount > 0) _getRegistry().remove(this);
		
		_stackSize = 0;
		
		_userData      = false;
		_updating      = false;
		mHook          = null;
		mObserverList      = null;
		mObserverCount = 0;
		mNodeLookup    = new IntMap();
		
		if (purge)
		{
			mPoolSize = 0;
			var node = mPoolHead;
			while (node != null)
			{
				var next = node.next;
				node.prev = null;
				node.next = null;
				node.observer = null;
				node = next;
			}
			
			mPoolHead =  new ObserverNode();
			mPoolTail = mPoolHead;
		}
	}
	
	inline function findNode(o:IObserver):ObserverNode
	{
		return mNodeLookup.get(o.__guid); //TODo use global map?
	}
	
	/**
		Registers an observer object `o` with this object so it is updated when calling `notify()`.
		Example:
		<pre class="prettyprint">
		import de.polygonal.core.event.Observable;
		import de.polygonal.core.event.IObserver;
		
		@:build(de.polygonal.core.event.ObserverMacro.create(
		[
		    UPDATE_A,
		    UPDATE_B,
		    UPDATE_C
		]))
		class MyEvent {}
		
		class MyObserver implements IObserver {
		    public function new() {}
		    public function onUpdate(type:Int, source:Observable, userData:Dynamic) {}
		}
		
		class Main {
		    public static function main() {
		        var observable = new Observable();
		        var observer = new MyObserver();
		        
		        //register with all updates (UPDATE_A, UPDATE_B, UPDATE_C)
		        observable.attach(observer);
		        
		        //or only register with a single update
		        observable.attach(observer, MyEvents.UPDATE_A);
		        
		        //or only register with a subset of updates
		        observable.attach(observer, MyEvents.UPDATE_A | MyEvents.UPDATE_B);
		    }
		}</pre>
		@param o the observer to register with.
		@param mask a bit field of bit flags defining which event types to register with.
		This can be used to select a subset of events from an event group.
		By default, `o` receives all updates from an event group.
		<warn>Must only contain event types from a single group, e.g. this mask is invalid: MyEventA.EVENT_X | MyEventB.EVENT_Y.</warn>
	**/
	public function attach(o:IObserver, mask = 0)
	{
		if (mFreed) return;
		
		//assign an id for fast node lookup
		if (o.__guid == 0) o.__guid = _nextGUID++;
		
		var n = findNode(o);
		
		if (n != null)
		{
			//{observer exists
			var groupId = mask >>> ObserverMacro.NUM_EVENT_BITS;
			
			//update bits only
			if (n.mask[groupId] == Bits.ALL)
			{
				if (mask != 0)
					n.mask[groupId] = mask & ObserverMacro.EVENT_MASK; //set given mask
			}
			else
			{
				if (mask != 0)
					n.mask[groupId] |= (mask & ObserverMacro.EVENT_MASK); //merge existing mask with new mask
				else
					n.mask[groupId] = Bits.ALL; //allow all
			}
			return;
			//}
		}
		
		//{get/create a node for storing the observer
		if (mPoolCapacity == 0)
		{
			//pooling disabled; create a node on-the-fly for storing the observer
			n = new ObserverNode();
		}
		else
		{
			//get a node from the pool
			if (mPoolSize == 0) //pool is empty
				n = new ObserverNode(); //create a node on-the-fly
			else
			{
				//get next available node from the pool
				n = mPoolHead;
				mPoolHead = mPoolHead.next;
				mPoolSize--;
			}
		}
		//}
		
		n.observer = o; //store observer
		
		if (mask == 0 || mask == Bits.ALL)
		{
			//prevent mask lookup if we listen to all updates
			n.all = true;
		}
		else
		{
			var groupId = mask >>> ObserverMacro.NUM_EVENT_BITS;
			n.mask[groupId] |= (mask == 0) ? Bits.ALL : (mask & ObserverMacro.EVENT_MASK);
			n.groupBits |= 1 << groupId;
		}
		
		mNodeLookup.set(o.__guid, n);
		
		//{prepend to observer list
		n.next = mObserverList;
		if (mObserverList != null) mObserverList.prev = n;
		mObserverList = n;
		mObserverCount++;
		//}
		
		if (mObserverCount == 1) //this is the first attached observer
			_getRegistry().set(this); //register with global observable list
	}
	
	/**
		Unregisters an observer object `o` from this object so it is no longer updated when calling `notify()`.
		Example:
		<pre class="prettyprint">
		import de.polygonal.core.event.Observable;
		import de.polygonal.core.event.IObserver;
		
		@:build(de.polygonal.core.event.ObserverMacro.create(
		[
		    UPDATE_A,
		    UPDATE_B,
		    UPDATE_C
		]))
		class MyEvent {}
		
		class MyObserver implements IObserver {
		    public function new() {}
		    public function onUpdate(type:Int, source:Observable, userData:Dynamic) {}
		}
		
		class Main {
		    public static function main() {
		        var observable = new Observable();
		        var observer = new MyObserver();
		        
		        //register with all updates (UPDATE_A, UPDATE_B, UPDATE_C, UPDATE_D)
		        observable.attach(observer);
		        
		        //only unregister from UPDATE_A
		        observable.detach(observer, MyEvents.UPDATE_A);
		        
		        //only unregister from UPDATE_B and UPDATE_C
		        observable.detach(observer, MyEvents.UPDATE_B | MyEvents.UPDATE_C);
		        
		        //unregister from event group (UPDATE_A, UPDATE_B, UPDATE_C, UPDATE_D)
		        observable.detach(observer);
		    }
		}</pre>
		@param o the observer to unregister from.
		@param mask a bit field of bit flags defining which event types to unregister from.
		This can be used to select a subset of events from an event group.
		By default, `o` is unregistered from the entire event group.
		<warn>Must only contain event types from a single group.</warn>
	**/
	public function detach(o:IObserver, mask:Int = 0)
	{
		if (mFreed) //free() was called?
			return;
		
		var n = findNode(o);
		if (n == null) return; //observer exists?
		
		if (mask != 0)
		{
			//update bits
			var groupId = mask >>> ObserverMacro.NUM_EVENT_BITS;
			n.mask[groupId] &= ~(mask & ObserverMacro.EVENT_MASK);
			
			//remove group if empty
			if (n.mask[groupId] == 0) n.groupBits &= ~(1 << groupId);
			
			//don't detach until all groups detached
			if (n.groupBits > 0) return;
		}
		
		//unlink from observer list
		if (n.prev != null) n.prev.next = n.next;
		if (n.next != null) n.next.prev = n.prev;
		if (n == mObserverList) mObserverList = n.next;
		if (n == mHook) mHook = mHook.next;
		
		if (_updating) //update in progress?
		{
			var i = 0;
			var k = _stackSize;
			while (i < k)
			{
				if (_stack[i] == n) _stack[i] = n.next;
				i += 3;
			}
		}
		
		mNodeLookup.remove(n.observer.__guid);
		
		//reset node
		n.observer = null;
		n.prev = n.next = null;
		
		if (mPoolCapacity > 0) //pooling enabled?
		{
			if (mPoolSize < mPoolCapacity) //room available?
			{
				//reuse it
				mPoolTail = mPoolTail.next = n;
				mPoolSize++;
			}
		}
		
		//remove node
		mObserverCount--;
		
		if (mObserverCount == 0) //last observer?
			_getRegistry().remove(this); //unregister from global observable list
	}
	
	/**
		Notifies all attached observers to indicate that the state of this object has changed.
		@param type the event type.
		<warn>Must only contain event types from a single group.</warn>
		@param userData additional event data. Default value is null.
	**/
	public function notify(type:Int, userData:Dynamic = null)
	{
		_notify(type, userData);
	}
	
	/**
		Disables all updates of type `x`.
		Improves performance if an event group repeatedly fires frequent updates that are not handled by an application (e.g. mouse move events).
	**/
	public function muteType(x:Int)
	{
		_blacklist |= x;
	}
	
	/**
		Removes the update type `x` from a blacklist of disabled updates, see `mute()`.
	**/
	public function unmuteType(x:Int)
	{
		_blacklist = _blacklist & ~x;
	}
	
	/**
		Returns true if `o` is registered with this object.
	**/
	public function contains(o:IObserver):Bool
	{
		var n = mObserverList;
		while (n != null)
		{
			if (n.observer == o) return true;
			n = n.next;
		}
		return false;
	}
	
	/**
		Returns an unordered list of all registered observers.
	**/
	public function getObserverList():Array<IObserver>
	{
		var v = new Array<IObserver>();
		var n = mObserverList;
		while (n != null)
		{
			v.push(n.observer);
			n = n.next;
		}
		return v;
	}
	
	/**
		Returns a new `ObservableIterator` object to iterate over all registered observers.
		@see <a href="http://haxe.org/ref/iterators" target="_blank">http://haxe.org/ref/iterators</a>
	**/
	public function iterator():Iterator<IObserver>
	{
		return new ObservableIterator<IObserver>(mObserverList);
	}
	
	inline function getEventId(type:Int):Int
	{
		return ObserverMacro.EVENT_MASK;
	}
	
	inline function getGroupid(type:Int):Int
	{
		return ObserverMacro.NUM_EVENT_BITS;
	}
	
	function _notify(type:Int, userData:Dynamic = null)
	{
		if (mObserverCount == 0 || (type & _blacklist) == type) //_blackList > 0?
			return; //early out
		
		var eventBits = type & ObserverMacro.EVENT_MASK;
		var groupId = type >>> ObserverMacro.NUM_EVENT_BITS;
		
		//when an observer calls notify() while an update is in progress, the current update stops
		//while the new update is carried out to all observers, e.g.:
		//we have 3 observers A,B and C - when B invokes an update the update order is [A, B, [A, B, C], C]
		if (_updating) //update still running?
		{
			//stop update and store state so it can be resumed later on
			_stack[_stackSize++] = mHook;
			_stack[_stackSize++] = _type;
			_stack[_stackSize++] = _userData;
			
			_type = type;
			_userData = userData;
			
			_update(mObserverList, type, eventBits, groupId, userData);
		}
		else
		{
			_updating = true;
			_type = type;
			_userData = userData;
			
			_update(mObserverList, type, eventBits, groupId, userData);
			
			if (_stack == null) //free() was called?
			{
				mHook = null;
				mObserverList = null;
				return;
			}
			
			if (_stackSize > 0)
			{
				while (_stackSize > 0)
				{
					//restore state
					userData = _stack[--_stackSize];
					type     = _stack[--_stackSize];
					eventBits = type & ObserverMacro.EVENT_MASK;
					groupId  = type >>> ObserverMacro.NUM_EVENT_BITS;
					
					//resume update
					_update(_stack[--_stackSize], type, eventBits, groupId, userData);
				}
			}
			
			_updating = false;
			mHook = null;
		}
	}
	
	inline function _update(node:ObserverNode, type:Int, eventBits:Int, groupId:Int, userData:Dynamic)
	{
		//update all observers
		while (node != null)
		{
			//preserve reference to next node so a detach() doesn't break an update
			mHook = node.next;
			if (node.all || node.mask[groupId] & eventBits > 0) //observer is suited for this update?
				node.observer.onUpdate(type, _source, userData); //update
			node = mHook;
		}
	}
}

@:publicFields
class ObserverNode
{
	var observer:IObserver;
	var prev:ObserverNode;
	var next:ObserverNode;
	var groupBits:Int;
	
	var all:Bool;
	
	var mask:Vector<Int>;
	
	public function new()
	{
		observer = null;
		prev = null;
		next = null;
		groupBits = 0;
		all = false;
		var k = 1 << ObserverMacro.NUM_GROUP_BITS;
		mask = new Vector<Int>(k);
		for (i in 0...k) mask[i] = 0;
	}
}

private class ObservableIterator<T>
{
	var _walker:ObserverNode;
	
	public function new(head:ObserverNode)
	{
		_walker = head;
	}
	
	public function hasNext():Bool
	{
		return _walker != null;
	}

	public function next():IObserver
	{
		var val = _walker.observer;
		_walker = _walker.next;
		return val;
	}
}

private class Bind implements IObserver
{
	static var _pool:DynamicObjectPool<Bind>;
	public static function get(f:Int->Dynamic->Bool, mask:Int):Bind
	{
		if (_pool == null)
			_pool = new DynamicObjectPool<Bind>(Bind, null, null, 1024);
		
		#if verbose
		if (_pool.capacity() == _pool.size())
			L.d("observable bind pool exhausted");
		#end
		
		var o = _pool.get();
		o._f = f;
		o._g = mask & ObserverMacro.GROUP_MASK;
		o._t = mask & ObserverMacro.EVENT_MASK;
		return o;
	}
	
	var _f:Int->Dynamic->Bool;
	var _g:Int;
	var _t:Int;
	
	public function onUpdate(type:Int, source:IObservable, userData:Dynamic)
	{
		if (_t != 0)
		{
			if (_g != (type & ObserverMacro.GROUP_MASK)) return;
			if (_t & (type & ObserverMacro.EVENT_MASK) == 0) return;
		}
		
		if (_f(type, userData)) return;
		
		_t &= ~(type & ObserverMacro.EVENT_MASK);
		source.detach(this, type);
		if (_t != 0) return;
		
		_f = null;
		_pool.put(this);
		
		#if verbose
		L.d("returning observable bind object");
		#end
		
		if (_pool.used() == 0)
		{
			#if verbose
			L.d("reclaiming observable bind pool");
			#end
			_pool.reclaim();
		}
	}
}

private class Delegate implements IObserver
{
	static var _pool:DynamicObjectPool<Delegate>;
	public static function get(f:Int->IObservable->Dynamic->Bool):Delegate
	{
		if (_pool == null) _pool = new DynamicObjectPool<Delegate>(Delegate, null, null, 256);
		
		#if verbose
		if (_pool.capacity() == _pool.size())
			L.d("observable delegate pool exhausted");
		#end
		
		var o = _pool.get();
		o._f = f;
		return o;
	}
	
	var _f:Int->IObservable->Dynamic->Bool;
	
	public function onUpdate(type:Int, source:IObservable, userData:Dynamic)
	{
		if (_f(type, source, userData)) return;
		
		source.detach(this);
		_f = null;
		_pool.put(this);
		
		#if verbose
		L.d("returning observable delegate object");
		#end
		
		if (_pool.used() == 0)
		{
			#if verbose
			L.d("reclaiming observable delegate pool");
			#end
			_pool.reclaim();
		}
	}
}