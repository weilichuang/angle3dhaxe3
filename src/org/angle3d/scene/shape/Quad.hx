package org.angle3d.scene.shape;

import flash.Vector;
import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.mesh.Mesh;

/**
 * <code>Quad</code> represents a rectangular plane in space
 * defined by 4 vertices. The quad's lower-left side is contained
 * at the local space origin (0, 0, 0), while the upper-right
 * side is located at the width/height coordinates (width, height, 0).
 *
 */
class Quad extends Mesh
{
	private var width:Float;
	private var height:Float;

	public function new(width:Float, height:Float, flipCoords:Bool = false)
	{
		super();
		updateGeometry(width, height, flipCoords);
	}

	public function getHeight():Float
	{
		return height;
	}

	public function getWidth():Float
	{
		return width;
	}

	public function updateGeometry(width:Float, height:Float, flipCoords:Bool = false):Void
	{
		this.width = width;
		this.height = height;

		var data:Vector<Float> = Vector.ofArray([0.0, 0.0, 0.0, width, 0.0, 0.0, width, height, 0.0, 0.0, height, 0.0]);
		setVertexBuffer(BufferType.POSITION, 3, data);

		if (flipCoords)
		{
			data = Vector.ofArray([0.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0]);
		}
		else
		{
			data = Vector.ofArray([0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0]);
		}
		setVertexBuffer(BufferType.TEXCOORD, 2, data);

		data = Vector.ofArray([0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0]);
		setVertexBuffer(BufferType.NORMAL, 3, data);

		data = Vector.ofArray([1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0]);
		setVertexBuffer(BufferType.COLOR, 3, data);

		var indices:Vector<UInt>;
		if (height < 0)
		{
			indices = Vector.convert(Vector.ofArray([0, 1, 2, 0, 2, 3]));
		}
		else
		{
			indices = Vector.convert(Vector.ofArray([0, 2, 1, 0, 3, 2]));
		}

		setIndices(indices);

		validate();
	}
}

