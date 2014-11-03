package org.angle3d.terrain.geomipmap;
import flash.Vector;

/**
 * Stores a terrain patch's details so the LOD background thread can update
 * the actual terrain patch back on the ogl thread.
 *
 * @author Brent Owens
 *
 */
class UpdatedTerrainPatch
{
	
	private var updatedPatch:TerrainPatch;
    private var newLod:Int;
    private var previousLod:Int;
    private var rightLod:Int;
	private var topLod:Int; 
	private var leftLod:Int; 
	private var bottomLod:Int;
    private var newIndexBuffer:Vector<UInt>;
    //private boolean reIndexNeeded = false;
    private var fixEdges:Bool = false;

    public function new(updatedPatch:TerrainPatch, newLod:Int = 0)
	{
        this.updatedPatch = updatedPatch;
        this.newLod = newLod;
    }

    public function getName():String
	{
        return updatedPatch.name;
    }

    public function lodChanged():Bool 
	{
        if ( previousLod != newLod)
            return true;
        else
            return false;
    }

    public function getUpdatedPatch():TerrainPatch
	{
        return updatedPatch;
    }

    public function setUpdatedPatch(updatedPatch:TerrainPatch):Void 
	{
        this.updatedPatch = updatedPatch;
    }

    public function getNewLod():Int
	{
        return newLod;
    }
    
    public function setNewLod( newLod:Int):Void 
	{
        this.newLod = newLod;
        if (this.newLod < 0)
            throw "newLod cannot be less than zero, was: " + newLod;
    }

    /*private IntBuffer getNewIndexBuffer() {
        return newIndexBuffer;
    }*/

    public function setNewIndexBuffer(newIndexBuffer:Vector<UInt>):Void 
	{
        this.newIndexBuffer = newIndexBuffer;
    }


    public function getRightLod():Int 
	{
        return rightLod;
    }


    public function setRightLod( rightLod:Int):Void 
	{
        this.rightLod = rightLod;
    }


    public function getTopLod():Int
	{
        return topLod;
    }


    public function setTopLod( topLod:Int):Void 
	{
        this.topLod = topLod;
    }


    public function getLeftLod():Int
	{
        return leftLod;
    }


    public function setLeftLod( leftLod:Int):Void
	{
        this.leftLod = leftLod;
    }


    public function getBottomLod():Int 
	{
        return bottomLod;
    }


    public function setBottomLod( bottomLod:Int):Void
	{
        this.bottomLod = bottomLod;
    }

    public function isReIndexNeeded():Bool 
	{
        if (lodChanged() || isFixEdges())
            return true;
        //if (leftLod != newLod || rightLod != newLod || bottomLod != newLod || topLod != newLod)
        //    return true;
        return false;
    }

    /*public void setReIndexNeeded(boolean reIndexNeeded) {
        this.reIndexNeeded = reIndexNeeded;
    }*/

    public function isFixEdges():Bool 
	{
        return fixEdges;
    }

    public function setFixEdges( fixEdges:Bool):Void
	{
        this.fixEdges = fixEdges;
    }

    /*public int getPreviousLod() {
        return previousLod;
    }*/

    public function setPreviousLod( previousLod:Int):Void
	{
        this.previousLod = previousLod;
    }

    public function updateAll():Void
	{
        updatedPatch.setLod(newLod);
        updatedPatch.setLodRight(rightLod);
        updatedPatch.setLodTop(topLod);
        updatedPatch.setLodLeft(leftLod);
        updatedPatch.setLodBottom(bottomLod);
        if (newIndexBuffer != null && isReIndexNeeded())
		{
            updatedPatch.setPreviousLod(previousLod);
			updatedPatch.getMesh().setIndices(newIndexBuffer);
        }
    }
}