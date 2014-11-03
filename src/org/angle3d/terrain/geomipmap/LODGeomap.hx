package org.angle3d.terrain.geomipmap;

import flash.Vector;
import org.angle3d.math.FastMath;
import org.angle3d.math.Triangle;
import org.angle3d.math.Vector2f;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.mesh.BufferUtils;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.terrain.GeoMap;
import org.angle3d.utils.TempVars;

/**
 * Produces the mesh for the TerrainPatch.
 * This LOD algorithm generates a single triangle strip by first building the center of the
 * mesh, minus one outer edge around it. Then it builds the edges in counter-clockwise order,
 * starting at the bottom right and working up, then left across the top, then down across the
 * left, then right across the bottom.
 * It needs to know what its neighbour's LOD's are so it can stitch the edges.
 * It creates degenerate polygons in order to keep the winding order of the polygons and to move
 * the strip to a new position while still maintaining the continuity of the overall mesh. These
 * degenerates are removed quickly by the video card.
 *
 * @author Brent Owens
 */
class LODGeomap extends GeoMap
{

	public function new(heightData:Vector<Float>, width:Int, height:Int, maxval:Int = 1) 
	{
		super(heightData, width, height, maxval);	
	}
	
	public function createLodMesh(scale:Vector3f, tcScale:Vector2f, tcOffset:Vector2f, offsetAmount:Float, totalSize:Int, center:Bool, lod:Int = 1, rightLod:Bool = false, topLod:Bool = false, leftLod:Bool = false, bottomLod:Bool = false):Mesh
	{
        var pb:Vector<Float> = writeVertexArray(null, scale, center);
        var texb:Vector<Float> = writeLodTexCoordArray(null, tcOffset, tcScale, offsetAmount, totalSize);
        var nb:Vector<Float> = writeNormalArray(null, scale);
		
        var ib:Vector<UInt> = writeIndexArrayLodDiff(lod, rightLod, topLod, leftLod, bottomLod, totalSize);
		
		var bb:Vector<Float> = new Vector<Float>(getWidth() * getHeight() * 3);
		var tanb:Vector<Float> = new Vector<Float>(getWidth() * getHeight() * 3);
		
		writeTangentArray(nb, tanb, bb, texb, scale);

        var m:Mesh = new Mesh();
        m.setVertexBuffer(BufferType.POSITION, 3, pb);
        m.setVertexBuffer(BufferType.NORMAL, 3, nb);
		m.setVertexBuffer(BufferType.TANGENT, 3, tanb);
		m.setVertexBuffer(BufferType.BINORMAL, 3, bb);
        m.setVertexBuffer(BufferType.TEXCOORD, 2, texb);
        m.setIndices(ib);
        m.setStatic();
        m.validate();
        return m;
    }
	
	public function writeLodTexCoordArray(store:Vector<Float>, offset:Vector2f, scale:Vector2f, offsetAmount:Float, totalSize:Int):Vector<Float>
	{
		if (store == null)
			store = new Vector<Float>();
			
		if (offset == null)
			offset = new Vector2f();
		
		var index:Int = 0;
        var tcStore:Vector2f = new Vector2f();
        // work from bottom of heightmap up, so we don't flip the coords
		var y:Int = getHeight() - 1;
		while (y >= 0)
		{
			for (x in 0...getWidth())
			{
				getLodUV(x, y, tcStore, offset, offsetAmount, totalSize);
				var tx:Float = tcStore.x * scale.x;
				var ty:Float = tcStore.y * scale.y;
				store[index++] = tx;
				store[index++] = ty;
			}
			y--;
		}
		
		return store;
	}
	
	public function getLodUV(x:Int, y:Int, store:Vector2f, offset:Vector2f, offsetAmount:Float, totalSize:Int):Vector2f
	{
		var offsetX:Float = offset.x + (offsetAmount * 1.0);
        var offsetY:Float = -offset.y + (offsetAmount * 1.0);//note the -, we flip the tex coords

        store.setTo((x + offsetX) / (totalSize - 1), // calculates percentage of texture here
                (y + offsetY) / (totalSize - 1));
        return store;
	}
	
