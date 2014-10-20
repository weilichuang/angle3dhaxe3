package org.angle3d.scene.debug;
import flash.Vector;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.shape.WireframeLineSet;
import org.angle3d.scene.shape.WireframeShape;

/**
 * ...
 * @author weilichuang
 */
class Arrow extends WireframeShape
{
	private var _curExtent:Vector3f;
	
	private var tempQuat:Quaternion = new Quaternion();
    private var tempVec:Vector3f = new Vector3f();

    private static var positions:Vector<Float> = Vector.ofArray([
        0, 0, 0,
        0, 0, 1, // tip
        0.05, 0, 0.9, // tip right
        -0.05, 0, 0.9, // tip left
        0, 0.05, 0.9, // tip top
        0, -0.05, 0.9, // tip buttom
    ]);
	
	private static var indices:Vector<Int> = Vector.ofArray([0, 1,
                    1, 2,
                    1, 3,
                    1, 4,
                    1, 5]);	

	public function new(extent:Vector3f) 
	{
		super();
		
		setArrowExtent(extent);
	}
	
	/**
     * Sets the arrow's extent.
     * This will modify the buffers on the mesh.
     * 
     * @param extent the arrow's extent.
     */
	
    public function setArrowExtent(extent:Vector3f):Void
	{
		if (_curExtent != null && _curExtent.equals(extent))
			return;
		
		_curExtent = extent;
		
        var len:Float = extent.length;
        var dir:Vector3f = extent.normalize();

        tempQuat.lookAt(dir, Vector3f.Y_AXIS);
        tempQuat.normalizeLocal();

        var newPositions:Vector<Float> = new Vector<Float>(positions.length);
        var i:Int = 0;
		while (i < newPositions.length)
		{
            var vec:Vector3f = tempVec.setTo(positions[i], positions[i + 1], positions[i + 2]);
            vec.scaleLocal(len);
            tempQuat.multiplyVector(vec, vec);

            newPositions[i] = vec.x;
            newPositions[i + 1] = vec.y;
            newPositions[i + 2] = vec.z;
			
			i += 3;
        }
		
		var j:Int = 0;
		while (j < indices.length)
		{
			var sIndex:Int = indices[j];
			var eIndex:Int = indices[j + 1];
			addSegment(new WireframeLineSet(newPositions[sIndex*3+0], newPositions[sIndex*3+1], newPositions[sIndex*3+2],
										newPositions[eIndex * 3 + 0], newPositions[eIndex * 3 + 1], newPositions[eIndex * 3 + 2]));
										
			j += 2;
		}
		build();
    }
	
}