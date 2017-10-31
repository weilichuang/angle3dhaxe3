package org.angle3d.io.parser.dae;

import flash.utils.ByteArray;
import haxe.ds.StringMap;
import haxe.xml.Fast;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.utils.Logger;

class DaeParser
{

	public function new() 
	{
		
	}
	
	public function parseStaticMesh(data:ByteArray):Mesh
	{
		var text:String = data.readUTFBytes(data.length);
		
		var xml:Xml = Xml.parse(text);

		var fastXml:Fast = new Fast(xml.firstElement());

		readGeometries(fastXml.node.resolve(":library_geometries").nodes.resolve(":geometry"));
		
		readScenes(fastXml.node.resolve(":library_visual_scenes").nodes.resolve(":visual_scene"));
		
		return null;
	}
	
	public function parseSkinnedMesh(data:ByteArray):Mesh
	{
		var text:String = data.readUTF();
		
		var xml:Xml = Xml.parse(text);
		
		return null;
	}
	
	private function readGeometries(list:List<Fast>):Void
	{
		Logger.log("readGeometries:\n");
		
		var fastXml:Fast;
		for (fastXml in list)
		{
			var id:String = fastXml.att.id;
			var name:String = fastXml.att.name;
			
			var meshList:List<Fast> = fastXml.nodes.resolve(":mesh");
			var meshFast:Fast;
			//每个Mesh XML生成一个SubMesh
			for (meshFast in meshList)
			{
				var sourceMap:FastStringMap<DaeSource> = new FastStringMap<DaeSource>();
				for (itemXml in meshFast.x.elements())
				{
					var itemFast:Fast = new Fast(itemXml);
					
					switch(itemFast.name)
					{
						case "source":
							var source:DaeSource = new DaeSource();
							source.parse(itemFast);
							sourceMap.set(itemFast.att.id, source);
						case "vertices":
							var inputList:List<Fast> = itemFast.nodes.resolve(":input");
							for (inputFast in inputList)
							{
								trace(inputFast.att.semantic);
								switch(inputFast.att.semantic)
								{
									case "POSITION":
										var inputSource:String = inputFast.att.source;
										trace(inputSource);
								}
							}
						case "triangles":
							var materialId:String = itemFast.att.material;
							var count:Int = Std.parseInt(itemFast.att.count);
							var inputList:List<Fast> = itemFast.nodes.resolve(":input");
							for (inputFast in inputList)
							{
								switch(inputFast.att.semantic)
								{
									case "VERTEX":
										var inputSource:String = inputFast.att.source;
										var offset:Int = Std.parseInt(inputFast.att.offset);
										trace(inputSource);
									case "NORMAL":
										var inputSource:String = inputFast.att.source;
										var offset:Int = Std.parseInt(inputFast.att.offset);
									case "TEXCOORD":
										var inputSource:String = inputFast.att.source;
										var offset:Int = Std.parseInt(inputFast.att.offset);
								}
							}
							
							var pFast:Fast = itemFast.node.resolve(":p");
							var arr:Array<String> = ~/\s+/g.split(pFast.innerData);
							//trace(arr);
					}
				}
			}
		}
	}
	
	private function readScenes(list:List<Fast>):Void
	{
		Logger.log("readScenes:\n");

		for (fastXml in list)
		{
			
		}
	}
	
}

class DaeSource
{
	public function new()
	{
		
	}
	
	public function parse(xml:Fast):Void
	{
		
	}
}