	/**
     * Create the LOD index array that will seam its edges with its neighbour's LOD.
     * This is a scary method!!! It will break your mind.
     *
     * @param store to store the index buffer
     * @param lod level of detail of the mesh
     * @param rightLod LOD of the right neighbour
     * @param topLod LOD of the top neighbour
     * @param leftLod LOD of the left neighbour
     * @param bottomLod LOD of the bottom neighbour
     * @return the LOD-ified index buffer
     */
    public function writeIndexArrayLodDiff(lod:Int, rightLod:Bool, topLod:Bool, leftLod:Bool, bottomLod:Bool, totalSize:Int):Vector<UInt>
	{
        var numIndexes:Int = calculateNumIndexesLodDiff(lod);
        
        var indices:Vector<UInt> = new Vector<UInt>();


        // generate center squares minus the edges
        //System.out.println("for (x="+lod+"; x<"+(getWidth()-(2*lod))+"; x+="+lod+")");
        //System.out.println("	for (z="+lod+"; z<"+(getWidth()-(1*lod))+"; z+="+lod+")");
		var r:Int = lod;
		while (r < getWidth() - (2 * lod)) // row
		{
			var rowIdx:Int = r * getWidth();
			var nextRowIdx:Int = (r + 1 * lod) * getWidth();
			
			var c:Int = lod;
			while (c < getWidth() - (1 * lod)) // column
			{
				var idx:Int = rowIdx + c;
				indices.push(idx);
				idx = nextRowIdx + c;
				indices.push(idx);
				c += lod;
			}
			
			// add degenerate triangles
			if (r < getWidth() - (3 * lod))
			{
				var idx:Int = nextRowIdx + getWidth() - (1 * lod) - 1;
				indices.push(idx);
				idx = nextRowIdx + (1 * lod); // inset by 1
				indices.push(idx);
			}
			
			r += lod;
		}
        //System.out.println("\nright:");

        //int runningBufferCount = buffer.getCount();
        //System.out.println("buffer start: "+runningBufferCount);


        // right
        var br:Int = getWidth() * (getWidth() - lod) - 1 - lod;
        indices.push(br); // bottom right -1
        var corner:Int = getWidth() * getWidth() - 1;
        indices.push(corner);	// bottom right corner
        if (rightLod) // if lower LOD
		{ 
			var row:Int = getWidth() - lod;
            while ( row >= 1 + lod)
			{
                var idx:Int = (row) * getWidth() - 1 - lod;
                indices.push(idx);
                idx = (row - lod) * getWidth() - 1;
                indices.push(idx);
                if (row > lod + 1) //if not the last one
				{ 
                    idx = (row - lod) * getWidth() - 1 - lod;
                    indices.push(idx);
                    idx = (row - lod) * getWidth() - 1;
                    indices.push(idx);
                } 
				else 
				{
                }
				
				row -= 2 * lod;
            }
        } 
		else
		{
            indices.push(corner);//br+1);//degenerate to flip winding order
			
			var row:Int = getWidth() - lod;
            while ( row > lod)
			{
                var idx:Int = row * getWidth() - 1; // mult to get row
                indices.push(idx);
                indices.push(idx - lod);
				
				row -= lod;
            }

        }

        indices.push(getWidth() - 1);


        //System.out.println("\nbuffer right: "+(buffer.getCount()-runningBufferCount));
        //runningBufferCount = buffer.getCount();


        //System.out.println("\ntop:");

        // top 			(the order gets reversed here so the diagonals line up)
        if (topLod) // if lower LOD
		{ 
            if (rightLod)
			{
                indices.push(getWidth() - 1);
            }
			
			var col:Int = getWidth() - 1;
            while ( col >= lod) 
			{
                var idx:Int = (lod * getWidth()) + col - lod; // next row
                indices.push(idx);
                idx = col - 2 * lod;
                indices.push(idx);
                if (col > lod * 2) //if not the last one
				{ 
                    idx = (lod * getWidth()) + col - 2 * lod;
                    indices.push(idx);
                    idx = col - 2 * lod;
                    indices.push(idx);
                }
				else 
				{
                }
				
				col -= 2 * lod;
            }
        } 
		else
		{
            if (rightLod)
			{
                indices.push(getWidth() - 1);
            }
			
			var col:Int = getWidth() - 1 - lod;
            while ( col > 0) 
			{
                var idx:Int = col + (lod * getWidth());
                indices.push(idx);
                idx = col;
                indices.push(idx);
				
				col -= lod;
            }
            indices.push(0);
        }
        indices.push(0);

        //System.out.println("\nbuffer top: "+(buffer.getCount()-runningBufferCount));
        //runningBufferCount = buffer.getCount();

        //System.out.println("\nleft:");

        // left
        if (leftLod) // if lower LOD
		{ 
            if (topLod)
			{
                indices.push(0);
            }
			
			var row:Int = 0; 
            while (row < getWidth() - lod)
			{
                var idx:Int = (row + lod) * getWidth() + lod;
                indices.push(idx);
                idx = (row + 2 * lod) * getWidth();
                indices.push(idx);
                if (row < getWidth() - 1 - 2 * lod) { //if not the last one
                    idx = (row + 2 * lod) * getWidth() + lod;
                    indices.push(idx);
                    idx = (row + 2 * lod) * getWidth();
                    indices.push(idx);
                } 
				else
				{
                }
				
				 row += 2 * lod;
            }
        } 
		else
		{
            if (!topLod) 
			{
                indices.push(0);
            }
            //indices.push(getWidth()+1); // degenerate
            //indices.push(0); // degenerate winding-flip
			
			var row:Int = lod; 
            while (row < getWidth() - lod)
			{
                var idx:Int = row * getWidth();
                indices.push(idx);
                idx = row * getWidth() + lod;
                indices.push(idx);
				
				row += lod;
            }

        }
        indices.push(getWidth() * (getWidth() - 1));


        //System.out.println("\nbuffer left: "+(buffer.getCount()-runningBufferCount));
        //runningBufferCount = buffer.getCount();

        //if (true) return buffer.delegate;
        //System.out.println("\nbottom");

        // bottom
        if (bottomLod) // if lower LOD
		{ 
            if (leftLod)
			{
                indices.push(getWidth() * (getWidth() - 1));
            }
            // there was a slight bug here when really high LOD near maxLod
            // far right has extra index one row up and all the way to the right, need to skip last index entered
            // seemed to be fixed by making "getWidth()-1-2-lod" this: "getWidth()-1-2*lod", which seems more correct
			var col:Int = 0; 
            while (col < getWidth() - lod) 
			{
                var idx:Int = getWidth() * (getWidth() - 1 - lod) + col + lod;
                indices.push(idx);
                idx = getWidth() * (getWidth() - 1) + col + 2 * lod;
                indices.push(idx);
                if (col < getWidth() - 1 - 2 * lod) { //if not the last one
                    idx = getWidth() * (getWidth() - 1 - lod) + col + 2 * lod;
                    indices.push(idx);
                    idx = getWidth() * (getWidth() - 1) + col + 2 * lod;
                    indices.push(idx);
                } 
				else
				{
                }
				
				col += 2 * lod;
            }
        }
		else
		{
            if (leftLod)
			{
                indices.push(getWidth() * (getWidth() - 1));
            }
			
			var col:Int = lod;
            while ( col < getWidth() - lod) 
			{
                var idx:Int = getWidth() * (getWidth() - 1 - lod) + col; // up
                indices.push(idx);
                idx = getWidth() * (getWidth() - 1) + col; // down
                indices.push(idx);
				
				col += lod;
            }
            //indices.push(getWidth()*getWidth()-1-lod); // <-- THIS caused holes at the end!
        }

        indices.push(getWidth() * getWidth() - 1);

        //System.out.println("\nbuffer bottom: "+(buffer.getCount()-runningBufferCount));
        //runningBufferCount = buffer.getCount();

        //System.out.println("\nBuffer size: "+buffer.getCount());

        // fill in the rest of the buffer with degenerates, there should only be a couple
        for (i in indices.length...numIndexes)
		{
            indices.push(getWidth() * getWidth() - 1);
        }

        return indices;
    }

