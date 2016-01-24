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

import de.polygonal.core.activity.Activity.ActivityState;
import de.polygonal.core.es.Entity;
import de.polygonal.core.es.EntitySystem;
import de.polygonal.core.time.Delay;
import de.polygonal.core.util.Assert.assert;
import de.polygonal.ds.Da;

/**
	Manages a stack of Activity objects.
	
	- Finishing an activity that has no parent will result in a blank screen (activity stack is empty).
	- Finishing an activity will also finish all child activities.
	- Finishing an activity is only allowed while the activity is in the "Created", "Stopped" or "Running" state.
	- Starting a child activity is only allowed while the activity is in the "Running" state.
**/
@:access(de.polygonal.core.activity.Activity)
class ActivityManager extends Entity
{
	var mActivityInstances = new Da<Activity>();
	
	var mTop:Activity;
	var mRoot:Activity;
	
	var transition(default, null):Transition;
	
	public function defineTransitionEffect(from:Class<Activity>, to:Class<Activity>, effect:TransitionListener)
	{
		transition.register(from, to, effect);
	}
	
	public function defineTransitionEffectToAndFrom(activity:Class<Activity>, effect:TransitionListener)
	{
		defineTransitionEffect(activity, null, effect);
		defineTransitionEffect(null, activity, effect);
	}
	
	inline public function getRootActivity():Activity return mRoot;
	
	inline public function getTopActivity():Activity return mTop;
	
	function new()
	{
		super(true);
		
		transition = add(Transition);
		
		L.d("ActivityManager initialized.", "activity");
	}
	
	/**
		Start a root activity; a root activity has neither a caller nor a parent activity.
		
		<assert>a non-child activity has to be full size</assert>
	**/
	public function startRootActivity(cl:Class<Activity>, ?extras:Dynamic)
	{
		start(null, cl, false, extras);
	}
	
	public function destroyAll()
	{
		var e = mTop;
		
		inline function stop(x:Activity)
		{
			switch (x.state)
			{
				case Running:
					x.onPause();
					x.onStop();
				
				case Paused:
					x.onStop();
				
				case _:
			}
		}
		
		while (!e.isRootActivity())
		{
			stop(e);
			var parent = e.parent;
			e.remove();
			destroy(e);
			e = cast parent;
		}
		
		stop(e);
		e.remove();
		destroy(e);
		
		mTop = null;
	}
	
	/**
		Destroys `activity` including all children.
		
		- the life cycle methods `onPause()`, `onStop()` are called in a top-down manner (where top is the running activity), but with no transition effect.
	**/
	public function destroy(activity:Activity)
	{
		if (mActivityInstances.remove(activity))
		{
			inline function stop(x:Activity)
			{
				switch (x.state)
				{
					case Running:
						x.onPause();
						x.onStop();
					
					case Paused:
						x.onStop();
					
					case _:
				}
			}
			
			var e = activity;
			var children = [];
			
			while (e.firstChild != null)
			{
				e = e.getChildActivity();
				children.push(e);
			}
			
			while (children.length > 0)
			{
				var e = children.pop();
				stop(e);
				e.remove();
				e.free();
			}
			
			stop(activity);
			activity.remove();
			activity.free();
			if (mTop == activity) mTop = null;
		}
	}
	
	function start(caller:Activity, cl:Class<Activity>, asChild:Bool, ?extras:Dynamic)
	{
		//find or create new activity instance
		var instanceCreated = false;
		var newActivity = Lambda.filter(mActivityInstances, function(e) return Type.getClass(e) == cl).first();
		if (newActivity == null)
		{
			newActivity = Type.createInstance(cl, []);
			if (newActivity.isPersistent())
				mActivityInstances.pushBack(newActivity);
			instanceCreated = true;
		}
		
		newActivity.mIntent = new Intent(caller, extras);
		newActivity.mIntent.isChild = asChild;
		
		//None -> Created
		if (instanceCreated) newActivity.onCreate(); 
		
		if (newActivity.isDecisionMaking()) mActivityInstances.remove(newActivity);
		
		#if debug
		if (!asChild) assert(newActivity.isFullSize(), "a root activity has to cover the entire screen");
		#end
		
		function pauseActivitiesAboveIncluding(x:Activity)
		{
			var p:Entity = x;
			while (p != null && p.is(Activity))
			{
				var a = p.as(Activity);
				if (a.state == ActivityState.Running) a.onPause();
				if (p.parent == newActivity) break;
				p = p.parent;
			}
		}
		
		function stopActivitiesAboveIncluding(x:Activity)
		{
			var p:Entity = x;
			while (p != null && p.is(Activity))
			{
				var a = p.as(Activity);
				if (a.state == ActivityState.Running) a.onPause();
				if (a.state == ActivityState.Paused) a.onStop();
				if (a.isRootActivity()) break;
				p = p.parent;
			}
		}
		
		if (!instanceCreated && newActivity.parent != null)
		{
			//restart existing activity?
			pauseActivitiesAboveIncluding(mTop);
			
			var a = newActivity.getChildActivity();
			var b = newActivity;
			mTop = newActivity;
			transition.pop(a, b);
			return;
		}
		
		if (asChild)
		{
			assert(mTop != null);
			
			mTop.onPause();
			mTop.add(newActivity);
			
			var top = mTop;
			var runTransition = transition.push.bind(top, newActivity);
			
			mTop = newActivity;
			newActivity.onStart(); //Created -> Started
			runTransition();
		}
		else
		{
			var top = mTop;
			
			var runTransition =
			if (top != null)
			{
				pauseActivitiesAboveIncluding(top);
				mTop = newActivity;
				transition.change.bind(top, newActivity);
			}
			else
			{
				mTop = mRoot = newActivity;
				transition.push.bind(null, newActivity);
			}
			
			add(newActivity);
			
			newActivity.onStart(); //Created -> Started
			runTransition();
		}
	}
	
	function finish(activity:Activity, ?extras:Dynamic)
	{
		if (activity.state == ActivityState.Created) //finish() called inside onCreate()?
		{
			activity.free(); 
			return;
		}
		
		assert(activity == mTop, "only the running activity (the topmost, visible activity) can be finished");
		assert(activity.parent != null);
		
		if (activity.isChildActivity())
		{
			mTop = activity.parent.as(Activity);
			
			activity.onPause();
			
			//restart parent activity
			mTop.mIntent = new Intent(activity, extras);
			
			if (mTop.state == ActivityState.Stopped)
			{
				//also restart parent activities if mTop is not full-sized
				if (!mTop.isFullSize()) //has to be a child activity
				{
					var p = mTop;
					do
					{
						p = cast p.parent;
						
						p.mIntent = new Intent(null, {});
						
						p.onRestart();
						p.onStart();
						p.onResume();
						p.onPause();
					}
					while (!p.isRootActivity() && !p.isFullSize());
				}
				
				mTop.onRestart();
				mTop.onStart();
			}
			
			transition.pop(activity, mTop);
		}
		else
		{
			activity.onPause();
			
			transition.pop(activity, null);
		}
	}
}