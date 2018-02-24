package angle3d.terrain.geomipmap.picking ;
import angle3d.collision.CollisionResult;
import angle3d.collision.CollisionResults;
import angle3d.math.Ray;
import angle3d.math.Triangle;
import angle3d.math.Vector2f;
import angle3d.math.Vector3f;
import angle3d.terrain.geomipmap.TerrainQuad;

/**
 * It basically works by casting a pick ray
 * against the bounding volumes of the TerrainQuad and its children, gathering
 * all of the TerrainPatches hit (in distance order.) The triangles of each patch
 * are then tested using the BresenhamYUpGridTracer to determine which triangles
 * to test and in what order. When a hit is found, it is guaranteed to be the
 * first such hit and can immediately be returned.
 * 
 */
class BresenhamTerrainPicker implements TerrainPicker
{
	private var gridTriA:Triangle = new Triangle();
    private var gridTriB:Triangle = new Triangle();

    private var calcVec1:Vector3f = new Vector3f();
    private var workRay:Ray = new Ray();
    private var worldPickRay:Ray = new Ray();

    private var root:TerrainQuad;
    private var tracer:BresenhamYUpGridTracer = new BresenhamYUpGridTracer();


    public function new(root:TerrainQuad)
	{
        this.root = root;
    }

    public function getTerrainIntersection(worldPick:Ray, results:CollisionResults):Vector3f
	{
        worldPickRay.copyFrom(worldPick);
        var pickData:Array<TerrainPickData> = new Array<TerrainPickData>();
        root.findPick(worldPick.clone(), pickData);
		
        //Collections.sort(pickData);

        if (pickData.length == 0)
            return null;

        workRay.copyFrom(worldPick);

        for ( pd in pickData)
		{
            var patch:TerrainPatch = pd.targetPatch;


            tracer.getGridSpacing().copyFrom(patch.getWorldScale());
            tracer.setGridOrigin(patch.getWorldTranslation());

            workRay.getOrigin().copyFrom(worldPick.getDirection()).scaleLocal(pd.cr.distance - .1).addLocal(worldPick.getOrigin());

            tracer.startWalk(workRay);

            var intersection:Vector3f = new Vector3f();
            var loc:Vector2f = tracer.getGridLocation();

            if (tracer.isRayPerpendicularToGrid())
			{
                var hit:Triangle = new Triangle();
                checkTriangles(loc.x, loc.y, workRay, intersection, patch, hit);
                var distance:Float = worldPickRay.origin.distance(intersection);
                var cr:CollisionResult = new CollisionResult();
				cr.contactPoint = intersection;
				cr.distance = distance;
                cr.geometry = patch;
                cr.contactNormal = hit.getNormal();
                results.addCollision(cr);
                return intersection;
            }
            
            

            while (loc.x >= -1 && loc.x <= patch.getSize() && 
                   loc.y >= -1 && loc.y <= patch.getSize()) 
		   {

                //System.out.print(loc.x+","+loc.y+" : ");
                // check the triangles of main square for intersection.
                var hit:Triangle = new Triangle();
                if (checkTriangles(loc.x, loc.y, workRay, intersection, patch, hit))
				{
                    // we found an intersection, so return that!
                    var distance:Float = worldPickRay.origin.distance(intersection);
                    var cr:CollisionResult = new CollisionResult();
					cr.contactPoint = intersection;
					cr.distance = distance;
					cr.geometry = patch;
					cr.contactNormal = hit.getNormal();
                    results.addCollision(cr);
                    return intersection;
                }

                // because of how we get our height coords, we will
                // sometimes be off by a grid spot, so we check the next
                // grid space up.
                var dx:Int = 0, dz:Int = 0;
                var d:Direction = tracer.getLastStepDirection();
                switch (d)
				{
					case Direction.PositiveX,Direction.NegativeX:
						dx = 0;
						dz = 1;
					case Direction.PositiveZ,Direction.NegativeZ:
						dx = 1;
						dz = 0;
					case Direction.PositiveY,Direction.NegativeY,Direction.None:
                }

                if (checkTriangles(loc.x + dx, loc.y + dz, workRay, intersection, patch, hit))
				{
                    // we found an intersection, so return that!
                    var distance:Float = worldPickRay.origin.distance(intersection);
                    var cr:CollisionResult = new CollisionResult();
					cr.contactPoint = intersection;
					cr.distance = distance;
					cr.geometry = patch;
					cr.contactNormal = hit.getNormal();
				
                    results.addCollision(cr);
                    return intersection;
                }

                tracer.next();
            }
        }

        return null;
    }

    private function checkTriangles(gridX:Float, gridY:Float, pick:Ray, intersection:Vector3f, patch:TerrainPatch, store:Triangle):Bool 
	{
        if (!getTriangles(gridX, gridY, patch))
            return false;

        if (pick.intersectWhereTriangle(gridTriA, intersection))
		{
            store.setPoints(gridTriA.point1, gridTriA.point2, gridTriA.point3);
            return true;
        } 
		else
		{
            if (pick.intersectWhereTriangle(gridTriB, intersection)) 
			{
                store.setPoints(gridTriB.point1, gridTriB.point2, gridTriB.point3);
                return true;
            }
        }

        return false;
    }

    /**
     * Request the triangles (in world coord space) of a TerrainBlock that
     * correspond to the given grid location. The triangles are stored in the
     * class fields _gridTriA and _gridTriB.
     *
     * @param gridX
     *            grid row
     * @param gridY
     *            grid column
     * @param patch
     *            the TerrainPatch we are working with
     * @return true if the grid point is valid for the given block, false if it
     *         is off the block.
     */
    private function getTriangles(gridX:Float, gridY:Float, patch:TerrainPatch):Bool 
	{
        calcVec1.setTo(gridX, 0, gridY);
        var index:Int = findClosestHeightIndex(calcVec1, patch);

        if (index == -1)
            return false;
        
        var t:Array<Triangle> = patch.getGridTriangles(gridX, gridY);
        if (t == null || t.length == 0)
            return false;
        
        gridTriA.point1.copyFrom(t[0].point1);
        gridTriA.point2.copyFrom(t[0].point2);
        gridTriA.point3.copyFrom(t[0].point3);

        gridTriB.point1.copyFrom(t[1].point1);
        gridTriB.point2.copyFrom(t[1].point2);
        gridTriB.point3.copyFrom(t[1].point3);

        return true;
    }

    /**
     * Finds the closest height point to a position. Will always be left/above
     * that position.
     *
     * @param position
     *            the position to check at
     * @param patch
     *            the patch to get height values from
     * @return an index to the height position of the given block.
     */
    private function findClosestHeightIndex(position:Vector3f, patch:TerrainPatch):Int 
	{

        var x:Int = Std.int(position.x);
        var z:Int = Std.int(position.z);

        if (x < 0 || x >= patch.getSize() - 1) 
		{
            return -1;
        }
        if (z < 0 || z >= patch.getSize() - 1) 
		{
            return -1;
        }

        return z * patch.getSize() + x;
    }
	
}