    public function writeIndexArrayLodVariable(lod:Int, rightLod:Int, topLod:Int, leftLod:Int, bottomLod:Int, totalSize:Int):Vector<UInt>
	{

        var numIndexes:Int = calculateNumIndexesLodDiff(lod);
        
        var indices:Vector<UInt> = new Vector<UInt>();

        // generate center squares minus the edges
        //System.out.println("for (x="+lod+"; x<"+(getWidth()-(2*lod))+"; x+="+lod+")");
        //System.out.println("	for (z="+lod+"; z<"+(getWidth()-(1*lod))+"; z+="+lod+")");
		
		var r:Int = lod; 
        while (r < getWidth() - (2 * lod)) // row
		{ 
            var rowIdx:Int = r * getWidth();
            var nextRowIdx:Int = (r + 1 * lod) * getWidth();
			
			var c:Int = lod; 
            while (c < getWidth() - (1 * lod)) // column
			{ 
                var idx:Int = rowIdx + c;
                indices.push(idx);
                idx = nextRowIdx + c;
                indices.push(idx);
				
				c += lod;
            }

            // add degenerate triangles
            if (r < getWidth() - (3 * lod))
			{
                var idx:Int = nextRowIdx + getWidth() - (1 * lod) - 1;
                indices.push(idx);
                idx = nextRowIdx + (1 * lod); // inset by 1
                indices.push(idx);
                //System.out.println("");
            }
			
			r += lod;
        }
        //System.out.println("\nright:");

        //int runningBufferCount = buffer.getCount();
        //System.out.println("buffer start: "+runningBufferCount);


        // right
        var br:Int = getWidth() * (getWidth() - lod) - 1 - lod;
        indices.push(br); // bottom right -1
        var corner:Int = getWidth() * getWidth() - 1;
        indices.push(corner);	// bottom right corner
        if (rightLod > lod) // if lower LOD
		{ 
            var idx:Int = corner;
            var it:Int = Std.int((getWidth() - 1) / rightLod); // iterations
            var lodDiff:Int = Std.int(rightLod / lod);
			
			var i:Int = it; 
            while (i > 0) // for each lod level of the neighbour
			{ 
                idx = getWidth() * (i * rightLod + 1) - 1;
                for (j in 1...(lodDiff + 1)) // for each section in that lod level
				{ 
                    var idxB:Int = idx - (getWidth() * (j * lod)) - lod;

                    if (j == lodDiff && i == 1) // the last one
					{
                        indices.push(getWidth() - 1);
                    } 
					else if (j == lodDiff)
					{
                        indices.push(idxB);
                        indices.push(idxB + lod);
                    }
					else 
					{
                        indices.push(idxB);
                        indices.push(idx);
                    }
                }
				
				 i--;
            }
            // reset winding order
            indices.push(getWidth() * (lod + 1) - lod - 1); // top-right +1row
            indices.push(getWidth() - 1);// top-right

        } 
		else
		{
            indices.push(corner);//br+1);//degenerate to flip winding order
			
			var row:Int = getWidth() - lod;
            while ( row > lod) 
			{
                var idx:Int = row * getWidth() - 1; // mult to get row
                indices.push(idx);
                indices.push(idx - lod);
				
				row -= lod;
            }
            indices.push(getWidth() - 1);
        }


        //System.out.println("\nbuffer right: "+(buffer.getCount()-runningBufferCount));
        //runningBufferCount = buffer.getCount();


        //System.out.println("\ntop:");

        // top 			(the order gets reversed here so the diagonals line up)
        if (topLod > lod) // if lower LOD
		{
            if (rightLod > lod)
			{
                // need to flip winding order
                indices.push(getWidth() - 1);
                indices.push(getWidth() * lod - 1);
                indices.push(getWidth() - 1);
            }
            var idx:Int = getWidth() - 1;
            var it:Int = Std.int((getWidth() - 1) / topLod); // iterations
            var lodDiff:Int = Std.int(topLod / lod);
			
			var i:Int = it; 
            while (i > 0)// for each lod level of the neighbour
			{ 
                idx = (i * topLod);
                for (j in 1...(lodDiff + 1))// for each section in that lod level
				{ 
                    var idxB:Int = lod * getWidth() + (i * topLod) - (j * lod);

                    if (j == lodDiff && i == 1) // the last one
					{
                        indices.push(0);
                    } 
					else if (j == lodDiff)
					{
                        indices.push(idxB);
                        indices.push(idx - topLod);
                    }
					else
					{
                        indices.push(idxB);
                        indices.push(idx);
                    }
                }
				
				 i--;
            }
        } 
		else
		{
            if (rightLod > lod) 
			{
                indices.push(getWidth() - 1);
            }
			
			var col:Int = getWidth() - 1 - lod;
            while ( col > 0) 
			{
                var idx:Int = col + (lod * getWidth());
                indices.push(idx);
                idx = col;
                indices.push(idx);
				
				col -= lod;
            }
            indices.push(0);
        }
        indices.push(0);

        //System.out.println("\nbuffer top: "+(buffer.getCount()-runningBufferCount));
        //runningBufferCount = buffer.getCount();

        //System.out.println("\nleft:");

        // left
        if (leftLod > lod) // if lower LOD
		{ 

            var idx:Int = 0;
            var it:Int = Std.int((getWidth() - 1) / leftLod); // iterations
            var lodDiff:Int = Std.int(leftLod / lod);
            for (i in 0...it) // for each lod level of the neighbour
			{ 
                idx = getWidth() * (i * leftLod);
                for (j in 1...(lodDiff + 1))  // for each section in that lod level
				{
                    var idxB:Int = idx + (getWidth() * (j * lod)) + lod;

                    if (j == lodDiff && i == it - 1) // the last one
					{
                        indices.push(getWidth() * getWidth() - getWidth());
                    }
					else if (j == lodDiff)
					{
                        indices.push(idxB);
                        indices.push(idxB - lod);
                    }
					else
					{
                        indices.push(idxB);
                        indices.push(idx);
                    }
                }
            }

        } 
		else 
		{
            indices.push(0);
            indices.push(getWidth() * lod + lod);
            indices.push(0);
			
			var row:Int = lod; 
            while (row < getWidth() - lod) 
			{
                var idx:Int = row * getWidth();
                indices.push(idx);
                idx = row * getWidth() + lod;
                indices.push(idx);
				
				row += lod;
            }
            indices.push(getWidth() * (getWidth() - 1));
        }
        //indices.push(getWidth()*(getWidth()-1));


        //System.out.println("\nbuffer left: "+(buffer.getCount()-runningBufferCount));
        //runningBufferCount = buffer.getCount();

        //if (true) return buffer.delegate;
        //System.out.println("\nbottom");

        // bottom
        if (bottomLod > lod) // if lower LOD
		{ 
            if (leftLod > lod) 
			{
                indices.push(getWidth() * (getWidth() - 1));
                indices.push(getWidth() * (getWidth() - lod));
                indices.push(getWidth() * (getWidth() - 1));
            }

            var idx:Int = getWidth() * getWidth() - getWidth();
            var it:Int = Std.int((getWidth() - 1) / bottomLod); // iterations
            var lodDiff:Int = Std.int(bottomLod / lod);
            for (i in 0...it) // for each lod level of the neighbour
			{ 
                idx = getWidth() * getWidth() - getWidth() + (i * bottomLod);
                for (j in 1...(lodDiff + 1)) // for each section in that lod level
				{ 
                    var idxB:Int = idx - (getWidth() * lod) + j * lod;

                    if (j == lodDiff && i == it - 1)// the last one
					{
                        indices.push(getWidth() * getWidth() - 1);
                    } 
					else if (j == lodDiff) 
					{
                        indices.push(idxB);
                        indices.push(idx + bottomLod);
                    } 
					else
					{
                        indices.push(idxB);
                        indices.push(idx);
                    }
                }
            }
        }
		else
		{
            if (leftLod > lod) 
			{
                indices.push(getWidth() * (getWidth() - 1));
                indices.push(getWidth() * getWidth() - (getWidth() * lod) + lod);
                indices.push(getWidth() * (getWidth() - 1));
            }
			
			var col:Int = lod; 
            while (col < getWidth() - lod)
			{
                var idx:Int = getWidth() * (getWidth() - 1 - lod) + col; // up
                indices.push(idx);
                idx = getWidth() * (getWidth() - 1) + col; // down
                indices.push(idx);
				
				col += lod;
            }
            //indices.push(getWidth()*getWidth()-1-lod); // <-- THIS caused holes at the end!
        }

        indices.push(getWidth() * getWidth() - 1);

        //System.out.println("\nbuffer bottom: "+(buffer.getCount()-runningBufferCount));
        //runningBufferCount = buffer.getCount();

        //System.out.println("\nBuffer size: "+buffer.getCount());

        // fill in the rest of the buffer with degenerates, there should only be a couple
        for (i in indices.length...numIndexes)
		{
            indices.push(getWidth() * getWidth() - 1);
        }

        return indices;
    }


