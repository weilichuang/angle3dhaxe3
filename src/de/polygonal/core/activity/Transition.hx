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
package de.polygonal.core.activity;

import de.polygonal.core.es.Entity;
import de.polygonal.core.time.Delay;
import de.polygonal.core.time.Interval;
import de.polygonal.core.util.ClassUtil;
import haxe.ds.StringMap;

@:enum
abstract TransitionType(Int)
{
    var Push = 1;
    var Pop = 2;
    var Change = 3;
}

//wait delay if activity needs preparation time

@:access(de.polygonal.core.activity.Activity)
@:access(de.polygonal.core.activity.ActivityManager)
class Transition extends Entity
{
	var mA:Activity;
	var mB:Activity;
	var mInterval:Interval = new Interval(1);
	var mListener:TransitionListener = null;
	var mType:TransitionType;
	var mTransitionLookup = new StringMap<TransitionListener>();
	var mPhase = 0;
	
	public function new() 
	{
		super();
	}
	
	public function register(from:Class<Activity>, to:Class<Activity>, effect:TransitionListener)
	{
		var a = from == null ? "*" : ClassUtil.getClassName(from);
		var b = to == null ? "*" : ClassUtil.getClassName(to);
		mTransitionLookup.set('$a-$b', effect);
	}
	
	/**
		Push `b` over `a`.
	**/
	public function push(a:Activity, b:Activity)
	{
		run(a, b, Push);
	}
	
	/**
		Pop `b` off `a`.
		
		- `b` can be null in case `a` has no parent activity.
	**/
	public function pop(a:Activity, b:Activity)
	{
		run(a, b, Pop);
	}
	
	/**
		Replace `a` (and all parent activities of `a`) with `b`.
	**/
	public function change(a:Activity, b:Activity)
	{
		run(a, b, Change);
	}
	
	function run(a:Activity, b:Activity, type:TransitionType)
	{
		mListener = resolveEffect(a, b);
		
		switch (type)
		{
			case Change, Push:
				if (b.isDecisionMaking())
					mListener = new NullTransition();
			
			case Pop:
				if (a.isDecisionMaking())
					mListener = new NullTransition();
		}
		
		if (mListener == null) mListener = new NullTransition();
		
		start(a, b, type);
	}
	
	function resolveEffect(a:Activity, b:Activity):TransitionListener
	{
		var nameA = a == null ? "null" : ClassUtil.getClassName(a);
		var nameB = ClassUtil.getClassName(b);
		
		var l:TransitionListener;
		
		inline function test(key:String):Bool
		{
			l = mTransitionLookup.get(key);
			return (l != null || mTransitionLookup.exists(key));
		}
		
		if (test('$nameA-$nameB')) return l;
		
		if (b != null)
		{
			var s = Type.getSuperClass(Type.getClass(b));
			while (s != null && s != Activity)
			{
				if (test('$nameA-${Type.getClassName(s)}')) return l;
				s = Type.getSuperClass(s);
			}
		}
		
		if (a != null)
		{
			var s = Type.getSuperClass(Type.getClass(a));
			while (s != null && s != Activity)
			{
				if (test('${Type.getClassName(s)}-$nameB')) return l;
				s = Type.getSuperClass(s);
			}
		}
		
		if (test('*-$nameB')) return l;
		if (test('$nameA-*')) return l;
		if (test('*-*')) return l;
		
		return null;
	}
	
	function start(a:Activity, b:Activity, type:TransitionType)
	{
		mA = a;
		mB = b;
		
		var sa = a == null ? "-" : a.name;
		var sb = b == null ? "-" : b.name;
		mListener.onStart(a, b, type);
		mType = type;
		mInterval.duration = mListener.getDuration(a, b, type);
		mPhase = 1;
	}
	
	function finish(a:Activity, b:Activity, type:TransitionType)
	{
		inline function stopAndRemove(x:Activity)
		{
			x.onStop();
			x.remove();
			if (!x.isPersistent()) x.free();
		}
		
		switch (type)
		{
			case Push:
				if (b.isFullSize() && a != null)
				{
					var above = getStackedActivitiesBelowIncluding(a);
					for (i in above)
						if (i.state == Paused)
							i.onStop();
				}
				b.onResume();
			
			case Pop:
				if (b == null)
				{
					//a has no parent
					stopAndRemove(a);
					return;
				}
				
				var above = getStackedActivitiesAboveIncluding(a);
				for (i in above) stopAndRemove(i);
				
				switch (b.state)
				{
					case Paused, Started:
						b.onResume();
					
					case Stopped:
						b.onRestart();
						b.onStart();
						b.onResume();
					
					case _:
				}
			
			case Change:
				//stop entire activity stack (all activities below a)
				var e:Activity = a;
				while (true)
				{
					var parent = e.parent;
					var isRoot = e.isRootActivity();
					stopAndRemove(e);
					if (isRoot) break;
					e = cast parent;
				}
				b.onResume();
		}
	}
	
	override function onTick(dt:Float, post:Bool)
	{
		switch (mPhase)
		{
			case 0:
			case 1:
				mListener.onProgress(mA, mB, mInterval.advance(dt), mType);
				if (mInterval.finished)
				{
					var sa = mA == null ? "-" : mA.name;
					var sb = mB == null ? "-" : mB.name;
					mListener.onFinish(mA, mB, mType);
					mPhase = 2;
				}
			
			case 3:
				mPhase = 0;
				var a = mA;
				var b = mB;
				mA = null;
				mB = null;
				finish(a, b, mType);
		}
	}
	
	override function onDraw(alpha:Float, post:Bool)
	{
		switch (mPhase)
		{
			case 2: mPhase = 3;
		}
	}
	
	function getStackedActivitiesBelowIncluding(e:Activity):Array<Activity>
	{
		var out = [];
		var p = e;
		while (!p.isRootActivity())
		{
			out.push(p);
			p = cast p.parent;
		}
		out.push(p);
		return out;
	}
	
	function getStackedActivitiesAboveIncluding(e:Activity):Array<Activity>
	{
		function findChildActivity(x:Entity):Activity
		{
			var a = null;
			var c = x.firstChild;
			while (c != null)
			{
				if (c.is(Activity))
				{
					a = cast c;
					break;
				}
				c = c.sibling;
			}
			return a;
		}
		
		var t = e;
		var c:Activity = null;
		while (t.firstChild != null) //can be null t
		{
			c = findChildActivity(t);
			
			trace('child activity of $t IS $c');
			
			if (c == null)
			{
				c = t;
				break;
			}
			
			t = c;
		}
		
		if (c == null) c = e; //TODO verify
		
		var out = [];
		var p = c;
		while (p != e)
		{
			out.push(p);
			p = cast p.parent;
		}
		
		out.push(e);
		return out;
	}
}