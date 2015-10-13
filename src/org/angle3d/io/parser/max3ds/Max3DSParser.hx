package org.angle3d.io.parser.max3ds;

import flash.Lib;
import flash.utils.ByteArray;
import flash.utils.Endian;
import flash.Vector;
import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.scene.mesh.MeshHelper;
import org.angle3d.utils.FastStringMap;
import org.angle3d.utils.Logger;


class Max3DSParser extends AbstractMax3DSParser
{
	private var _materials:FastStringMap<Dynamic>;
	private var _meshes:Array<Mesh>;

	public function new()
	{
		super();
	}

	public var meshes(get, null):Array<Mesh>;
	private function get_meshes():Array<Mesh>
	{
		return _meshes;
	}

	override private function initialize():Void
	{
		super.initialize();

		parseFunctions[Max3DSChunk.PRIMARY] = parsePrimary;
		parseFunctions[Max3DSChunk.SCENE] = enterChunk;
		parseFunctions[Max3DSChunk.MATERIAL] = parseMaterial;
		parseFunctions[Max3DSChunk.OBJECT] = parseObject;
	}

	public function parse(data:ByteArray):Array<Mesh>
	{
		data.endian = Endian.LITTLE_ENDIAN;
		data.position = 0;

		if (data.readUnsignedShort() != Max3DSChunk.PRIMARY)
			return null;

		_materials = new FastStringMap<Dynamic>();

		_meshes = [];

		data.position = 0;
		parseChunk(new Max3DSChunk(data));

		return _meshes;
	}

	private function parsePrimary(chunk:Max3DSChunk):Void
	{
		// throw an error if the first chunk is not a primary chunk
	/*if (chunk.identifier != Max3DSChunk.PRIMARY)
		throw new Error("Wrong file format!");*/
	}

	private function parseObject(chunk:Max3DSChunk):Void
	{
		var name:String = chunk.readString();
		
		Logger.log("object name:" + name);

		chunk = new Max3DSChunk(chunk.data);

		if (chunk.identifier == Max3DSChunk.MESH)
		{
			var parser:Max3DSMeshParser = new Max3DSMeshParser(chunk, name);

			var objectMaterials:FastStringMap<Dynamic> = parser.materials;
			var keys = objectMaterials.keys();
			for (materialName in keys)
			{
				var mesh:Mesh = new Mesh();

				mesh.setVertexBuffer(BufferType.POSITION, 3, parser.vertices);
				mesh.setVertexBuffer(BufferType.TEXCOORD, 2, parser.uvData);
				
				var indices:Vector<UInt> = objectMaterials.get(materialName);
				
				var normals:Vector<Float> = MeshHelper.buildVertexNormals(indices, parser.vertices);
				mesh.setVertexBuffer(BufferType.NORMAL, 3, normals);
				
				mesh.setIndices(indices);
				mesh.validate();
				
				_meshes.push(mesh);

//				var group : IGroup = getMaterialGroup(materialName);
//
//				if (!group)
//				{
//					throw new Error("Unable to find material named '"
//						+ materialName + "'.");
//				}
//
//				var textureFilename : String = _materials[materialName].textureFilename;
//				var vstream : VertexStream = VertexStream.fromPositionsAndUVs(parser.vertices, parser.uvData, _options.keepStreamsDynamic);
//				var scene : IScene = new Max3DSMesh(new VertexStreamList(vstream),
//					new IndexStream(objectMaterials[materialName], 0, _options.keepStreamsDynamic),
//					name,
//					materialName,
//					textureFilename);
//
//				scene = _options.replaceNodeFunction(scene);
//				group.addChild(scene);
			}
		}
		else
		{
			chunk.skip();
		}
	}

//		private function getMaterialGroup(materialName : String) : Group
//		{
//			for (var i : int = 0; i < _data.length && _data[i].name != materialName; ++i)
//				continue;
//
//			return i < _data.length ? Group(_data[i]) : null;
//		}

	private function parseMaterial(chunk:Max3DSChunk):Void
	{

		var material:Max3DSMaterialParser = new Max3DSMaterialParser(chunk);
		#if debug
		Lib.trace("material:" + material.name);
		Lib.trace("material.textureFilename:" + material.textureFilename);
		#end

		if (!_materials.exists(material.name))
			_materials.set(material.name, material);

		//var loadTextures:Bool = _options != null ? _options.loadTextures : false;
//		var group : Group = getMaterialGroup(material.name);
//		var texture : IScene = null;
//
//		if (!group)
//		{
//			if (loadTextures)
//			{
//				var textureFilename : String = material.textureFilename;
//
//				if (textureFilename != null)
//					textureFilename = _options.rewritePathFunction(textureFilename);
//
//				if (textureFilename)
//				{
//					texture = _options.loadFunction(new URLRequest(textureFilename), _options);
//
//					texture.name = material.name;
//					if (texture is LoaderGroup)
//					{
//						var loader : LoaderGroup = texture as LoaderGroup;
//
//						if (!_markedLoader[loader] && loader.numLoadedItems != loader.numTotalItems)
//						{
//							_markedLoader[loader] = true;
//							loader.addEventListener(Event.COMPLETE, textureCompleteHandler);
//							++_total;
//						}
//					}
//				}
//			}
//
//			group = _options.replaceNodeFunction(new StyleGroup());
//			if (texture)
//				group.addChild(texture);
//
//			group.name = material.name;
//			_data.push(group);
//
//			_materials[material.name] = material;
//		}
	}

	override private function finalize():Void
	{
//		if (_options && _options.mergeMeshes)
//		{
//			var numMaterials : int = _data.length;
//			var meshes : Vector<IMesh> = new Vector<IMesh>();
//
//			for (var i : int = 0; i < numMaterials; ++i)
//			{
//				var materialGroup : Group = _data[i] as Group;
//				var texture : IScene = materialGroup.getChildAt(0);
//
//				meshes.length = 0;
//
//				for each (var child : IScene in materialGroup)
//					if (child is IMesh)
//						meshes.push(child as IMesh);
//
//				materialGroup.removeAllChildren();
//				if (texture && !(texture is IMesh))
//					materialGroup.addChild(texture);
//				if (meshes.length)
//				{
//					var mergedMesh : IMesh = Mesh.merge(meshes);
//
//					mergedMesh = _options.replaceNodeFunction(mergedMesh);
//					materialGroup.addChild(mergedMesh);
//				}
//			}
//		}
	}
}
