package org.angle3d.scene.shape;


import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.mesh.Mesh;

/**
 * `Quad` represents a rectangular plane in space
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

		var data:Array<Float> = [0.0, 0.0, 0.0, width, 0.0, 0.0, width, height, 0.0, 0.0, height, 0.0];
		setVertexBuffer(BufferType.POSITION, 3, data);

		if (flipCoords)
		{
			data = [0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0];
			
		}
		else
		{
			data = [0.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0];
		}
		setVertexBuffer(BufferType.TEXCOORD, 2, data);

		data = [0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0];
		setVertexBuffer(BufferType.NORMAL, 3, data);

		data = [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0];
		setVertexBuffer(BufferType.COLOR, 3, data);

		var indices:Array<UInt>;
		if (height < 0)
		{
			indices = [0, 1, 2, 0, 2, 3];
		}
		else
		{
			indices = [0, 2, 1, 0, 3, 2];
		}

		setIndices(indices);

		validate();
	}
}

