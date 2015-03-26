package org.angle3d.bullet.control.ragdoll ;
import org.angle3d.utils.FastStringMap;
import org.angle3d.bullet.joints.SixDofJoint;
import org.angle3d.utils.Logger;

/**
 *
 * @author Nehon
 */
class RagdollPreset 
{
    private var boneMap:FastStringMap<JointPreset> = new FastStringMap<JointPreset>();
    private var lexicon:FastStringMap<LexiconEntry> = new FastStringMap<LexiconEntry>();
	
	public function new()
	{
		
	}

    private function initBoneMap():Void
	{
		
	}

    private function initLexicon():Void
	{
		
	}

    public function setupJointForBone(boneName:String, joint:SixDofJoint):Void
	{
        if (!boneMap.iterator().hasNext())
		{
            initBoneMap();
        }
        if (!lexicon.iterator().hasNext())
		{
            initLexicon();
        }
		
        var resultName:String = "";
        var resultScore:Int = 0;
		
		var keys = lexicon.keys();
		for (key in keys)
		{
			var score:Int = lexicon.get(key).getScore(boneName);
			if (score > resultScore)
			{
                resultScore = score;
                resultName = key;
            }
		}
        
        var preset:JointPreset = boneMap.get(resultName);

        if (preset != null && resultScore >= 50)
		{
            Logger.log('Found matching joint for bone {boneName} : {resultName} with score {resultScore}');
            preset.setupJoint(joint);
        } 
		else
		{
            Logger.log('No joint match found for bone ${boneName}');
            if (resultScore > 0) 
			{
                Logger.log('Best match found is ${resultName} with score ${resultScore}');
            }
            new JointPreset().setupJoint(joint);
        }

    }
}

class LexiconEntry
{
	public var map:FastStringMap<Int>;
	
	public function new()
	{
		map = new FastStringMap<Int>();
	}
	
	public function put(key:String, value:Int):Void
	{
		map.set(key, value);
	}
	
	public function addSynonym(word:String, score:Int):Void
	{
		map.set(word.toLowerCase(), score);
	}

	public function getScore(word:String):Int
	{
		var score:Int = 0;
		var searchWord:String = word.toLowerCase();
		var keys = map.keys();
		for(key in keys)
		{
			if (searchWord.indexOf(key) >= 0)
			{
				score += map.get(key);
			}
		}
		return score;
	}
}

class JointPreset 
{

	private var maxX:Float;
	private var minX:Float;
	private var maxY:Float;
	private var minY:Float;
	private var maxZ:Float;
	private var minZ:Float;

	public function new(maxX:Float=0, minX:Float=0, maxY:Float=0, minY:Float=0, maxZ:Float=0, minZ:Float=0) 
	{
		this.maxX = maxX;
		this.minX = minX;
		this.maxY = maxY;
		this.minY = minY;
		this.maxZ = maxZ;
		this.minZ = minZ;
	}

	public function setupJoint(joint:SixDofJoint):Void
	{
		joint.getRotationalLimitMotor(0).setHiLimit(maxX);
		joint.getRotationalLimitMotor(0).setLoLimit(minX);
		joint.getRotationalLimitMotor(1).setHiLimit(maxY);
		joint.getRotationalLimitMotor(1).setLoLimit(minY);
		joint.getRotationalLimitMotor(2).setHiLimit(maxZ);
		joint.getRotationalLimitMotor(2).setLoLimit(minZ);
	}
}

