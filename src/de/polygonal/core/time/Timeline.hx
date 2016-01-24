/*
Copyright (c) 2014 Michael Baczynski, http://www.polygonal.de

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
package de.polygonal.core.time;

import de.polygonal.core.math.Mathematics.M;
import de.polygonal.core.util.Assert.assert;
import de.polygonal.ds.ArrayedQueue;
import de.polygonal.ds.Cloneable;
import de.polygonal.ds.Dll;
import de.polygonal.ds.Heap;
import de.polygonal.ds.Heapable;
import de.polygonal.ds.IntHashTable;
import de.polygonal.ds.pooling.ObjectPool;

/**
	A service that can schedule time intervals to run after a given delay for a given amount of time, or periodically.
	A time interval represents a period of time between two instants.
**/
@:allow(de.polygonal.core.time)
@:access(de.polygonal.core.time.TimelineListener)
class Timeline
{
	public static var DEFAULT_POOL_SIZE = 4096;
	
	static var mInitialized = false;
	static var mNextId:Int;
	static var mNextTick:Int;
	
	static var mBufferedIntervals:ArrayedQueue<TimelineNode>;
	static var mActiveIntervals:Dll<TimelineNode>;
	static var mPendingIntervals:Heap<TimelineNode>;
	static var mIntervalLut:IntHashTable<TimelineNode>;
	
	static var mNodePool:ObjectPool<TimelineNode>;
	
	public static function init()
	{
		if (mInitialized) return;
		mInitialized = true;
		
		Timebase.init();
		
		mNextId = 1;
		mNextTick = 1;
		
		mBufferedIntervals = new ArrayedQueue<TimelineNode>(4096);
		mActiveIntervals = new Dll<TimelineNode>();
		mPendingIntervals = new Heap<TimelineNode>();
		mIntervalLut = new IntHashTable<TimelineNode>(1 << 16);
		
		mNodePool = new ObjectPool<TimelineNode>(DEFAULT_POOL_SIZE);
		mNodePool.allocate(true, TimelineNode);
	}
	
	public static function free()
	{
		if (!mInitialized) return;
		mInitialized = false;
		
		mBufferedIntervals.free();
		mActiveIntervals.free();
		mPendingIntervals.free();
		mIntervalLut.free();
		
		mNodePool.free();
		
		mBufferedIntervals = null;
		mActiveIntervals = null;
		mPendingIntervals = null;
		mIntervalLut = null;
		mNodePool = null;
	}
	
	/**
		Schedules an event to run after `delay` seconds, for a period of `duration` seconds.
		
		Returns an unique id that identifies the event. This id can be used to cancel a pending/running time interval or instant by calling `Timeline.cancel(id)`.
		
		- if `repeatCount` > 0, the event repeats `repeatCount` times, each time waiting for `repeatInterval` seconds before the event is carried out again.
		- if `repeatCount` > 0 and `repeatInterval` is omitted, `delay` is used in place of `repeatInterval`.
		- if `repeatCount` == -1 the event runs periodically until cancelled.
	**/
	public static function schedule(listener:TimelineListener = null, duration:Float, delay:Float = 0, repeatCount:Int = 0, repeatInterval:Float = 0):Int
	{
		assert(duration >= 0);
		assert(delay >= 0);
		assert(repeatCount >= 0 || repeatCount == -1);
		assert(repeatInterval >= 0);
		
		#if debug
		if (repeatCount > 0 && repeatInterval == 0) assert(delay > 0);
		#end
		
		if (!mInitialized) init();
		
		if (repeatCount != 0 && repeatInterval == 0)
			repeatInterval = delay; //use delay as interval
			
		var id = mNextId++;
		
		var node:TimelineNode;
		
		if (mNodePool.isEmpty())
		{
			L.w("pool exhausted");
			node = new TimelineNode();
		}
		else
		{
			var poolId = mNodePool.next();
			node = mNodePool.get(poolId);
			node.poolId = poolId;
		}
		
		var now = Timebase.elapsedTime;
		
		node.id = id;
		node.duration = duration;
		node.delay = delay;
		node.repeatCount = repeatCount;
		node.repeatInterval = repeatInterval;
		node.timeStart = now + delay;
		node.timeFinish = node.timeStart + duration;
		
		node.iteration = 0;
		node.listener = listener;
		
		mBufferedIntervals.enqueue(node);
		mIntervalLut.set(node.id, node);
		
		return id;
	}
	
	/**
		Cancels or aborts a pending or running time interval.
		Returns true if the time interval was successfully cancelled.
	**/
	public static function cancel(id:Int):Bool
	{
		if (!mInitialized) return false;
		if (id < 0) return false;
		
		var node = mIntervalLut.get(id);
		if (node != null)
		{
			node.cancel();
			mIntervalLut.clr(id);
			return true;
		}
		
		return false;
	}
	
