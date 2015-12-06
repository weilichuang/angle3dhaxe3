package org.angle3d.io.parser.ogre;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.geom.Vector3D;
import flash.Vector;
import haxe.ds.StringMap;
import haxe.xml.Fast;
import org.angle3d.animation.Animation;
import org.angle3d.animation.Bone;
import org.angle3d.animation.BoneTrack;
import org.angle3d.animation.Skeleton;
import org.angle3d.animation.Track;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;

/**
 * ...
 * @author weilichuang
 */
class OgreSkeletonParser extends EventDispatcher
{
	private var bones:Vector<Bone>;
	private var boneMap:StringMap<Bone>;
	
	private var rotation:Quaternion = new Quaternion();
	private var axis:Vector3f = new Vector3f();
	
	public var skeleton:Skeleton;
	public var animations:Vector<Animation>;
	
	public function new() 
	{
		super();
	}
	
	public function parse(data:String):Void
	{
		skeleton = new Skeleton();
		animations = new Vector<Animation>();
		
		bones = new Vector<Bone>();
		boneMap = new StringMap<Bone>();
		
		var xml:Xml = Xml.parse(data);
		var fast:Fast = new Fast(xml.firstElement());
		var bonesFast:Fast = fast.node.bones;
		for (boneFast in bonesFast.nodes.bone)
		{
			var bone:Bone = startBone(boneFast);
			boneMap.set(bone.name, bone);
			bones.push(bone);
		}
		
		var bonehierarchy:Fast = fast.node.bonehierarchy;
		for (boneParentFast in bonehierarchy.nodes.boneparent)
		{
			var boneName:String = boneParentFast.att.bone;
			var parentName:String = boneParentFast.att.parent;
			
			var bone:Bone = boneMap.get(boneName);
			bone.parentName = parentName;
		}
		
		skeleton.setBones(bones);
		
		var animationsFast:Fast = fast.node.animations;
		for (animationFast in animationsFast.nodes.animation)
		{
			var animatonName:String = animationFast.att.name;
			var length:Float = Std.parseFloat(animationFast.att.length);
			
			var animation:Animation = new Animation(animatonName, length);
			
			var tracks:Fast = animationFast.node.tracks;
			for (trackFast in tracks.nodes.track)
			{
				var bone:Bone = boneMap.get(trackFast.att.bone);
				var boneIndex:Int = skeleton.getBoneIndex(bone);
				var track:BoneTrack = new BoneTrack(boneIndex);
				
				var times:Vector<Float> = new Vector<Float>();
				var translations:Vector<Float> = new Vector<Float>();
				var rotations:Vector<Float> = new Vector<Float>();
				var scales:Vector<Float> = new Vector<Float>();
				
				var keyframesFast:Fast = trackFast.node.keyframes;
				for (keyframe in keyframesFast.nodes.keyframe)
				{
					times.push(Std.parseFloat(keyframe.att.time));
					if (keyframe.hasNode.translate)
					{
						var translate:Fast = keyframe.node.translate;
						
						translations.push(Std.parseFloat(translate.att.x));
						translations.push(Std.parseFloat(translate.att.y));
						translations.push(Std.parseFloat(translate.att.z));
					}
					
					if (keyframe.hasNode.rotate)
					{
						var rotate:Fast = keyframe.node.rotate;
						var angle:Float = Std.parseFloat(rotate.att.angle);
						var axisFast:Fast = rotate.node.axis;
						axis.x = Std.parseFloat(axisFast.att.x);
						axis.y = Std.parseFloat(axisFast.att.y);
						axis.z = Std.parseFloat(axisFast.att.z);
						rotation.fromAngleAxis(angle, axis);
						
						rotations.push(rotation.x);
						rotations.push(rotation.y);
						rotations.push(rotation.z);
						rotations.push(rotation.w);
					}
					
					if (keyframe.hasNode.scale)
					{
						var scaleFast:Fast = keyframe.node.scale;

						scales.push(Std.parseFloat(scaleFast.att.x));
						scales.push(Std.parseFloat(scaleFast.att.y));
						scales.push(Std.parseFloat(scaleFast.att.z));
					}
				}
				
				track.setKeyframes(times, translations, rotations, scales, 4);
				
				animation.addTrack(track);
			}
			
			animations.push(animation);
		}
		
		dispatchEvent(new Event(Event.COMPLETE));
	}
	
	private function startBone(boneFast:Fast):Bone
	{
		var bone:Bone = new Bone("");
		bone.name = boneFast.att.name;
		
		if (boneFast.hasNode.position)
		{
			var positionFast:Fast = boneFast.node.position;
			
			bone.localPos.x = Std.parseFloat(positionFast.att.x);
			bone.localPos.y = Std.parseFloat(positionFast.att.y);
			bone.localPos.z = Std.parseFloat(positionFast.att.z);
		}
		
		if (boneFast.hasNode.rotation)
		{
			var rotationFast:Fast = boneFast.node.rotation;
			
			var angle:Float = Std.parseFloat(rotationFast.att.angle);
			
			var axisFast:Fast = rotationFast.node.axis;
			
			axis.x = Std.parseFloat(axisFast.att.x);
			axis.y = Std.parseFloat(axisFast.att.y);
			axis.z = Std.parseFloat(axisFast.att.z);
			
			rotation.fromAngleAxis(angle, axis);
			
			bone.localRot.copyFrom(rotation);
		}
		
		if (boneFast.hasNode.scale)
		{
			var scaleFast:Fast = boneFast.node.scale;

			bone.localScale.x = Std.parseFloat(scaleFast.att.x);
			bone.localScale.y = Std.parseFloat(scaleFast.att.y);
			bone.localScale.z = Std.parseFloat(scaleFast.att.z);
		}
		
		return bone;
	}
	
}