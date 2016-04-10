package org.angle3d.terrain.geomipmap ;
import org.angle3d.math.Vector3f;

/**
 
 */

interface TerrainGridTileLoader 
{
	function getTerrainQuadAt(location:Vector3f):TerrainQuad;

    function setPatchSize(patchSize:Int):Void;

    function setQuadSize(quadSize:Int):Void;
}