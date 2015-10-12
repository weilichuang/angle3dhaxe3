package org.angle3d.utils;
import flash.Vector;
import haxe.ds.IntMap;
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
import org.angle3d.utils.TangentBinormalGenerator.VertexData;

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
		setToleranceAngle(45);
	}
	
	public static function setToleranceAngle(angle:Float):Void
	{
        if (angle < 0 || angle > 179)
		{
            throw "The angle must be between 0 and 179 degrees.";
        }
        toleranceDot = Math.cos(angle * FastMath.DEGTORAD());
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
	
	public function generateSpatial(scene:Spatial, splitMirrored:Bool):Void
	{
		if (Std.is(scene, Node))
		{
			var node:Node = cast scene;
			for (child in node.children)
			{
				generateSpatial(scene,splitMirrored);
			}
		}
		else if(Std.is(scene,Geometry))
		{
			var geom:Geometry = cast scene;
			var mesh:Mesh = geom.getMesh();
			
			// Check to ensure mesh has texcoords and normals before generating
			if (mesh.getVertexBuffer(BufferType.TEXCOORD) != null && mesh.getVertexBuffer(BufferType.NORMAL) != null)
			{
				generateMesh(mesh, true, splitMirrored);
			}
		}
	}
	
	public function generateMesh(mesh:Mesh, approxTangents:Bool = true, splitMirrored:Bool = false):Void
	{
		if (mesh.getVertexBuffer(BufferType.NORMAL) == null)
			throw "The given mesh has no normal data!";
			
		var index:Vector<Int> = new Vector<Int>(3);
		var v:Vector<Vector3f> = new Vector<Vector3f>(3);
		var t:Vector<Vector2f> = new Vector<Vector2f>(3);
		for (i in 0...3)
		{
			v[i] = new Vector3f();
			t[i] = new Vector2f();
		}
		
		var vertices:Array<VertexData> = processTriangles(mesh, index, v, t, splitMirrored);
		if (splitMirrored)
		{
			splitVertices(mesh, vertices, splitMirrored);
		}
		
		processTriangleData(mesh, vertices, approxTangents, splitMirrored);

        //if the mesh has a bind pose, we need to generate the bind pose for the tangent buffer
        if (mesh.getVertexBuffer(BufferType.BIND_POSE_POSITION) != null)
		{
            var tangents:VertexBuffer = mesh.getVertexBuffer(BufferType.TANGENT);
            if (tangents != null) 
			{
                var bindTangents:VertexBuffer = new VertexBuffer(BufferType.BIND_POSE_TANGENT,4);
				bindTangents.setUsage(Usage.CPUONLY);
				bindTangents.updateData(tangents.getData().concat());
                
                if (mesh.getVertexBuffer(BufferType.BIND_POSE_TANGENT) != null) 
				{
                    mesh.clearBuffer(BufferType.BIND_POSE_TANGENT);
                }
                mesh.setVertexBufferDirect(bindTangents);
                tangents.setUsage(Usage.DYNAMIC);
            }
        }
	}
	
	private static function processTriangleData(mesh:Mesh, vertices:Array<VertexData>, approxTangent:Bool, splitMirrored:Bool):Void
	{
        //Array<VertexInfo> vertexMap = linkVertices(mesh,splitMirrored);
//
        //FloatBuffer tangents = BufferUtils.createFloatBuffer(vertices.size() * 4);
//
        //ColorRGBA[] cols = null;
        //if (debug) {
            //cols = new ColorRGBA[vertices.size()];
        //}
//
        //Vector3f tangent = new Vector3f();
        //Vector3f binormal = new Vector3f();
        ////Vector3f normal = new Vector3f();
        //Vector3f givenNormal = new Vector3f();
//
        //Vector3f tangentUnit = new Vector3f();
        //Vector3f binormalUnit = new Vector3f();
//
        //for (int k = 0; k < vertexMap.size(); k++) {
            //float wCoord = -1;
//
            //VertexInfo vertexInfo = vertexMap.get(k);
//
            //givenNormal.set(vertexInfo.normal);
            //givenNormal.normalizeLocal();
//
            //TriangleData firstTriangle = vertices.get(vertexInfo.indices.get(0)).triangles.get(0);
//
            //// check tangent and binormal consistency
            //tangent.set(firstTriangle.tangent);
            //tangent.normalizeLocal();
            //binormal.set(firstTriangle.binormal);
            //binormal.normalizeLocal();
//
            //for (int i : vertexInfo.indices) {
                //ArrayList<TriangleData> triangles = vertices.get(i).triangles;
//
                //for (int j = 0; j < triangles.size(); j++) {
                    //TriangleData triangleData = triangles.get(j);
//
                    //tangentUnit.set(triangleData.tangent);
                    //tangentUnit.normalizeLocal();
                    //if (tangent.dot(tangentUnit) < toleranceDot) {
                        //log.log(Level.WARNING,
                                //"Angle between tangents exceeds tolerance "
                                //+ "for vertex {0}.", i);
                        //break;
                    //}
//
                    //if (!approxTangent) {
                        //binormalUnit.set(triangleData.binormal);
                        //binormalUnit.normalizeLocal();
                        //if (binormal.dot(binormalUnit) < toleranceDot) {
                            //log.log(Level.WARNING,
                                    //"Angle between binormals exceeds tolerance "
                                    //+ "for vertex {0}.", i);
                            //break;
                        //}
                    //}
                //}
            //}
//
//
            //// find average tangent
            //tangent.set(0, 0, 0);
            //binormal.set(0, 0, 0);
//
            //int triangleCount = 0;
            //for (int i : vertexInfo.indices) {
                //ArrayList<TriangleData> triangles = vertices.get(i).triangles;
                //triangleCount += triangles.size();
                //if (debug) {
                    //cols[i] = ColorRGBA.White;
                //}
//
                //for (int j = 0; j < triangles.size(); j++) {
                    //TriangleData triangleData = triangles.get(j);
                    //tangent.addLocal(triangleData.tangent);
                    //binormal.addLocal(triangleData.binormal);
//
                //}
            //}
//
//
            //int blameVertex = vertexInfo.indices.get(0);
//
            //if (tangent.length() < ZERO_TOLERANCE) {
                //log.log(Level.WARNING,
                        //"Shared tangent is zero for vertex {0}.", blameVertex);
                //// attempt to fix from binormal
                //if (binormal.length() >= ZERO_TOLERANCE) {
                    //binormal.cross(givenNormal, tangent);
                    //tangent.normalizeLocal();
                //} // if all fails use the tangent from the first triangle
                //else {
                    //tangent.set(firstTriangle.tangent);
                //}
            //} else {
                //tangent.divideLocal(triangleCount);
            //}
//
            //tangentUnit.set(tangent);
            //tangentUnit.normalizeLocal();
            //if (Math.abs(Math.abs(tangentUnit.dot(givenNormal)) - 1)
                    //< ZERO_TOLERANCE) {
                //log.log(Level.WARNING,
                        //"Normal and tangent are parallel for vertex {0}.", blameVertex);
            //}
//
//
            //if (!approxTangent) {
                //if (binormal.length() < ZERO_TOLERANCE) {
                    //log.log(Level.WARNING,
                            //"Shared binormal is zero for vertex {0}.", blameVertex);
                    //// attempt to fix from tangent
                    //if (tangent.length() >= ZERO_TOLERANCE) {
                        //givenNormal.cross(tangent, binormal);
                        //binormal.normalizeLocal();
                    //} // if all fails use the binormal from the first triangle
                    //else {
                        //binormal.set(firstTriangle.binormal);
                    //}
                //} else {
                    //binormal.divideLocal(triangleCount);
                //}
//
                //binormalUnit.set(binormal);
                //binormalUnit.normalizeLocal();
                //if (Math.abs(Math.abs(binormalUnit.dot(givenNormal)) - 1)
                        //< ZERO_TOLERANCE) {
                    //log.log(Level.WARNING,
                            //"Normal and binormal are parallel for vertex {0}.", blameVertex);
                //}
//
                //if (Math.abs(Math.abs(binormalUnit.dot(tangentUnit)) - 1)
                        //< ZERO_TOLERANCE) {
                    //log.log(Level.WARNING,
                            //"Tangent and binormal are parallel for vertex {0}.", blameVertex);
                //}
            //}
//
            //Vector3f finalTangent = new Vector3f();
            //Vector3f tmp = new Vector3f();
            //for (int i : vertexInfo.indices) {
                //if (approxTangent) {
                    //// Gram-Schmidt orthogonalize
                    //finalTangent.set(tangent).subtractLocal(tmp.set(givenNormal).multLocal(givenNormal.dot(tangent)));
                    //finalTangent.normalizeLocal();
//
                    //wCoord = tmp.set(givenNormal).crossLocal(tangent).dot(binormal) < 0f ? -1f : 1f;
//
                    //tangents.put((i * 4), finalTangent.x);
                    //tangents.put((i * 4) + 1, finalTangent.y);
                    //tangents.put((i * 4) + 2, finalTangent.z);
                    //tangents.put((i * 4) + 3, wCoord);
                //} else {
                    //tangents.put((i * 4), tangent.x);
                    //tangents.put((i * 4) + 1, tangent.y);
                    //tangents.put((i * 4) + 2, tangent.z);
                    //tangents.put((i * 4) + 3, wCoord);
//
                    ////setInBuffer(binormal, binormals, i);
                //}
            //}
        //}
        //tangents.limit(tangents.capacity());
        //// If the model already had a tangent buffer, replace it with the regenerated one
        //mesh.clearBuffer(Type.Tangent);
        //mesh.setBuffer(Type.Tangent, 4, tangents);
        //
        //
        //
        //if(mesh.isAnimated()){
            //mesh.clearBuffer(Type.BindPoseNormal);
            //mesh.clearBuffer(Type.BindPosePosition);
            //mesh.clearBuffer(Type.BindPoseTangent);
            //mesh.generateBindPose(true);
        //}
//
        //if (debug) {
            //writeColorBuffer( vertices, cols, mesh);
        //}
        //mesh.updateBound();
        //mesh.updateCounts();
    }   
	
	private static function approxEqualVec3(u:Vector3f,v:Vector3f):Bool
	{
        var tolerance:Float = 1E-4;
        return (FastMath.abs(u.x - v.x) < tolerance) &&
               (FastMath.abs(u.y - v.y) < tolerance) &&
               (FastMath.abs(u.z - v.z) < tolerance);
    }
    
    private static function approxEqualVec2(u:Vector2f, v:Vector2f):Bool
	{
        var tolerance:Float = 1E-4;
        return (FastMath.abs(u.x - v.x) < tolerance) &&
               (FastMath.abs(u.y - v.y) < tolerance);
    }
    
    private static function linkVertices(mesh:Mesh, splitMirrored:Bool):Array<VertexInfo>
	{
		return null;
        //ArrayList<VertexInfo> vertexMap = new ArrayList<VertexInfo>();
        //
        //FloatBuffer vertexBuffer = mesh.getFloatBuffer(Type.Position);
        //FloatBuffer normalBuffer = mesh.getFloatBuffer(Type.Normal);
        //FloatBuffer texcoordBuffer = mesh.getFloatBuffer(Type.TexCoord);
        //
        //var position:Vector3f = new Vector3f();
        //var normal:Vector3f = new Vector3f();
        //var texCoord:Vector2f = new Vector2f();
        //
        //var size:Int = vertexBuffer.limit() / 3;
        //for (i in 0...size) 
		//{
            //
            //populateFromBuffer(position, vertexBuffer, i);
            //populateFromBuffer(normal, normalBuffer, i);
            //populateFromBuffer(texCoord, texcoordBuffer, i);
            //
            //boolean found = false;
            ////Nehon 07/07/2013
            ////Removed this part, joining splitted vertice to compute tangent space makes no sense to me
            ////separate vertice should have separate tangent space   
            //if(!splitMirrored){
                //for (int j = 0; j < vertexMap.size(); j++) {
                    //VertexInfo vertexInfo = vertexMap.get(j);
                    //if (approxEqualVec3(vertexInfo.position, position) &&
                        //approxEqualVec3(vertexInfo.normal, normal) &&
                        //approxEqualVec2(vertexInfo.texCoord, texCoord))
                    //{
                        //vertexInfo.indices.add(i);
                        //found = true;
                        //break;  
                    //}
                //}
            //}
            //if (!found) {
                //VertexInfo vertexInfo = new VertexInfo(position.clone(), normal.clone(), texCoord.clone());
                //vertexInfo.indices.add(i);
                //vertexMap.add(vertexInfo);
            //}
        //}
        //
        //return vertexMap;
    }
	
	private function splitVertices(mesh:Mesh, vertexData:Array<VertexData>, splitMirorred:Bool):Array<VertexData>
	{
		var nbVertices:Int = mesh.getVertexBuffer(BufferType.POSITION).getNumElements();
		var newVertices:Array<VertexData> = [];
		var indiceMap:IntMap<Int> = new IntMap<Int>();
		var normalBuffer:VertexBuffer = mesh.getVertexBuffer(BufferType.NORMAL);
		
		for (i in 0...vertexData.length)
		{
			var triangles:Vector<TriangleData> = vertexData[i].triangles;
			var givenNormal:Vector3f = new Vector3f();
			BufferUtils.populateFromBuffer(givenNormal, normalBuffer.getData(), i);
			
			var trianglesUp:Array<TriangleData> = [];
			var trianglesDown:Array<TriangleData> = [];
			for (j in 0...triangles.length)
			{
				var triangleData:TriangleData = triangles[j];
				if (parity(givenNormal, triangleData.normal) > 0)
				{
					trianglesUp.push(triangleData);
				}
				else
				{
					trianglesDown.push(triangleData);
				}
			}
			
			//if the vertex has triangles with opposite parity it has to be split
			if (trianglesUp.length != 0 && trianglesDown.length != 0)
			{
				Logger.log('Splitting vertex ${i}');
				
				//assigning triangle with the same parity to the original vertex
				vertexData[i].triangles.length = 0;
				
				for (t in 0...trianglesUp.length)
				{
					vertexData[i].triangles[t] = trianglesUp[t];
				}
				
				//creating a new vertex
				var newVert:VertexData = new VertexData();
				//assigning triangles with opposite parity to it
				for (t in 0...trianglesDown.length)
				{
					newVert.triangles[t] = trianglesDown[t];
				}
				
				newVertices.push(newVert);
				//keep vertex index to fix the index buffers later
				indiceMap.set(nbVertices, i);
				for (tri in newVert.triangles)
				{
					for (j in 0...tri.index.length)
					{
						if (tri.index[j] == i)
						{
							tri.index[j] = nbVertices;
						}
					}
				}
				nbVertices++;
			}
		}
		
		if (newVertices.length != 0)
		{
			//we have new vertices, we need to update the mesh's buffers.
			var types:Array<String> = BufferType.VERTEX_TYPES;
			for (type in types)
			{
				//skip tangent buffer as we're gonna overwrite it later
				if (type == BufferType.TANGENT || type == BufferType.BIND_POSE_TANGENT)
					continue;
				
				var vb:VertexBuffer = mesh.getVertexBuffer(type);
				//Some buffer (hardware skinning ones) can be there but not 
                //initialized, they must be skipped. 
                //They'll be initialized when Hardware Skinning is engaged
				if (vb == null || vb.components == 0)
					continue;
					
				var bufferData:Vector<Float> = vb.getData();
				var index:Int = vertexData.length;
				for (j in 0...newVertices.length)
				{
					var oldInd:Int = indiceMap.get(index);
					for (i in 0...vb.components)
					{
						bufferData.push(bufferData[oldInd * vb.components + i]);
					}
					index++;
				}
				vb.updateData(bufferData);
			}
			
			var indices:Vector<UInt> = mesh.getIndices();
			for (vertex in newVertices)
			{
				for (tri in vertex.triangles)
				{
					for (t in 0...tri.index.length)
					{
						indices[tri.triangleOffset + t] = tri.index[t];
					}
				}
			}
			mesh.setIndices(indices);
			
			
			for (n in 0...newVertices.length)
			{
				vertexData.push(newVertices[n]);
			}
			
			mesh.updateCounts();
		}
		
		return vertexData;
	}
	
	private function processTriangles(mesh:Mesh, index:Vector<Int>, v:Vector<Vector3f>, t:Vector<Vector2f>, splitMirrored:Bool):Array<VertexData>
	{
		if (mesh.getVertexBuffer(BufferType.TEXCOORD) == null)
			throw "Can only generate tangents for "
                    + "meshes with texture coordinates";
			
		var indices:Vector<UInt> = mesh.getIndices();
		var vertexList:Vector<Float> = mesh.getVertexBuffer(BufferType.POSITION).getData();
		var texCoords:Vector<Float> = mesh.getVertexBuffer(BufferType.TEXCOORD).getData();
		
		var vertices:Array<VertexData> = initVertexData(Std.int(vertexList.length / 3));
		
		var count:Int = Std.int(indices.length / 3);
		for (i in 0...count)
		{
			for (j in 0...3)
			{
				index[j] = indices[i * 3 + j];
				BufferUtils.populateFromBuffer(v[j], vertexList, index[j]);
				BufferUtils.populateFromVector2f(t[j], texCoords, index[j]);
			}
			
			var triData:TriangleData = processTriangle(index, v, t);
			if (splitMirrored)
			{
				triData.setIndex(index);
				triData.triangleOffset = i * 3;
			}
			
			vertices[index[0]].triangles.push(triData);
			vertices[index[1]].triangles.push(triData);
			vertices[index[2]].triangles.push(triData);
		}
		
		return vertices;
	}
	
	public function processTriangle(index:Vector<Int>, v:Vector<Vector3f>, t:Vector<Vector2f>):TriangleData
	{
		var tmp:TempVars = TempVars.get();
		
		var edge1:Vector3f = tmp.vect1;
		var edge2:Vector3f = tmp.vect2;
		var edge1uv:Vector2f = tmp.vect2d;
		var edge2uv:Vector2f = tmp.vect2d2;
		
		var tangent:Vector3f = new Vector3f();
		var binormal:Vector3f = new Vector3f();
		var normal:Vector3f = new Vector3f();
		
		t[1].subtract(t[0], edge1uv);
		t[2].subtract(t[0], edge2uv);
		var det:Float = edge1uv.x * edge2uv.y - edge1uv.y * edge2uv.x;
		
		var normalize:Bool = false;
		if (Math.abs(det) < ZERO_TOLERANCE)
		{
			Logger.warn('Colinear uv coordinates for triangle [${index[0]}, ${index[1]}, ${index[2]}]; tex0 = [${t[0].x}, ${t[0].y}], tex1 = [${t[1].x}, ${t[1].y}], tex2 = [${t[2].x}, ${t[2].y}]');
			det = 1;
			normalize = true;
		}
		
		v[1].subtract(v[0], edge1);
		v[2].subtract(v[0], edge2);
		
		tangent.copyFrom(edge1);
		tangent.normalizeLocal();
		binormal.copyFrom(edge2);
		binormal.normalizeLocal();
		
		if (Math.abs(Math.abs(tangent.dot(binormal)) - 1) < ZERO_TOLERANCE) 
		{
			Logger.warn('Vertices are on the same line for triangle [${index[0]}, ${index[1]}, ${index[2]}].');
		}
		
		var factor:Float = 1 / det;
		tangent.x = (edge2uv.y * edge1.x - edge1uv.y * edge2.x) * factor;
		tangent.y = (edge2uv.y * edge1.y - edge1uv.y * edge2.y) * factor;
		tangent.z = (edge2uv.y * edge1.z - edge1uv.y * edge2.z) * factor;
		if (normalize)
		{
			tangent.normalizeLocal();
		}
		
		binormal.x = (edge1uv.x * edge2.x - edge2uv.x * edge1.x) * factor;
		binormal.y = (edge1uv.x * edge2.y - edge2uv.x * edge1.y) * factor;
		binormal.z = (edge1uv.x * edge2.z - edge2uv.x * edge1.z) * factor;
		if (normalize)
		{
			binormal.normalizeLocal();
		}
		
		tangent.cross(binormal, normal);
		normal.normalizeLocal();
		
		tmp.release();
		
		return new TriangleData(tangent, binormal, normal);
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
	
	private static function parity(n1:Vector3f, n:Vector3f):Int
	{
        if (n1.dot(n) < 0)
		{
            return -1;
        }
		else
		{
            return 1;
        }
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
	public var triangles:Vector<TriangleData> = new Vector<TriangleData>();
	
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
