package org.angle3d.cinematic;

import org.angle3d.cinematic.events.CinematicEvent;

class KeyFrame {
	public var cinematicEvents:Array<CinematicEvent>;
	private var index:Int;

	public function new() {
		cinematicEvents = new Array<CinematicEvent>();
	}

	public function isEmpty():Bool {
		return cinematicEvents.length == 0;
	}

	public function trigger():Array<CinematicEvent> {
		for (i in 0...cinematicEvents.length) {
			cinematicEvents[i].play();
		}
		return cinematicEvents;
	}

	public function getCinematicEvents():Array<CinematicEvent> {
		return cinematicEvents;
	}

	public function addCinematicEvent(cinematicEvent:CinematicEvent):Void {
		cinematicEvents.push(cinematicEvent);
	}

	public function setCinematicEvents(cinematicEvents:Array<CinematicEvent>):Void {
		this.cinematicEvents = cinematicEvents;
	}

	public function getIndex():Int {
		return index;
	}

	public function setIndex(index:Int):Void {
		this.index = index;
	}
}