    /*private int calculateNumIndexesNormal(int lod) {
    int length = getWidth()-1;
    int num = ((length/lod)+1)*((length/lod)+1)*2;
    System.out.println("num: "+num);
    num -= 2*((length/lod)+1);
    System.out.println("num2: "+num);
    // now get the degenerate indexes that exist between strip rows
    num += 2*(((length/lod)+1)-2); // every row except the first and last
    System.out.println("Index buffer size: "+num);
    return num;
    }*/
    /**
     * calculate how many indexes there will be.
     * This isn't that precise and there might be a couple extra.
     */
    private function calculateNumIndexesLodDiff(lod:Int):Int
	{
        if (lod == 0)
		{
            lod = 1;
        }
        var length:Int = getWidth() - 1; // make it even for lod calc
        var side:Int = Std.int(length / lod) + 1 - (2);
        //System.out.println("side: "+side);
        var num:Int = side * side * 2;
        //System.out.println("num: "+num);
        num -= 2 * side;	// remove one first row and one last row (they are only hit once each)
        //System.out.println("num2: "+num);
        // now get the degenerate indexes that exist between strip rows
        var degenerates:Int = 2 * (side - (2)); // every row except the first and last
        num += degenerates;
        //System.out.println("degenerates: "+degenerates);

        //System.out.println("center, before edges: "+num);

        num += Std.int(getWidth() / lod) * 2 * 4;
        num++;

        num += 10;// TODO remove me: extra
        //System.out.println("Index buffer size: "+num);
        return num;
    }

