package angle3d.animation;

import angle3d.error.Assert;

import angle3d.math.Quaternion;
import angle3d.math.Vector3f;
import angle3d.scene.Spatial;

/**
 * This class represents the track for spatial animation.
 */
class SpatialTrack implements Track {
	/**
	 * Translations of the track.
	 */
	private var translations:Array<Float>;
	/**
	 * Rotations of the track.
	 */
	private var rotations:Array<Float>;
	/**
	 * Scales of the track.
	 */
	private var scales:Array<Float>;
	/**
	 * The times of the animations frames.
	 */
	private var times:Array<Float>;

	private var useTrans:Bool;
	private var useRotation:Bool;
	private var useScale:Bool;

	public function new(times:Array<Float>, translations:Array<Float> = null, rotations:Array<Float> = null, scales:Array<Float> = null) {
		setKeyframes(times, translations, rotations, scales);
	}

	/**
	 *
	 * Modify the spatial which this track modifies.
	 *
	 * @param time
	 *            the current time of the animation
	 * @param spatial
	 *            the spatial that should be animated with this track
	 */
	private static var tempV:Vector3f = new Vector3f();
	private static var tempS:Vector3f = new Vector3f();
	private static var tempQ:Quaternion = new Quaternion();
	private static var tempV2:Vector3f = new Vector3f();
	private static var tempS2:Vector3f = new Vector3f();
	private static var tempQ2:Quaternion = new Quaternion();
	public function setTime(time:Float, weight:Float, control:AnimControl, channel:AnimChannel):Void {
		var lastFrame:Int = times.length - 1;
		if (lastFrame == 0 || time < 0) {
			if (useRotation)
				getRotation(0, tempQ);
			if (useTrans)
				getTranslation(0, tempV);
			if (useScale)
				getScale(0, tempS);
		} else if (time >= times[lastFrame]) {
			if (useRotation)
				getRotation(lastFrame, tempQ);
			if (useTrans)
				getTranslation(lastFrame, tempV);
			if (useScale)
				getScale(lastFrame, tempS);
		} else
		{
			var startFrame:Int = 0;
			var endFrame:Int = 1;
			// use lastFrame so we never overflow the array
			var i:Int = 0;
			while (i < lastFrame && times[i] < time) {
				startFrame = i;
				endFrame = i + 1;
				i++;
			}

			var totalTime:Float = (times[endFrame] - times[startFrame]);
			var blend:Float = (time - times[startFrame]) / totalTime;

			if (totalTime == 0 || blend == 0) {
				if (useRotation) {
					getRotation(startFrame, tempQ);
				}
				if (useTrans) {
					getTranslation(startFrame, tempV);
				}
				if (useScale) {
					getScale(startFrame, tempS);
				}
			} else
			{
				if (useRotation) {
					getRotation(startFrame, tempQ);
					getRotation(endFrame, tempQ2);
				}
				if (useTrans) {
					getTranslation(startFrame, tempV);
					getTranslation(endFrame, tempV2);
				}
				if (useScale) {
					getScale(startFrame, tempS);
					getScale(endFrame, tempS2);
				}

				tempQ.slerp(tempQ, tempQ2, blend);
				tempV.lerp(tempV, tempV2, blend);
				tempS.lerp(tempS, tempS2, blend);
			}
		}

		var spatial:Spatial = control.getSpatial();
		if (useTrans)
			spatial.localTranslation = tempV;

		if (useRotation)
			spatial.setLocalRotation(tempQ);

		if (useScale)
			spatial.setLocalScale(tempS);
	}

	/**
	 * set_the translations and rotations for this bone track
	 * @param times a float array with the time of each frame
	 * @param translations the translation of the bone for each frame
	 * @param rotations the rotation of the bone for each frame
	 */
	public function setKeyframes(times:Array<Float>, translations:Array<Float>, rotations:Array<Float>, scales:Array<Float> = null):Void {
		Assert.assert(times.length > 0, "SpatialTrack with no keyframes!");

		this.times = times;
		this.translations = translations;
		this.rotations = rotations;
		this.scales = scales;

		this.useTrans = translations != null;
		this.useRotation = rotations != null;
		this.useScale = scales != null;
	}

	/**
	 * @return the length of the track
	 */
	public function getLength():Float {
		return times == null ? 0 : times[times.length - 1] - times[0];
	}

	public function getKeyFrameTimes():Array<Float> {
		return times;
	}

	public function clone():Track {
		return new SpatialTrack(this.times,this.translations,this.rotations,this.scales);
	}

	private inline function getTranslation(index:Int, vec3:Vector3f):Void {
		var i3:Int = index * 3;
		vec3.x = translations[i3];
		vec3.y = translations[i3 + 1];
		vec3.z = translations[i3 + 2];
	}

	private inline function getScale(index:Int, vec3:Vector3f):Void {
		var i3:Int = index * 3;
		vec3.x = scales[i3];
		vec3.y = scales[i3 + 1];
		vec3.z = scales[i3 + 2];
	}

	private inline function getRotation(index:Int, quat:Quaternion):Void {
		var i4:Int = index * 4;
		quat.x = rotations[i4];
		quat.y = rotations[i4 + 1];
		quat.z = rotations[i4 + 2];
		quat.w = rotations[i4 + 3];
	}

}

