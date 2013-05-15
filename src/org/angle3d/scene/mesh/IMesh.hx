package org.angle3d.scene.mesh;
import flash.Vector;
interface IMesh
{
	var subMeshList(get,set):Vector<SubMesh>;
	var type(get,null):MeshType;
}

