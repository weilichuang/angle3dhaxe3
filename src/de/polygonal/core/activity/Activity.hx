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
import de.polygonal.core.util.Assert.assert;
import de.polygonal.core.util.ClassUtil;

enum ActivityState
{
	None;
	Created;
	Started;
	Running;
	Restarted;
	Paused;
	Stopped;
	Destroyed;
}

/**
	An Activity is an object that provides a screen with which users can interact.
	
	Inspired by [Managing the Activity Lifecycle](http://developer.android.com/guide/components/activities.html)
	
	Note:
	
	- An activity never resides in the "Created", "Started" or "Restarted" states.
	- New activities are placed at the top of the activity stack.
**/
@:access(de.polygonal.core.activity.ActivityManager)
class Activity extends Entity
{
	/**
		The current state of this activity.
	**/
	public var state(default, null):ActivityState;
	
	/**
		True if this activity covers the entire screen and thus is able to hide all activities below it.
		
		Default is true.
	**/
	public function isFullSize():Bool return true;
	
	public function isPersistent():Bool return true;
	
	public function isDecisionMaking():Bool return false;
	
	var mIntent:Intent;
	
	function new() 
	{
		super(ClassUtil.getUnqualifiedClassName(this));
		state = ActivityState.None;
		mIntent = new Intent(null, {});
	}
	
	/**
		Spawns a new activity embedded inside this activity.
		
		<assert>starting an activity is only allowed while in the "Running" state</assert>
	**/
	function startChildActivity(cl:Class<Activity>, ?extras:Dynamic)
	{
		assert(state == ActivityState.Running, "starting an activity is only allowed while in the \"Running\" state");
		
		lookup(ActivityManager).start(this, cl, true, extras);
	}
	
	/**
		Stops all activities in the current activity stack before spawning a new activity.
	**/
	function startActivity(cl:Class<Activity>, ?extras:Dynamic)
	{
		lookup(ActivityManager).start(this, cl, false, extras);
	}
	
	/**
		Stops this activity.
	**/
	@:access(de.polygonal.core.activity.ActivityManager)
	function finish(?extras:Dynamic)
	{
		assert(state == ActivityState.Running, "finishing an activity is only allowed while in the \"Running\" state");
		
		lookup(ActivityManager).finish(this, extras);
	}
	
	/**
		Returns true if this activity is embedded inside another activity.
	**/
	public function isChildActivity():Bool
	{
		return parent != null && parent.is(Activity);
	}
	
	/**
		Returns true if this activity is a root activity.
	**/
	public function isRootActivity():Bool
	{
		return parent != null && !parent.is(Activity);
	}
	
	public function getChildActivity():Activity
	{
		var c = firstChild;
		while (c != null)
		{
			if (c.is(Activity)) return cast c;
			c = c.sibling;
		}
		
		return null;
	}
	
	/**
		The intent of the calling activity.
	**/
	public function getIntent():Intent
	{
		return mIntent;
	}
	
	/**
		Implement this method to perform basic startup logic that should happen __only once__ for the entire lifetime of this activity.
		
		After `onCreate()` the system calls `onStart()` which is then followed by `onResume()`.
	**/
	@:dox(show)
	function onCreate()
	{
		assert(state == ActivityState.None);

		changeState(ActivityState.Created);
	}
	
	/**
		If the user returns to this activity while it's in the stopped state, the system restarts this activity by calling `onRestart()``.
	**/
	@:dox(show)
	function onRestart()
	{
		assert(state == ActivityState.Stopped);
		
		changeState(ActivityState.Restarted);
	}
	
	/**
		The system calls `onStart()` every time this activity becomes visible (either being restarted or created for the first time).
	**/
	@:dox(show)
	function onStart()
	{
		assert(state == ActivityState.Created || state == ActivityState.Stopped || state == ActivityState.Restarted);
		
		changeState(ActivityState.Started);
		passable = true;
	}
	
	/**
		The activity is in the foreground and the user can interact with it.
		
		Called after `onRestart()` or `onPause()`; the activity can now interact with the user.
		
		Implement `onResume()` to initialize components that have been released in `onPause()` and are only used while the activity has user focus.
	**/
	@:dox(show)
	function onResume()
	{
		assert(state == ActivityState.Started || state == ActivityState.Paused);
		
		changeState(ActivityState.Running);
	}
	
	/**
		This activity is partially obscured by another activity (another activity in the foreground is
		semi-transparent or doesn't cover the entire screen.)
		
		The paused activity does __not receive user input__, but otherwise can execute code.
	**/
	@:dox(show)
	function onPause()
	{
		assert(state == ActivityState.Running, Std.string(state));
		
		changeState(ActivityState.Paused);
	}
	
	/**
		The activity is completely hidden and not visible to the user.
		
		While stopped, the activity instance is kept alive in the background, but it __cannot execute__ any code.
		
		When the user leaves this activity by starting another activity, the system calls `onStop()` to stop this activity,
		allowing you to specify the behavior while being stopped.
	**/
	@:dox(show)
	function onStop()
	{
		assert(state == ActivityState.Paused);
		
		changeState(ActivityState.Stopped);
	}
	
	function onDestroy() {}
	
	/**
		The system destroyed this activity in order to free memory.
		
		Called after `onPause()` and `onStop()`.
	**/
	override function onFree()
	{
		assert(state == ActivityState.None || state == ActivityState.Created || state == ActivityState.Stopped);
		
		if (state != ActivityState.None)
		{
			changeState(ActivityState.Destroyed);
			onDestroy();
		}
	}
	
	override public function toString():String
	{
		return '{Activity $name; state=$state fullSize=${isFullSize()}}';
	}
	
	function changeState(newState:ActivityState)
	{
		assert(newState != null);
		
		#if verbose
		L.d('$name: $state -> $newState', "activity");
		#end
		state = newState;
	}
}