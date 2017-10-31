package org.angle3d.scene.shape;

import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.mesh.BufferUtils;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.scene.mesh.MeshHelper;

import org.angle3d.utils.Logger;

class Cone extends Mesh
{
	private var axisSamples:Int;

    private var radialSamples:Int;

    private var radius:Float;
    private var radius2:Float;

    private var height:Float;
    private var closed:Bool;
    private var inverted:Bool;

	public function new(axisSamples:Int, radialSamples:Int, radius:Float, radius2:Float, height:Float, closed:Bool=true,
	inverted:Bool = false )
	{
		super();

		updateGeometry(axisSamples, radialSamples, radius, radius2, height, closed, inverted);
	}

	private function updateGeometry(axisSamples:Int, radialSamples:Int, radius:Float, radius2:Float, height:Float, closed:Bool=true,
	inverted:Bool = false):Void
	{
		this.axisSamples = axisSamples + (closed ? 2 : 0);
        this.radialSamples = radialSamples;
        this.radius = radius;
        this.radius2 = radius2;
        this.height = height;
        this.closed = closed;
        this.inverted = inverted;

		// Vertices
        var vertCount:Int = axisSamples * (radialSamples + 1) + (closed ? 2 : 0);
		var triCount:Int = ((closed ? 2 : 0) + 2 * (axisSamples - 1)) * radialSamples;
		
		var pb:Vector<Float> = new Vector<Float>();
		
		var tb:Vector<Float> = new Vector<Float>();
		var nb:Vector<Float> = new Vector<Float>();

		// generate geometry
        var inverseRadial:Float = 1.0 / radialSamples;
        var inverseAxisLess:Float = 1.0 / (closed ? axisSamples - 3 : axisSamples - 1);
        var inverseAxisLessTexture:Float = 1.0 / (axisSamples - 1);
        var halfHeight:Float = 0.5 * height;

        // Generate points on the unit circle to be used in computing the mesh
        // points on a cylinder slice.
        var sin:Vector<Float> = new Vector<Float>(radialSamples + 1);
        var cos:Vector<Float> = new Vector<Float>(radialSamples + 1);

        for (radialCount in 0...radialSamples)
		{
            var angle:Float = FastMath.TWO_PI * inverseRadial * radialCount;
            cos[radialCount] = Math.cos(angle);
            sin[radialCount] = Math.sin(angle);
        }
        sin[radialSamples] = sin[0];
        cos[radialSamples] = cos[0];

        // calculate normals
        var vNormals:Vector<Vector3f> = null;
        var vNormal:Vector3f = new Vector3f(0, 0, 1);

        if ((height != 0.0) && (radius != radius2))
		{
            vNormals = new Vector<Vector3f>(radialSamples);
            var vHeight:Vector3f = new Vector3f(0, 0, 1).scaleLocal(height);
            var vRadial:Vector3f = new Vector3f();

            for (radialCount in 0...radialSamples)
			{
                vRadial.setTo(cos[radialCount], sin[radialCount], 0.0);
                var vRadius:Vector3f = vRadial.scale(radius);
                var vRadius2:Vector3f = vRadial.scale(radius2);
                var vMantle:Vector3f = vHeight.subtract(vRadius2.subtract(vRadius));
                var vTangent:Vector3f = vRadial.cross(new Vector3f(0, 0, 1));
                vNormals[radialCount] = vMantle.cross(vTangent).normalize();
            }
        }

        // generate the cylinder itself
        var tempNormal:Vector3f = new Vector3f();
		var axisCount:Int = 0;
		var i:Int = 0;
		while (axisCount < axisSamples)
		{
			var axisFraction:Float;
            var axisFractionTexture:Float;
            var topBottom:Int = 0;
            if (!closed)
			{
                axisFraction = axisCount * inverseAxisLess; // in [0,1]
                axisFractionTexture = axisFraction;
            } 
			else 
			{
                if (axisCount == 0)
				{
                    topBottom = -1; // bottom
                    axisFraction = 0;
                    axisFractionTexture = inverseAxisLessTexture;
                } 
				else if (axisCount == axisSamples - 1)
				{
                    topBottom = 1; // top
                    axisFraction = 1;
                    axisFractionTexture = 1 - inverseAxisLessTexture;
                }
				else
				{
                    axisFraction = (axisCount - 1) * inverseAxisLess;
                    axisFractionTexture = axisCount * inverseAxisLessTexture;
                }
            }

            // compute center of slice
            var z:Float = -halfHeight + height * axisFraction;
            var sliceCenter:Vector3f = new Vector3f(0, 0, z);

            // compute slice vertices with duplication at end point
            var save:Int = i;
            for (radialCount in 0...radialSamples) 
			{
                var radialFraction:Float = radialCount * inverseRadial; // in [0,1)
                tempNormal.setTo(cos[radialCount], sin[radialCount], 0.0);

                if (vNormals != null) 
				{
                    vNormal = vNormals[radialCount];
                } 
				else if (radius == radius2) 
				{
                    vNormal = tempNormal;
                }

                if (topBottom == 0)
				{
                    if (!inverted)
					{
                        nb.push(vNormal.x);
						nb.push(vNormal.y);
						nb.push(vNormal.z);
					}
                    else
					{
                        nb.push( -vNormal.x);
						nb.push( -vNormal.y);
						nb.push( -vNormal.z);
					}
                } 
				else
				{
                    nb.push(0);
					nb.push(0);
					nb.push(topBottom * (inverted ? -1 : 1));
                }

                tempNormal.scaleLocal((radius - radius2) * axisFraction + radius2)
                        .addLocal(sliceCenter);
                pb.push(tempNormal.x);
				pb.push(tempNormal.y);
				pb.push(tempNormal.z);
				
                tb.push((inverted ? 1 - radialFraction : radialFraction));
                tb.push(axisFractionTexture);
						
				i++;
            }

            BufferUtils.copyInternalVector3(pb, save, i);
            BufferUtils.copyInternalVector3(nb, save, i);

            tb.push((inverted ? 0.0 : 1.0));
            tb.push(axisFractionTexture);
					
			i++;
			axisCount++;
		}
		
        if (closed)
		{
            pb.push(0); 
			pb.push(0); 
			pb.push( -halfHeight); // bottom center
			
            nb.push(0);
			nb.push(0);
			nb.push( -1 * (inverted ? -1 : 1));
			
            tb.push(0.5);
			tb.push(0);
			
            pb.push(0);
			pb.push(0);
			pb.push(halfHeight); // top center
			
            nb.push(0);
			nb.push(0);
			nb.push(1 * (inverted ? -1 : 1));
			
            tb.push(0.5);
			tb.push(1);
        }

        var ib:Vector<UInt> = new Vector<UInt>();
        var index:Int = 0;
		
		var axisStart:Int = 0;
        // Connectivity
        for (axisCount in 0...(axisSamples - 1))
		{
            var i0:Int = axisStart;
            var i1:Int = i0 + 1;
            axisStart += radialSamples + 1;
            var i2:Int = axisStart;
            var i3:Int = i2 + 1;
            for (i in 0...radialSamples) 
			{
                if (closed && axisCount == 0)
				{
                    if (!inverted)
					{
						ib[index++] = i1++;
                        ib[index++] = vertCount - 2;
                        ib[index++] = i0++;
                    }
					else
					{
						ib[index++] = vertCount - 2;
                        ib[index++] = i1++;
                        ib[index++] = i0++;
                    }
                } 
				else if (closed && axisCount == axisSamples - 2) 
				{
					ib[index++] = inverted ? i3++ : vertCount - 1;
                    ib[index++] = inverted ? vertCount - 1 : i3++;
                    ib[index++] = i2++;
                } 
				else
				{
					ib[index++] = inverted ? i1 : i2;
                    ib[index++] = inverted ? i2 : i1;
                    ib[index++] = i0++;
					
					ib[index++] = inverted ? i3++ : i2++;
                    ib[index++] = inverted ? i2++ : i3++;
                    ib[index++] = i1++;
                }
            }
        }

		setVertexBuffer(BufferType.POSITION, 3, pb);
		setVertexBuffer(BufferType.TEXCOORD, 2, tb);
		setVertexBuffer(BufferType.NORMAL, 3, nb);
		setIndices(ib);
		validate();
	}
}