    public function writeTangentArray(normalBuffer:Vector<Float>, 
									tangentStore:Vector<Float>, 
									binormalStore:Vector<Float>, 
									textureBuffer:Vector<Float>, 
									scale:Vector3f):Array<Vector<Float>>
	{
        if (!isLoaded())
		{
           throw "not loaded";
        }
		
		if (tangentStore == null)
		{
			tangentStore = new Vector<Float>();
		}
		
		if (binormalStore == null)
		{
			binormalStore = new Vector<Float>();
		}

        var normal:Vector3f = new Vector3f();
        var tangent:Vector3f = new Vector3f();
        var binormal:Vector3f = new Vector3f();
        /*Vector3f v1 = new Vector3f();
        Vector3f v2 = new Vector3f();
        Vector3f v3 = new Vector3f();
        Vector2f t1 = new Vector2f();
        Vector2f t2 = new Vector2f();
        Vector2f t3 = new Vector2f();*/

        for (r in 0...getHeight())
		{
            for (c in 0...getWidth())
			{
                
                var idx:Int = (r * getWidth() + c) * 3;
                normal.setTo(normalBuffer[idx], normalBuffer[idx+1], normalBuffer[idx+2]);
                tangent.copyFrom(normal.cross(new Vector3f(0,0,1)));
                binormal.copyFrom(new Vector3f(1,0,0).cross(normal));
                
                BufferUtils.setInBuffer(tangent.normalizeLocal(), tangentStore, (r * getWidth() + c)); // save the tangent
                BufferUtils.setInBuffer(binormal.normalizeLocal(), binormalStore, (r * getWidth() + c)); // save the binormal
            }
        }

/*        for (int r = 0; r < getHeight(); r++) {
            for (int c = 0; c < getWidth(); c++) {

                int texIdx = ((getHeight() - 1 - r) * getWidth() + c) * 2; // pull from the end
                int texIdxAbove = ((getHeight() - 1 - (r - 1)) * getWidth() + c) * 2; // pull from the end
                int texIdxNext = ((getHeight() - 1 - (r + 1)) * getWidth() + c) * 2; // pull from the end

                v1.set(c, getValue(c, r), r);
                t1.set(textureBuffer.get(texIdx), textureBuffer.get(texIdx + 1));

                // below
                if (r == getHeight()-1) { // last row
                    v3.set(c, getValue(c, r), r + 1);
                    float u = textureBuffer.get(texIdx) - textureBuffer.get(texIdxAbove);
                    u += textureBuffer.get(texIdx);
                    float v = textureBuffer.get(texIdx + 1) - textureBuffer.get(texIdxAbove + 1);
                    v += textureBuffer.get(texIdx + 1);
                    t3.set(u, v);
                } else {
                    v3.set(c, getValue(c, r + 1), r + 1);
                    t3.set(textureBuffer.get(texIdxNext), textureBuffer.get(texIdxNext + 1));
                }
                
                //right
                if (c == getWidth()-1) { // last column
                    v2.set(c + 1, getValue(c, r), r);
                    float u = textureBuffer.get(texIdx) - textureBuffer.get(texIdx - 2);
                    u += textureBuffer.get(texIdx);
                    float v = textureBuffer.get(texIdx + 1) - textureBuffer.get(texIdx - 1);
                    v += textureBuffer.get(texIdx - 1);
                    t2.set(u, v);
                } else {
                    v2.set(c + 1, getValue(c + 1, r), r); // one to the right
                    t2.set(textureBuffer.get(texIdx + 2), textureBuffer.get(texIdx + 3));
                }

                calculateTangent(new Vector3f[]{v1.mult(scale), v2.mult(scale), v3.mult(scale)}, new Vector2f[]{t1, t2, t3}, tangent, binormal);
                BufferUtils.setInBuffer(tangent, tangentStore, (r * getWidth() + c)); // save the tangent
                BufferUtils.setInBuffer(binormal, binormalStore, (r * getWidth() + c)); // save the binormal
            }
        }
        */
        return [tangentStore, binormalStore];
    }

