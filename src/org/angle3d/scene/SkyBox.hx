package org.angle3d.scene;

import org.angle3d.bounding.BoundingSphere;
import org.angle3d.renderer.queue.QueueBucket;
import org.angle3d.scene.shape.Sphere;

/**
 * 天空体
 * @author weilichuang
 */
class SkyBox extends Geometry
{
	public function new(size:Float = 100.0)
	{
		super("SkyBox");
		
		//TODO 添加参数用来选择使用Sphere还是Box
		var sphereMesh:Sphere = new Sphere(size / 2, 10, 10);
		//setMesh(new SkyBoxShape(size));
		setMesh(sphereMesh);
		
		localQueueBucket = QueueBucket.Sky;
		localCullHint = CullHint.Never;
		//setModelBound(new BoundingSphere(Math.POSITIVE_INFINITY));
	}
}

