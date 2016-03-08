package org.angle3d.terrain.geomipmap.lodcalc.util ;
import flash.Vector;
import org.angle3d.bounding.BoundingBox;
import org.angle3d.collision.CollisionResults;
import org.angle3d.math.Matrix4f;
import org.angle3d.math.Ray;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.mesh.BufferUtils;
import org.angle3d.scene.mesh.Mesh;

/**
 * Computes the entropy value δ (delta) for a given terrain block and
 * LOD level.
 * See the geomipmapping paper section
 * "2.3.1 Choosing the appropriate GeoMipMap level"
 *
 * 
 */
class EntropyComputeUtil
{

	public static function computeLodEntropy(terrainBlock:Mesh, lodIndices:Vector<UInt>):Float
	{
        // Bounding box for the terrain block
        var bbox:BoundingBox = cast terrainBlock.getBound();

        // Vertex positions for the block
        var positions:Vector<Float> = terrainBlock.getVertexBuffer(BufferType.POSITION).getData();

        // Prepare to cast rays
        var pos:Vector3f = new Vector3f();
        var dir:Vector3f = new Vector3f(0, -1, 0);
        var ray:Ray = new Ray(pos, dir);

        // Prepare collision results
        var results:CollisionResults = new CollisionResults();

        // Set the LOD indices on the block
        var originalIndices:Vector<UInt> = terrainBlock.getIndices();

		terrainBlock.setIndices(lodIndices);

        // Recalculate collision mesh
        terrainBlock.createCollisionData();

        var entropy:Float = 0;
		var triangleCount:Int = Std.int(positions.length / 3);
        for (i in 0...triangleCount)
		{
            BufferUtils.populateFromBuffer(pos, positions, i);

            var realHeight:Float = pos.y;

            pos.addXYZLocal(0, bbox.yExtent, 0);
            ray.setOrigin(pos);

            results.clear();
            terrainBlock.collideWith(ray, Matrix4f.IDENTITY, bbox, results);

            if (results.size > 0)
			{
                var contactPoint:Vector3f = results.getClosestCollision().contactPoint;
                var delta:Float = Math.abs(realHeight - contactPoint.y);
                entropy = Math.max(delta, entropy);
            }
        }

        // Restore original indices
        terrainBlock.setIndices(originalIndices);

        return entropy;
    }
	
}