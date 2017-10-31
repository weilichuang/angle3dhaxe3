package org.angle3d.terrain.geomipmap.grid ;


import org.angle3d.math.Vector3f;
import org.angle3d.terrain.geomipmap.TerrainGridTileLoader;
import org.angle3d.terrain.geomipmap.TerrainQuad;
import org.angle3d.terrain.heightmap.AbstractHeightMap;
import org.angle3d.terrain.heightmap.HeightMap;
import org.angle3d.terrain.noise.Basis;

/**
 *
, normenhansen
 */
class FractalTileLoader implements TerrainGridTileLoader
{  
    private var patchSize:Int;
    private var quadSize:Int;
    private var base:Basis;
    private var heightScale:Float;

    public function new(base:Basis, heightScale:Float)
	{
        this.base = base;
        this.heightScale = heightScale;
    }

    private function getHeightMapAt(location:Vector3f):HeightMap
	{
        var heightmap:AbstractHeightMap = null;
        
        var buffer:Array<Float> = this.base.getBuffer(location.x * (this.quadSize - 1), location.z * (this.quadSize - 1), 0, this.quadSize);

        for (i in 0...buffer.length)
		{
            buffer[i] *= this.heightScale;
        }
        heightmap = new FloatBufferHeightMap(buffer);
        heightmap.load();
        return heightmap;
    }

    public function getTerrainQuadAt(location:Vector3f):TerrainQuad
	{
        var heightMapAt:HeightMap = getHeightMapAt(location);
        var q:TerrainQuad = new TerrainQuad("Quad" + location);
		q.init2(patchSize, quadSize, new Vector3f(1, 1, 1), heightMapAt == null ? null : heightMapAt.getHeightMap());
        return q;
    }

    public function setPatchSize(patchSize:Int):Void
	{
        this.patchSize = patchSize;
    }

    public function setQuadSize(quadSize:Int):Void
	{
        this.quadSize = quadSize;
    } 
}

class FloatBufferHeightMap extends AbstractHeightMap 
{

	private var buffer:Array<Float>;

	public function new(buffer:Array<Float>)
	{
		this.buffer = buffer;
	}
	
	override public function load():Bool
	{
		this.heightData = this.buffer;
		return true;
	}
}
