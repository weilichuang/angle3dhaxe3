package org.angle3d.bullet.control.ragdoll ;

import org.angle3d.bullet.control.ragdoll.RagdollPreset.JointPreset;
import org.angle3d.bullet.control.ragdoll.RagdollPreset.LexiconEntry;
import org.angle3d.math.FastMath;

class HumanoidRagdollPreset extends RagdollPreset {
	public function new() {
		super();
	}

	override function initBoneMap():Void {
		var QUARTER_PI:Float = 0.25 * Math.PI;
		var HALF_PI:Float = 0.5 * Math.PI;

		boneMap.set("head", new JointPreset(QUARTER_PI, -QUARTER_PI, QUARTER_PI, -QUARTER_PI, QUARTER_PI, -QUARTER_PI));

		boneMap.set("torso", new JointPreset(QUARTER_PI, -QUARTER_PI, 0, 0, QUARTER_PI, -QUARTER_PI));

		boneMap.set("upperleg", new JointPreset(Math.PI, -QUARTER_PI, QUARTER_PI/2, -QUARTER_PI/2, QUARTER_PI, -QUARTER_PI));

		boneMap.set("lowerleg", new JointPreset(0, -Math.PI, 0, 0, 0, 0));

		boneMap.set("foot", new JointPreset(0, -QUARTER_PI, QUARTER_PI, -QUARTER_PI, QUARTER_PI, -QUARTER_PI));

		boneMap.set("upperarm", new JointPreset(HALF_PI, -QUARTER_PI, 0, 0, HALF_PI, -QUARTER_PI));

		boneMap.set("lowerarm", new JointPreset(HALF_PI, 0, 0, 0, 0, 0));

		boneMap.set("hand", new JointPreset(QUARTER_PI, -QUARTER_PI, QUARTER_PI, -QUARTER_PI, QUARTER_PI, -QUARTER_PI));
	}

	override function initLexicon():Void {
		var entry:LexiconEntry = new LexiconEntry();
		entry.addSynonym("head", 100);
		lexicon.set("head", entry);

		entry = new LexiconEntry();
		entry.addSynonym("torso", 100);
		entry.addSynonym("chest", 100);
		entry.addSynonym("spine", 45);
		entry.addSynonym("high", 25);
		lexicon.set("torso", entry);

		entry = new LexiconEntry();
		entry.addSynonym("upperleg", 100);
		entry.addSynonym("thigh", 100);
		entry.addSynonym("hip", 75);
		entry.addSynonym("leg", 40);
		entry.addSynonym("high", 10);
		entry.addSynonym("up", 15);
		entry.addSynonym("upper", 15);
		lexicon.set("upperleg", entry);

		entry = new LexiconEntry();
		entry.addSynonym("lowerleg", 100);
		entry.addSynonym("calf", 100);
		entry.addSynonym("shin", 100);
		entry.addSynonym("knee", 75);
		entry.addSynonym("leg", 50);
		entry.addSynonym("low", 10);
		entry.addSynonym("lower", 10);
		lexicon.set("lowerleg", entry);

		entry = new LexiconEntry();
		entry.addSynonym("foot", 100);
		entry.addSynonym("ankle", 75);
		lexicon.set("foot", entry);

		entry = new LexiconEntry();
		entry.addSynonym("upperarm", 100);
		entry.addSynonym("humerus", 100);
		entry.addSynonym("shoulder", 50);
		entry.addSynonym("arm", 40);
		entry.addSynonym("high", 10);
		entry.addSynonym("up", 15);
		entry.addSynonym("upper", 15);
		lexicon.set("upperarm", entry);

		entry = new LexiconEntry();
		entry.addSynonym("lowerarm", 100);
		entry.addSynonym("ulna", 100);
		entry.addSynonym("elbow", 75);
		entry.addSynonym("arm", 50);
		entry.addSynonym("low", 10);
		entry.addSynonym("lower", 10);
		lexicon.set("lowerarm", entry);

		entry = new LexiconEntry();
		entry.addSynonym("hand", 100);
		entry.addSynonym("fist", 100);
		entry.addSynonym("wrist", 75);
		lexicon.set("hand", entry);
	}
}
