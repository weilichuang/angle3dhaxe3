package angle3d.utils;

class ArrayUtil {
	@:generic
	public static function clear<T>(arr:Array<T>):Void {
		#if cpp
		untyped arr.__SetSize(0);
		#elseif js
		untyped arr.length = 0;
		#else
		arr.splice(0, arr.length);
		#end
	}

	public static inline function contains<T>(list:Array<T>, item:T):Bool {
		return list.indexOf(item) != -1;
	}

	public static function containsAll<T>(list:Array<T>, list1:Array<T>):Bool {
		if (list.length == 0 || list1.length == 0)
			return true;

		for (i in 0...list1.length) {
			if (list.indexOf(list1[i]) == -1) {
				return false;
			}
		}

		return true;
	}
}