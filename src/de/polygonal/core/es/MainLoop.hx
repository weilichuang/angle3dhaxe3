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
package de.polygonal.core.es;

import de.polygonal.core.es.Entity in E;
import de.polygonal.core.event.IObservable;
import de.polygonal.core.event.IObserver;
import de.polygonal.core.time.Timebase;
import de.polygonal.core.time.TimebaseEvent;
import de.polygonal.core.time.Timeline;
import haxe.ds.Vector;

using de.polygonal.core.es.EntitySystem;

/**
	The top entity responsible for updating the entire entity hierachy
**/
class MainLoop extends Entity implements IObserver
{
	public var paused = false;
	
	var mStack:Array<E> = [];
	var mPostFlag:Array<Bool> = [];
	var mTop:Int = 0;
	var mBufferedEntities:Vector<E>;
	var mMaxBufferSize:Int = 0;
	var mElapsedTime:Float = 0;
	
	public function new()
	{
		super(MainLoop.ENTITY_NAME, true);
		
		Timebase.init();
		Timebase.attach(this);
		Timeline.init();
		
		mBufferedEntities = new Vector<E>(EntitySystem.MAX_SUPPORTED_ENTITIES);
	}
	
	override function onFree()
	{
		Timebase.detach(this);
	}
	
	public function onUpdate(type:Int, source:IObservable, userData:Dynamic)
	{
		if (paused) return;
		
		if (type == TimebaseEvent.TICK)
		{
			//process scheduled events
			Timeline.update();
			
			//advance entities
			var dt:Float = userData;
			propagateTick(dt);
			
			//dispatch buffered messages
			EntitySystem.dispatchMessages();
			
			mElapsedTime += dt;
		}
		else
		if (type == TimebaseEvent.RENDER)
		{
			//draw all entities
			var alpha:Float = userData;
			propagateDraw(alpha);
			
			//prune scratch list for gc at regular intervals
			if (mElapsedTime > 3)
			{
				mElapsedTime = 0;
				var list = mBufferedEntities;
				for (i in 0...mMaxBufferSize) list[i] = null;
				mMaxBufferSize = 0;
			}
		}
	}
	
	function propagateTick(dt:Float)
	{
		var k = bufferEntities();
		var a = mBufferedEntities;
		var p = mPostFlag;
		var e;
		
		for (i in 0...k)
		{
			e = a[i];
			
			if (e.mBits & (E.BIT_SKIP_TICK | E.BIT_MARK_FREE | E.BIT_NO_PARENT) == 0)
				e.onTick(dt, p[i]);
		}
	}
	
	function propagateDraw(alpha:Float)
	{
		var k = bufferEntities();
		var a = mBufferedEntities;
		var p = mPostFlag;
		var e;
		
		for (i in 0...k)
		{
			e = a[i];
			
			if (e.mBits & (E.BIT_SKIP_DRAW | E.BIT_MARK_FREE | E.BIT_NO_PARENT) == 0)
				e.onDraw(alpha, p[i]);
		}
	}
	
	function bufferEntities():Int
	{
		var a = mBufferedEntities;
		var b = mStack;
		var c = mPostFlag;
		
		var k = 0, j = 0, t;
		
		var last:E = null;
		
		var e = firstChild;
		while (e != null)
		{
			if (e.mBits & E.BIT_SKIP_SUBTREE != 0)
			{
				e = e.nextSubtree();
				continue;
			}
			
			if (e.firstChild != null)
			{
				b[j++] = e;
				last = e.lastChild;
			}
			a[k] = e;
			c[k++] = false;
			if (j > 0 && last == e)
			{
				t = b[--j];
				a[k] = t;
				c[k++] = true;
			}
			
			e = e.preorder;
		}
		
		while (j > 0)
		{
			t = b[--j];
			a[k] = t;
			c[k++] = true;
		}
		
		if (k > mMaxBufferSize) mMaxBufferSize = k;
		
		return k;
	}
}