    /**
     * 
     * @param v Takes 3 vertices: root, right, bottom
     * @param t Takes 3 tex coords: root, right, bottom
     * @param tangent that will store the result
     * @return the tangent store
     */
    public static function calculateTangent(v:Array<Vector3f>, t:Array<Vector2f>, tangent:Vector3f, binormal:Vector3f):Vector3f
	{
        var edge1:Vector3f = new Vector3f(); // y=0
        var edge2:Vector3f = new Vector3f(); // x=0
        var edge1uv:Vector2f = new Vector2f(); // y=0
        var edge2uv:Vector2f = new Vector2f(); // x=0

        t[2].subtract(t[0], edge2uv);
        t[1].subtract(t[0], edge1uv);

        var det:Float = edge1uv.x * edge2uv.y;// - edge1uv.y*edge2uv.x;  = 0

        var normalize:Bool = true;
        if (Math.abs(det) < 0.0000001)
		{
            det = 1;
            normalize = true;
        }

        v[1].subtract(v[0], edge1);
        v[2].subtract(v[0], edge2);

        tangent.copyFrom(edge1);
        tangent.normalizeLocal();
        binormal.copyFrom(edge2);
        binormal.normalizeLocal();

        var factor:Float = 1 / det;
        tangent.x = (edge2uv.y * edge1.x) * factor;
        tangent.y = 0;
        tangent.z = (edge2uv.y * edge1.z) * factor;
        if (normalize) 
		{
            tangent.normalizeLocal();
        }

        binormal.x = 0;
        binormal.y = (edge1uv.x * edge2.y) * factor;
        binormal.z = (edge1uv.x * edge2.z) * factor;
        if (normalize)
		{
            binormal.normalizeLocal();
        }

        return tangent;
    }

	override public function writeNormalArray(store:Vector<Float>, scale:Vector3f):Vector<Float> 
	{
		if (!isLoaded()) 
		{
            throw "not loaded";
        }

        if (store == null)
		{
			store = new Vector<Float>();
        }   

        var vars:TempVars = TempVars.getTempVars();
        
        var rootPoint:Vector3f = vars.vect1;
        var rightPoint:Vector3f = vars.vect2;
        var leftPoint:Vector3f = vars.vect3;
        var topPoint:Vector3f = vars.vect4;
        var bottomPoint:Vector3f = vars.vect5;
        
        var tmp1:Vector3f = vars.vect6;

        // calculate normals for each polygon
        for (r in 0...getHeight())
		{
            for (c in 0...getWidth())
			{

                rootPoint.setTo(0, getValue(c, r), 0);
                var normal:Vector3f = vars.vect8;

                if (r == 0)// first row
				{ 
                    if (c == 0) // first column
					{ 
                        rightPoint.setTo(1, getValue(c + 1, r), 0);
                        bottomPoint.setTo(0, getValue(c, r + 1), 1);
                        getNormal(bottomPoint, rootPoint, rightPoint, scale, normal);
                    } 
					else if (c == getWidth() - 1) // last column
					{ 
                        leftPoint.setTo(-1, getValue(c - 1, r), 0);
                        bottomPoint.setTo(0, getValue(c, r + 1), 1);
                        getNormal(leftPoint, rootPoint, bottomPoint, scale, normal);
                    } 
					else // all middle columns
					{
                        leftPoint.setTo(-1, getValue(c - 1, r), 0);
                        rightPoint.setTo(1, getValue(c + 1, r), 0);
                        bottomPoint.setTo(0, getValue(c, r + 1), 1);
                        
                        normal.copyFrom( getNormal(leftPoint, rootPoint, bottomPoint, scale, tmp1) );
                        normal.addLocal( getNormal(bottomPoint, rootPoint, rightPoint, scale, tmp1) );
                    }
                } 
				else if (r == getHeight() - 1) // last row
				{
                    if (c == 0) // first column
					{ 
                        topPoint.setTo(0, getValue(c, r - 1), -1);
                        rightPoint.setTo(1, getValue(c + 1, r), 0);
                        getNormal(rightPoint, rootPoint, topPoint, scale, normal);
                    } 
					else if (c == getWidth() - 1) // last column
					{
                        topPoint.setTo(0, getValue(c, r - 1), -1);
                        leftPoint.setTo(-1, getValue(c - 1, r), 0);
                        getNormal(topPoint, rootPoint, leftPoint, scale, normal);
                    } 
					else// all middle columns
					{ 
                        topPoint.setTo(0, getValue(c, r - 1), -1);
                        leftPoint.setTo(-1, getValue(c - 1, r), 0);
                        rightPoint.setTo(1, getValue(c + 1, r), 0);
                        
                        normal.copyFrom( getNormal(topPoint, rootPoint, leftPoint, scale, tmp1) );
                        normal.addLocal( getNormal(rightPoint, rootPoint, topPoint, scale, tmp1) );
                    }
                }
				else // all middle rows
				{ 
                    if (c == 0)// first column
					{ 
                        topPoint.setTo(0, getValue(c, r - 1), -1);
                        rightPoint.setTo(1, getValue(c + 1, r), 0);
                        bottomPoint.setTo(0, getValue(c, r + 1), 1);
                        
                        normal.copyFrom( getNormal(rightPoint, rootPoint, topPoint, scale, tmp1) );
                        normal.addLocal( getNormal(bottomPoint, rootPoint, rightPoint, scale, tmp1) );
                    } 
					else if (c == getWidth() - 1) // last column
					{ 
                        topPoint.setTo(0, getValue(c, r - 1), -1);
                        leftPoint.setTo(-1, getValue(c - 1, r), 0);
                        bottomPoint.setTo(0, getValue(c, r + 1), 1);

                        normal.copyFrom( getNormal(topPoint, rootPoint, leftPoint, scale, tmp1) );
                        normal.addLocal( getNormal(leftPoint, rootPoint, bottomPoint, scale, tmp1) );
                    } 
					else  // all middle columns
					{
                        topPoint.setTo(0, getValue(c, r - 1), -1);
                        leftPoint.setTo(-1, getValue(c - 1, r), 0);
                        rightPoint.setTo(1, getValue(c + 1, r), 0);
                        bottomPoint.setTo(0, getValue(c, r + 1), 1);
                        
                        normal.copyFrom( getNormal(topPoint,  rootPoint, leftPoint, scale, tmp1 ) );
                        normal.addLocal( getNormal(leftPoint, rootPoint, bottomPoint, scale, tmp1) );
                        normal.addLocal( getNormal(bottomPoint, rootPoint, rightPoint, scale, tmp1) );
                        normal.addLocal( getNormal(rightPoint, rootPoint, topPoint, scale, tmp1) );
                    }
                }
                normal.normalizeLocal();
                BufferUtils.setInBuffer(normal, store, (r * getWidth() + c)); // save the normal
            }
        }
        vars.release();
        
        return store;
	}

