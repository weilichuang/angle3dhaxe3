package angle3d.terrain.geomipmap.picking ;
import angle3d.math.FastMath;
import angle3d.math.Ray;
import angle3d.math.Vector2f;
import angle3d.math.Vector3f;


/**
 * Works on the XZ plane, with positive Y as up.
 */
class BresenhamYUpGridTracer
{

	private var gridOrigin:Vector3f = new Vector3f();
    private var gridSpacing:Vector3f = new Vector3f();
    private var gridLocation:Vector2f = new Vector2f();
    private var rayLocation:Vector3f = new Vector3f();
    private var walkRay:Ray = new Ray();

    private var stepDirection:Direction = Direction.None;
    private var rayLength:Float;

    // a "near zero" value we will use to determine if the walkRay is
    // perpendicular to the grid.
    private static var TOLERANCE:Float = 0.0000001;

    private var stepXDirection:Int;
    private var stepZDirection:Int;

    // from current position along ray
    private var distToNextXIntersection:Float;
	private var distToNextZIntersection:Float;
    private var distBetweenXIntersections:Float;
	private var distBetweenZIntersections:Float;
	
	public function new()
	{
		
	}

    public function startWalk(walkRay:Ray):Void
	{
        // store ray
        this.walkRay.copyFrom(walkRay);

        // simplify access to direction
        var direction:Vector3f = this.walkRay.getDirection();

        // Move start point to grid space
        var start:Vector3f = this.walkRay.getOrigin().subtract(gridOrigin);

        gridLocation.x = Std.int(start.x / gridSpacing.x);
        gridLocation.y = Std.int(start.z / gridSpacing.z);

        var ooDirection:Vector3f = new Vector3f(1.0 / direction.x, 1, 1.0 / direction.z);

        // Check which direction on the X world axis we are moving.
        if (direction.x > TOLERANCE)
		{
            distToNextXIntersection = ((gridLocation.x + 1) * gridSpacing.x - start.x) * ooDirection.x;
            distBetweenXIntersections = gridSpacing.x * ooDirection.x;
            stepXDirection = 1;
        }
		else if (direction.x < -TOLERANCE)
		{
            distToNextXIntersection = (start.x - (gridLocation.x * gridSpacing.x)) * -direction.x;
            distBetweenXIntersections = -gridSpacing.x * ooDirection.x;
            stepXDirection = -1;
        } 
		else
		{
            distToNextXIntersection = FastMath.POSITIVE_INFINITY;
            distBetweenXIntersections = FastMath.POSITIVE_INFINITY;
            stepXDirection = 0;
        }

        // Check which direction on the Z world axis we are moving.
        if (direction.z > TOLERANCE)
		{
            distToNextZIntersection = ((gridLocation.y + 1) * gridSpacing.z - start.z) * ooDirection.z;
            distBetweenZIntersections = gridSpacing.z * ooDirection.z;
            stepZDirection = 1;
        } 
		else if (direction.z < -TOLERANCE)
		{
            distToNextZIntersection = (start.z - (gridLocation.y * gridSpacing.z)) * -direction.z;
            distBetweenZIntersections = -gridSpacing.z * ooDirection.z;
            stepZDirection = -1;
        } 
		else
		{
            distToNextZIntersection = FastMath.POSITIVE_INFINITY;
            distBetweenZIntersections = FastMath.POSITIVE_INFINITY;
            stepZDirection = 0;
        }

        // Reset some variables
        rayLocation.copyFrom(start);
        rayLength = 0.0;
        stepDirection = Direction.None;
    }

    public function next():Void
	{
        // Walk us to our next location based on distances to next X or Z grid
        // line.
        if (distToNextXIntersection < distToNextZIntersection) 
		{
            rayLength = distToNextXIntersection;
            gridLocation.x += stepXDirection;
            distToNextXIntersection += distBetweenXIntersections;
            switch (stepXDirection) 
			{
				case -1:
					stepDirection = Direction.NegativeX;
				case 0:
					stepDirection = Direction.None;
				case 1:
					stepDirection = Direction.PositiveX;
            }
        }
		else
		{
            rayLength = distToNextZIntersection;
            gridLocation.y += stepZDirection;
            distToNextZIntersection += distBetweenZIntersections;
            switch (stepZDirection)
			{
				case -1:
					stepDirection = Direction.NegativeZ;
				case 0:
					stepDirection = Direction.None;
				case 1:
					stepDirection = Direction.PositiveZ;
            }
        }

        rayLocation.copyFrom(walkRay.direction).scaleLocal(rayLength).addLocal(walkRay.origin);
    }

    public function getLastStepDirection():Direction
	{
        return stepDirection;
    }

    public function isRayPerpendicularToGrid():Bool
	{
        return stepXDirection == 0 && stepZDirection == 0;
    }


    public function getGridLocation():Vector2f 
	{
        return gridLocation;
    }

    public function getGridOrigin():Vector3f 
	{
        return gridOrigin;
    }

    public function getGridSpacing():Vector3f
	{
        return gridSpacing;
    }


    public function setGridLocation(gridLocation:Vector2f):Void
	{
        this.gridLocation = gridLocation;
    }

    public function setGridOrigin(gridOrigin:Vector3f):Void
	{
        this.gridOrigin = gridOrigin;
    }

    public function setGridSpacing(gridSpacing:Vector3f):Void 
	{
        this.gridSpacing = gridSpacing;
    }
	
}