	/**
		Cancels all pending running time intervals.
	**/
	public static function cancelAll()
	{
		if (!mInitialized) return;
		
		for (i in mIntervalLut) i.cancel();
		mIntervalLut.clear();
		mBufferedIntervals.clear();
		mActiveIntervals.clear();
		mPendingIntervals.clear();
	}
	
	/**
		Updates the timeline. Should be called once every game tick.
	**/
	public static function update()
	{
		if (!mInitialized) return;
		
		var now = Timebase.elapsedTime;
		
		var h = mPendingIntervals, l = mActiveIntervals, q = mBufferedIntervals, n;
		
		inline function reuse(x:TimelineNode)
		{
			if (x.poolId != -1)
			{
				x.listener = null;
				mNodePool.put(x.poolId);
			}
		}
		
		var lut = mIntervalLut;
		inline function unregister(x:TimelineNode) lut.clr(x.id);
		
		//handle buffered intervals
		mNextTick = 1;
		while (!q.isEmpty())
		{
			n = q.dequeue();
			if (n.isCancelled()) continue;
			n.tick = mNextTick++;
			h.add(n);
		}
		
		//handle pending intervals
		while (true)
		{
			if (h.isEmpty()) break;
			
			var top = h.top();
			
			if (top.isCancelled())
			{
				h.pop();
				top.onCancel();
				reuse(top);
				unregister(top);
				continue;
			}
			
			if (top.isReady(now))
			{
				h.pop();
				
				if (top.isInstant())
				{
					top.onInstant();
					if (top.isRepeatable())
					{
						top.respawn();
						q.enqueue(top);
					}
					else
					{
						reuse(top);
						unregister(top);
					}
				}
				else
				{
					top.progress = 0;
					top.onStart();
					top.onProgress();
					l.append(top);
				}
				continue;
			}
			
			break;
		}
		
		//handle running time intervals
		var walker = l.head;
		while (walker != null)
		{
			n = walker.val;
			
			if (n.isCancelled())
			{
				walker = walker.unlink();
				n.onCancel();
				reuse(n);
				unregister(n);
				continue;
			}
			
			n.progress = M.fclamp((now - n.timeStart) / n.duration, 0, 1);
			n.onProgress();
			
			if (n.isFinished(now))
			{
				walker = walker.unlink();
				n.onFinish();
				if (n.isRepeatable())
				{
					n.respawn();
					q.enqueue(n);
				}
				else
				{
					reuse(n);
					unregister(n);
				}
			}
			else
				walker = walker.next;
		}
	}
}

@:publicFields
@:access(de.polygonal.core.time.TimelineListener)
private class TimelineNode implements Heapable<TimelineNode> implements Cloneable<TimelineNode>
{
	var timeStart:Float;
	var timeFinish:Float;
	var delay:Float;
	var duration:Float;
	var repeatInterval:Float;
	var progress:Float;
	
	var tick:Int;
	var repeatCount:Int;
	var iteration:Int;
	
	var id:Int;
	var poolId:Int = -1;
	var position:Int;
	
	var listener:TimelineListener;
	
	function new() {}
	
	inline function isInstant():Bool return timeStart == timeFinish;
	
	inline function isCancelled():Bool return timeStart < 0;
	
	inline function isReady(now:Float) return timeStart <= now;
	
	inline function isFinished(now:Float):Bool return timeFinish <= now;
	
	inline function isRepeatable():Bool return repeatCount != 0;
	
	inline function cancel() timeStart = -1;
	
	inline function respawn()
	{
		timeStart = timeFinish + repeatInterval;
		timeFinish = timeStart + duration;
		if (isRepeatable())
		{
			repeatCount--;
			iteration++;
		}
	}
	
	inline function onInstant() listener.onInstant(id, iteration);
	
	inline function onStart() listener.onStart(id, iteration);
	
	inline function onProgress() listener.onProgress(progress);
	
	inline function onFinish() listener.onFinish(id, iteration);
	
	inline function onCancel() listener.onCancel(id);
	
	function compare(other:TimelineNode):Int
	{
		var dt = other.timeStart - timeStart;
		return dt > 0 ? 1 : (dt < 0 ? -1 : other.tick - tick);
	}
	
	function clone():TimelineNode
	{
		var n = new TimelineNode();
		n.timeStart = timeStart;
		n.timeFinish = timeFinish;
		n.delay = delay;
		n.duration = duration;
		n.repeatInterval = repeatInterval;
		n.progress = progress;
		n.tick = tick;
		n.repeatCount = repeatCount;
		n.iteration = iteration;
		n.id = id;
		return n;
	}
	
	function toString():String
	{
		var s = "";
		if (repeatCount == -1)
			s = "repeat=inf";
		else
		if (repeatCount > 0)
			s = 'repeat=$repeatCount';
		
		return
		if (isInstant())
			return Printf.format('{Instant id=$id[$tick] time=%.2f$s}', [timeStart]);
		else
			return Printf.format('{Period id=$id[$tick] start=%.2f finish=%.2f progress=%.2f$s}', [timeStart, timeFinish, progress]);
	}
}