package org.angle3d.scene.shape;

import flash.Vector;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.mesh.BufferUtils;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.utils.TempVars;

/**
 * Sphere represents a 3D object with all points equidistance from a center point.
 */
class Sphere extends Mesh
{
	/** the distance from the center point each point falls on */
	public var radius:Float;
	
	private var vertCount:Int;
	private var triCount:Int;
	private var zSamples:Int;
	private var radialSamples:Int;
	private var useEvenSlices:Bool;
	private var interior:Bool;

	private var textureMode:SphereTextureMode = SphereTextureMode.Original;

	/**
     * Constructs a sphere. All geometry data buffers are updated automatically.
     * Both zSamples and radialSamples increase the quality of the generated
     * sphere.
     * 
     * @param zSamples
     *            The number of samples along the Z.
     * @param radialSamples
     *            The number of samples along the radial.
     * @param radius
     *            The radius of the sphere.
     */
	public function new(radius:Float = 50, zSamples:Int = 32, radialSamples:Int = 32, useEvenSlices:Bool = false, interior:Bool = false)
	{
		super();

		updateGeometry(radius, zSamples, radialSamples, useEvenSlices, interior);
	}

	public function updateGeometry(radius:Float = 50, zSamples:Int = 16, radialSamples:Int = 12, useEvenSlices:Bool = false, interior:Bool = false):Void
	{
		if (zSamples < 3)
		{
            throw "zSamples cannot be smaller than 3";
        }
		this.radius = radius;
        this.zSamples = zSamples;
        this.radialSamples = radialSamples;
        this.useEvenSlices = useEvenSlices;
        this.interior = interior;
        setGeometryData();
        setIndexData();
        setStatic();
		validate();
	}
	
	/**
     * builds the vertices based on the radius, radial and zSamples.
     */
    private function setGeometryData():Void
	{
        // allocate vertices
        vertCount = (zSamples - 2) * (radialSamples + 1) + 2;
		
		var positions:Vector<Float> = new Vector<Float>();
		var normals:Vector<Float> = new Vector<Float>();
		var texCoords:Vector<Float> = new Vector<Float>();

        // generate geometry
        var fInvRS:Float = 1.0 / radialSamples;
        var fZFactor:Float = 2.0 / (zSamples - 1);

        // Generate points on the unit circle to be used in computing the mesh
        // points on a sphere slice.
        var afSin:Vector<Float> = new Vector<Float>(radialSamples + 1);
        var afCos:Vector<Float> = new Vector<Float>(radialSamples + 1);
        for (iR in 0...radialSamples)
		{
            var fAngle:Float = FastMath.TWO_PI() * fInvRS * iR;
            afCos[iR] = Math.cos(fAngle);
            afSin[iR] = Math.sin(fAngle);
        }
        afSin[radialSamples] = afSin[0];
        afCos[radialSamples] = afCos[0];

        var vars:TempVars = TempVars.get();
        var tempVa:Vector3f = vars.vect1;
        var tempVb:Vector3f = vars.vect2;
        var tempVc:Vector3f = vars.vect3;

        // generate the sphere itself
        var i:Int = 0;
        for (iZ in 1...(zSamples - 1))
		{
            var fAFraction:Float = FastMath.HALF_PI() * (-1.0 + fZFactor * iZ); // in (-pi/2, pi/2)
            var fZFraction:Float;
            if (useEvenSlices)
			{
                fZFraction = -1.0 + fZFactor * iZ; // in (-1, 1)
            } 
			else
			{
                fZFraction = Math.sin(fAFraction); // in (-1,1)
            }
            var fZ:Float = radius * fZFraction;

            // compute center of slice
            var kSliceCenter:Vector3f = tempVb.setTo(0,0,0);
            kSliceCenter.z += fZ;

            // compute radius of slice
            var fSliceRadius:Float = FastMath.sqrt(FastMath.abs(radius * radius
                    - fZ * fZ));

            // compute slice vertices with duplication at end point
            var kNormal:Vector3f;
            var iSave:Int = i;
            for (iR in 0...radialSamples)
			{
                var fRadialFraction:Float = iR * fInvRS; // in [0,1)
                var kRadial:Vector3f = tempVc.setTo(afCos[iR], afSin[iR], 0);
                kRadial.scale(fSliceRadius, tempVa);
				
				positions.push(kSliceCenter.x + tempVa.x);
				positions.push(kSliceCenter.y + tempVa.y);
				positions.push(kSliceCenter.z + tempVa.z);

                BufferUtils.populateFromBuffer(tempVa, positions, i);
                kNormal = tempVa;
                kNormal.normalizeLocal();
                if (!interior) // allow interior texture vs. exterior
                {
                    normals.push(kNormal.x);
					normals.push(kNormal.y);
					normals.push(kNormal.z);
                } 
				else
				{
					normals.push(-kNormal.x);
					normals.push(-kNormal.y);
					normals.push(-kNormal.z);
                }

                if (textureMode == SphereTextureMode.Original) 
				{
					texCoords.push(fRadialFraction);
					texCoords.push(0.5 * (fZFraction + 1.0));
                } 
				else if (textureMode == SphereTextureMode.Projected)
				{
                    texCoords.push(fRadialFraction);
					texCoords.push(FastMath.INV_PI() * (FastMath.HALF_PI() + Math.asin(fZFraction)));
                }
				else if (textureMode == SphereTextureMode.Polar) 
				{
                    var r:Float = (FastMath.HALF_PI() - Math.abs(fAFraction)) / Math.PI;
                    var u:Float = r * afCos[iR] + 0.5;
                    var v:Float = r * afSin[iR] + 0.5;
                    texCoords.push(u);
					texCoords.push(v);
                }

                i++;
            }

            BufferUtils.copyInternalVector3(positions, iSave, i);
            BufferUtils.copyInternalVector3(normals, iSave, i);

            if (textureMode == SphereTextureMode.Original) 
			{
                texCoords.push(1.0);
				texCoords.push(0.5 * (fZFraction + 1.0));
            } 
			else if (textureMode == SphereTextureMode.Projected)
			{
                texCoords.push(1.0);
				texCoords.push(FastMath.INV_PI() * (FastMath.HALF_PI() + Math.asin(fZFraction)));
            } 
			else if (textureMode == SphereTextureMode.Polar) 
			{
                var r:Float = (FastMath.HALF_PI() - FastMath.abs(fAFraction)) / Math.PI;
                texCoords.push(r + 0.5);
				texCoords.push(0.5);
            }

            i++;
        }

        vars.release();

        // south pole
        positions.push(0);
		positions.push(0);
		positions.push(-radius);

        if (!interior)
		{
            normals.push(0);
			normals.push(0);
			normals.push(-1); // allow for inner
        } // texture orientation
        // later.
        else
		{
            normals.push(0);
			normals.push(0);
			normals.push(1);
        }

        if (textureMode == SphereTextureMode.Polar)
		{
            texCoords.push(0.5);
			texCoords.push(0.5);
        } 
		else
		{
            texCoords.push(0.5);
			texCoords.push(0.0);
        }

        i++;

        // north pole
        positions.push(0);
		positions.push(0);
		positions.push(radius);

        if (!interior) 
		{
            normals.push(0);
			normals.push(0);
			normals.push(1);
        } 
		else
		{
            normals.push(0);
			normals.push(0);
			normals.push( -1);
        }

        if (textureMode == SphereTextureMode.Polar) 
		{
            texCoords.push(0.5);
			texCoords.push(0.5);
        } 
		else 
		{
            texCoords.push(0.5);
			texCoords.push(1.0);
        }
		
		setVertexBuffer(BufferType.POSITION, 3, positions);
		setVertexBuffer(BufferType.TEXCOORD, 2, texCoords);
		setVertexBuffer(BufferType.NORMAL, 3, normals);
    }

