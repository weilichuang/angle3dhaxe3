package angle3d.effect.gpu.influencers.position;

import angle3d.effect.gpu.influencers.AbstractInfluencer;
import angle3d.math.Vector3f;

class DefaultPositionInfluencer extends AbstractInfluencer implements IPositionInfluencer {
	private var _point:Vector3f;

	public function new(point:Vector3f = null) {
		super();
		_point = point != null ? point.clone() : new Vector3f(0, 0, 0);
	}

	public function getPosition(index:Int, vector3:Vector3f):Vector3f {
		vector3.copyFrom(_point);
		return vector3;
	}
}
