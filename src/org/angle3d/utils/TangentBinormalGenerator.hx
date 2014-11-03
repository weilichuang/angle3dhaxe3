package org.angle3d.utils;
import flash.Vector;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector2f;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.mesh.BufferUtils;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.scene.mesh.Usage;
import org.angle3d.scene.mesh.VertexBuffer;
import org.angle3d.scene.Node;
import org.angle3d.scene.shape.WireframeShape;
import org.angle3d.scene.shape.WireframeUtil;
import org.angle3d.scene.Spatial;

/**
 * ...
 * @author weilichuang
 */
class TangentBinormalGenerator
{
	private static inline var ZERO_TOLERANCE:Float = 0.0000001;

    private static var toleranceDot:Float;
    public static var debug:Bool;
	
	static function __init__():Void
	{
		debug = false;
		//setToleranceAngle(45);
	}

    private static function initVertexData(size:Int):Array<VertexData>
	{
        var vertices:Array<VertexData> = new Array<VertexData>();        
        for (i in 0...size)
		{
            vertices[i] = new VertexData();
        }
        return vertices;
    }
	
    public static function genTbnLines(mesh:Mesh, scale:Float):Mesh
	{
        if (mesh.getVertexBuffer(BufferType.TANGENT) == null) 
		{
            return genNormalLines(mesh, scale);
        } 
		else
		{
            return genTangentLines(mesh, scale);
        }
    }
    
    public static function genNormalLines(mesh:Mesh, scale:Float):Mesh
	{
        return WireframeUtil.generateNormalLineShape(mesh, scale);
    }
    
    private static function genTangentLines(mesh:Mesh, scale:Float):Mesh
	{
        return WireframeUtil.generateTangentLineShape(mesh, scale);
    }
	
}

class VertexInfo
{
	public var position:Vector3f;
	public var normal:Vector3f;
	public var texCoord:Vector2f;
	public var indices:Vector<UInt> = new Vector<UInt>();
	
	public function new(position:Vector3f, normal:Vector3f, texCoord:Vector2f) 
	{
		this.position = position;
		this.normal = normal;
		this.texCoord = texCoord;
	}
}

/** Collects all the triangle data for one vertex.
 */
class VertexData 
{
	public var triangles:Array<TriangleData> = new Array<TriangleData>();
	
	public function new()
	{
		
	}
}

/** Keeps track of tangent, binormal, and normal for one triangle.
 */
class TriangleData
{
	public var tangent:Vector3f;
	public var binormal:Vector3f;
	public var normal:Vector3f;        
	public var index:Vector<Int> = new Vector<Int>(3);
	public var triangleOffset:Int;
	
	public function new(tangent:Vector3f, binormal:Vector3f, normal:Vector3f) 
	{
		this.tangent = tangent;
		this.binormal = binormal;
		this.normal = normal;
	}
	
	public function setIndex(index:Vector<Int>):Void
	{
		for (i in 0...index.length)
		{
			this.index[i] = index[i];
		}
	}
}
