package angle3d.terrain.heightmap ;

/**
 *

 */
interface Namer 
{

    /**
     * Gets a name for a heightmap tile given it's cell id
     * @param x
     * @param y
     * @return
     */
    function getName(x:Int, y:Int):String;

}
