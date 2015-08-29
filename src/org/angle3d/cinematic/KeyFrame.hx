package org.angle3d.cinematic;

import flash.Vector;
import org.angle3d.cinematic.events.CinematicEvent;

class KeyFrame
{
	public var cinematicEvents:Vector<CinematicEvent>;
	private var index:Int;

	public function new()
	{
		cinematicEvents = new Vector<CinematicEvent>();
	}

	public function isEmpty():Bool
	{
		return cinematicEvents.length == 0;
	}

	public function trigger():Vector<CinematicEvent>
	{
		for (i in 0...cinematicEvents.length)
		{
			cinematicEvents[i].play();
		}
		return cinematicEvents;
	}

	public function getCinematicEvents():Vector<CinematicEvent>
	{
		return cinematicEvents;
	}

	public function addCinematicEvent(cinematicEvent:CinematicEvent):Void
	{
		cinematicEvents.push(cinematicEvent);
	}

	public function setCinematicEvents(cinematicEvents:Vector<CinematicEvent>):Void
	{
		this.cinematicEvents = cinematicEvents;
	}

	public function getIndex():Int
	{
		return index;
	}

	public function setIndex(index:Int):Void
	{
		this.index = index;
	}
}

