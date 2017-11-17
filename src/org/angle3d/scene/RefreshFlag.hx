package org.angle3d.scene;

/**
 * Refresh flag types
 */
@:enum abstract RefreshFlag(Int) {
	var NONE = 0;
	var RF_TRANSFORM       = value(0);// need light resort + combine transforms
	var RF_BOUND           = value(1);
	var RF_LIGHTLIST       = value(2);// changes in light lists
	var RF_CHILD_LIGHTLIST = value(3);// some child need geometry update
	var RF_MATPARAM_OVERRIDE = value(4);

	static inline function value(index:Int) return 1 << index;

	inline public function new(v:Int)
	this = v;

	inline public function toInt():Int
	return this;

	inline public function remove(mask:RefreshFlag):RefreshFlag {
		return new RefreshFlag(this & ~mask.toInt());
	}

	inline public function add(mask:RefreshFlag):RefreshFlag {
		return new RefreshFlag(this | mask.toInt());
	}

	inline public function contains(mask:RefreshFlag):Bool {
		return this & mask.toInt() != 0;
	}
}