    public function getNormal(firstPoint:Vector3f, rootPoint:Vector3f, secondPoint:Vector3f, scale:Vector3f, store:Vector3f):Vector3f
	{
        var x1:Float = firstPoint.x - rootPoint.x;
        var y1:Float = firstPoint.y - rootPoint.y;
        var z1:Float = firstPoint.z - rootPoint.z;
        x1 *= scale.x;
        y1 *= scale.y;
        z1 *= scale.z;
        var x2:Float = secondPoint.x - rootPoint.x;
        var y2:Float = secondPoint.y - rootPoint.y;
        var z2:Float = secondPoint.z - rootPoint.z;
        x2 *= scale.x;
        y2 *= scale.y;
        z2 *= scale.z;
        var x3:Float = (y1 * z2) - (z1 * y2);
        var y3:Float = (z1 * x2) - (x1 * z2);
        var z3:Float = (x1 * y2) - (y1 * x2);
        
        var inv:Float = 1.0 / Math.sqrt(x3 * x3 + y3 * y3 + z3 * z3);
        store.x = x3 * inv;
        store.y = y3 * inv;
        store.z = z3 * inv;
        
        
        /*firstPoint.multLocal(scale);
        rootPoint.multLocal(scale);
        secondPoint.multLocal(scale);
        firstPoint.subtractLocal(rootPoint);
        secondPoint.subtractLocal(rootPoint);
        firstPoint.cross(secondPoint, store);*/
        return store;
    }

    /**
     * Get the two triangles that make up the grid section at the specified point.
     *
     * For every grid space there are two triangles oriented like this:
     *  *----*
     *  |a / |
     *  | / b|
     *  *----*
     * The corners of the mesh have differently oriented triangles. The two
     * corners that we have to special-case are the top left and bottom right
     * corners. They are oriented inversely:
     *  *----*
     *  | \ b|
     *  |a \ |
     *  *----*
     */
    public function getHeightXZ(x:Float, z:Float, xm:Float, zm:Float):Float
	{
        var index:Int = findClosestHeightIndex(Std.int(x), Std.int(z));
        if (index < 0)
		{
            return Math.NaN;
        }
        
        var h1:Float = hdata[index];                // top left
        var h2:Float = hdata[index + 1];            // top right
        var h3:Float = hdata[index + width];        // bottom left
        var h4:Float = hdata[index + width + 1];    // bottom right

        //float dix = (x % 1f) ;
        //float diz = (z % 1f) ;
            
        if ((x == 0 && z == 0) || (x == width - 2 && z == width - 2)) 
		{
            // top left or bottom right grid point
            /*  1----2
             *  | \ b|
             *  |a \ |
             *  3----4 */
            if (xm < zm)
                return h1 + xm * (h4 - h3) + zm * (h3 - h1);
            else
                return h1 + xm * (h2 - h1) + zm * (h4 - h2);
            
        } 
		else
		{
            // all other grid points
            /*  1----2
             *  |a / |
             *  | / b|
             *  3----4 */
            if (xm<(1-zm))
                return h3 + (xm) * (h2 - h1) + (1 - zm) * (h1 - h3);
            else
                return h3 + (xm) * (h4 - h3) + (1 - zm) * (h2 - h4);
        }
    }
    
    /**
     * Get a representation of the underlying triangle at the given point,
     * translated to world coordinates.
     * 
     * @param x local x coordinate
     * @param z local z coordinate
     * @return a triangle in world space not local space
     */
    public function getTriangleAtPointScaleAndTranslation(x:Float, z:Float, scale:Vector3f, translation:Vector3f):Triangle
	{
        var tri:Triangle = getTriangleAtPoint(x, z);
        if (tri != null) 
		{
            tri.point1.multLocal(scale).addLocal(translation);
            tri.point2.multLocal(scale).addLocal(translation);
            tri.point3.multLocal(scale).addLocal(translation);
        }
        return tri;
    }

