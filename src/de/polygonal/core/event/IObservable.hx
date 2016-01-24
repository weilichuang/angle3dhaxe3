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

/**
 * An object with state that is observed by `IObserver` objects.
 * `IObserver` objects are updated whenever the state of an `IObservable` object changes.
 * An update (the terms event and update are used interchangeable) is identified by a 32-bit integer.
 * Related updates, such as a bunch of events fired by a loader class describing different states of the loading progress, are grouped together into an update group.
 * This has the advantage that an `IObserver` object has to only register once with an `IObservable` object to get different updates, clearly reducing boilerplate code.
 * As a consequence, the integer describing the update is annotated with an extra group id that uniquely identifies the source of the update:
 * the most significant bits (5 bits by default, see `Observable.NUM_GROUP_BITS`) are reserved for this purpose; the remaining bits hold the update type in form of a bit flag.
 * It is therefore possible to store a total of 2^`Observable.NUM_GROUP_BITS` - 1 groups, and each group can define a total of 32 - `Observable.NUM_GROUP_BITS` unique events.
 * See <a href="http://en.wikipedia.org/wiki/Observer_pattern" target="_blank">http://en.wikipedia.org/wiki/Observer_pattern</a>.
**/
interface IObservable
{
	/**
		Registers `o` with an `IObservable` object so `o` is updated when calling `notify()`.
		@param o the observer to register with.
		@param mask a bit field of bit flags defining which event types to register with.
		This can be used to select a subset of events from an event group.
		By default, `o` receives all updates from an event group.
	**/
	function attach(o:IObserver, mask:Int = 0):Void;
	
	/**
		Unregisters `o` from an `IObservable` object so `o` is no longer updated when calling `notify()`.
		@param o the observer to unregister from.
		@param mask a bit field of bit flags defining which event types to unregister from.
		This can be used to select a subset of events from an event group.
		By default, `o` is unregistered from the entire event group.
	**/
	function detach(o:IObserver, mask:Int = 0):Void;
	
	/**
		Notifies all attached observers to indicate that the state of an `IObservable` object has changed.
		@param type the event type.
		@param userData additional event data. Default value is null.
	**/
	function notify(type:Int, userData:Dynamic = null):Void;
}