    /**
     * sets the indices for rendering the sphere.
     */
    private function setIndexData():Void
	{
        // allocate connectivity
        triCount = 2 * (zSamples - 2) * radialSamples;
		
		var indices:Vector<UInt> = new Vector<UInt>();

        // generate connectivity
        var index:Int = 0;
		var iZ:Int = 0;
		var iZStart:Int = 0;
        while (iZ < (zSamples - 3))
		{
            var i0:Int = iZStart;
            var i1:Int = i0 + 1;
            iZStart += (radialSamples + 1);
            var i2:Int = iZStart;
            var i3:Int = i2 + 1;
			
			var i:Int = 0;
            while (i < radialSamples)
			{
                if (!interior)
				{
                    indices.push(i0++);
                    indices.push(i1);
                    indices.push(i2);
                    indices.push(i1++);
                    indices.push(i3++);
                    indices.push(i2++);
                } 
				else
				{ 
					// inside view
                    indices.push(i0++);
                    indices.push(i2);
                    indices.push(i1);
                    indices.push(i1++);
                    indices.push(i2++);
                    indices.push(i3++);
                }
				
				i++;
				index += 6;
            }
			iZ++;
        }

        // south pole triangles
		var i:Int = 0;
        while (i < radialSamples) 
		{
            if (!interior)
			{
                indices.push(i);
                indices.push((vertCount - 2));
                indices.push((i + 1));
            } 
			else
			{
				// inside view
                indices.push(i);
                indices.push((i + 1));
                indices.push((vertCount - 2));
            }
			i++;
			index += 3;
        }

        // north pole triangles
        var iOffset:Int = (zSamples - 3) * (radialSamples + 1);
		i = 0;
        while (i < radialSamples)
		{
            if (!interior)
			{
                indices.push((i + iOffset));
                indices.push((i + 1 + iOffset));
                indices.push((vertCount - 1));
            } 
			else 
			{
				// inside view
                indices.push((i + iOffset));
                indices.push((vertCount - 1));
                indices.push((i + 1 + iOffset));
            }
			i++;
			index += 3;
        }
		
		setIndices(indices);
    }

    /**
     * @param textureMode
     *            The textureMode to set.
     */
    public function setTextureMode(textureMode:SphereTextureMode):Void
	{
        this.textureMode = textureMode;
        setGeometryData();
    }

	public function getRadialSamples():Int
	{
        return radialSamples;
    }

    public function getRadius():Float 
	{
        return radius;
    }

    /**
     * @return Returns the textureMode.
     */
    public function getTextureMode():SphereTextureMode
	{
        return textureMode;
    }

    public function getZSamples():Int
	{
        return zSamples;
    }
}

enum SphereTextureMode
{
	/** 
	 * Wrap texture radially and along z-axis 
	 */
	Original;
	/** 
	 * Wrap texure radially, but spherically project along z-axis 
	 */
	Projected;
	/** 
	 * Apply texture to each pole.  Eliminates polar distortion,
	 * but mirrors the texture across the equator 
	 */
	Polar;
}