    /**
     * Get the two triangles that make up the grid section at the specified point,
     * translated to world coordinates.
     *
     * @param x local x coordinate
     * @param z local z coordinate
     * @param scale
     * @param translation
     * @return two triangles in world space not local space
     */
    public function getGridTrianglesAtPointScaleAndTranslation(x:Float, z:Float, scale:Vector3f, translation:Vector3f):Array<Triangle>
	{
        var tris:Array<Triangle> = getGridTrianglesAtPoint(x, z);
        if (tris != null) 
		{
            tris[0].point1.multLocal(scale).addLocal(translation);
            tris[0].point2.multLocal(scale).addLocal(translation);
            tris[0].point3.multLocal(scale).addLocal(translation);
            tris[1].point1.multLocal(scale).addLocal(translation);
            tris[1].point2.multLocal(scale).addLocal(translation);
            tris[1].point3.multLocal(scale).addLocal(translation);
        }
        return tris;
    }

    /**
     * Get the two triangles that make up the grid section at the specified point.
     *
     * For every grid space there are two triangles oriented like this:
     *  *----*
     *  |a / |
     *  | / b|
     *  *----*
     * The corners of the mesh have differently oriented triangles. The two
     * corners that we have to special-case are the top left and bottom right
     * corners. They are oriented inversely:
     *  *----*
     *  | \ b|
     *  |a \ |
     *  *----*
     *
     * @param x local x coordinate
     * @param z local z coordinate
     * @return
     */
    public function getGridTrianglesAtPoint(x:Float, z:Float):Array<Triangle>
	{
        var gridX:Int = Std.int(x);
        var gridY:Int = Std.int(z);

        var index:Int = findClosestHeightIndex(gridX, gridY);
        if (index < 0) {
            return null;
        }

        var t:Triangle = new Triangle(new Vector3f(), new Vector3f(), new Vector3f());
        var t2:Triangle = new Triangle(new Vector3f(), new Vector3f(), new Vector3f());

        var h1:Float = hdata[index];                // top left
        var h2:Float = hdata[index + 1];            // top right
        var h3:Float = hdata[index + width];        // bottom left
        var h4:Float = hdata[index + width + 1];    // bottom right

        if ((gridX == 0 && gridY == 0) || (gridX == width - 2 && gridY == width - 2))
		{
            // top left or bottom right grid point
            t.point1.x = (gridX);
            t.point1.y = (h1);
            t.point1.z = (gridY);

            t.point2.x = (gridX);
            t.point2.y = (h3);
            t.point2.z = (gridY + 1);

            t.point3.x = (gridX + 1);
            t.point3.y = (h4);
            t.point3.z = (gridY + 1);

            t2.point1.x = (gridX);
            t2.point1.y = (h1);
            t2.point1.z = (gridY);

            t2.point2.x = (gridX + 1);
            t2.point2.y = (h4);
            t2.point2.z = (gridY + 1);

            t2.point3.x = (gridX + 1);
            t2.point3.y = (h2);
            t2.point3.z = (gridY);
        } 
		else 
		{
            // all other grid points
            t.point1.x = (gridX);
            t.point1.y = (h1);
            t.point1.z = (gridY);

            t.point2.x = (gridX);
            t.point2.y = (h3);
            t.point2.z = (gridY + 1);

            t.point3.x = (gridX + 1);
            t.point3.y = (h2);
            t.point3.z = (gridY);

            t2.point1.x = (gridX + 1);
            t2.point1.y = (h2);
            t2.point1.z = (gridY);

            t2.point2.x = (gridX);
            t2.point2.y = (h3);
            t2.point2.z = (gridY + 1);

            t2.point3.x = (gridX + 1);
            t2.point3.y = (h4);
            t2.point3.z = (gridY + 1);
        }

        return [t, t2];
    }

    /**
     * Get the triangle that the point is on.
     * 
     * @param x coordinate in local space to the geomap
     * @param z coordinate in local space to the geomap
     * @return triangle in local space to the geomap
     */
    public function getTriangleAtPoint(x:Float, z:Float):Triangle
	{
        var triangles:Array<Triangle> = getGridTrianglesAtPoint(x, z);
        if (triangles == null) 
		{
            //System.out.println("x,z: " + x + "," + z);
            return null;
        }
        var point:Vector2f = new Vector2f(x, z);
        var t1:Vector2f = new Vector2f(triangles[0].point1.x, triangles[0].point1.z);
        var t2:Vector2f = new Vector2f(triangles[0].point2.x, triangles[0].point2.z);
        var t3:Vector2f = new Vector2f(triangles[0].point3.x, triangles[0].point3.z);

        if (0 != FastMath.pointInsideTriangle(t1, t2, t3, point))
		{
            return triangles[0];
        }

        t1.setTo(triangles[1].point1.x, triangles[1].point1.z);
        t1.setTo(triangles[1].point2.x, triangles[1].point2.z);
        t1.setTo(triangles[1].point3.x, triangles[1].point3.z);

        if (0 != FastMath.pointInsideTriangle(t1, t2, t3, point))
		{
            return triangles[1];
        }

        return null;
    }

    public function findClosestHeightIndex(x:Int, z:Int):Int
	{

        if (x < 0 || x >= width - 1) {
            return -1;
        }
        if (z < 0 || z >= width - 1) {
            return -1;
        }

        return z * width + x;
    }
}