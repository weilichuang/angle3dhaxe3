package org.angle3d.terrain.heightmap ;

import org.angle3d.math.Vector3f;

/**
 *

 */
@Deprecated
/**
 * @Deprecated in favor of TerrainGridTileLoader
 */
interface HeightMapGrid
{

    function getHeightMapAt(location:Vector3f):HeightMap;

    function setSize(size:Int):Void;

}
