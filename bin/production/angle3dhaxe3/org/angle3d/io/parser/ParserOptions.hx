package org.angle3d.io.parser;

/**
 * ParserOptions objects provide properties and function references
 * to customize how a LoaderGroup object will load and interpret
 * content.
 *
 * @author Jean-Marc Le Roux
 *
 */
class ParserOptions
{
	//private var _loadTextures:Bool = false;
//
	//private var _loadMeshes:Bool = true;
	//private var _loadSkins:Bool = true;
	//private var _mergeMeshes:Bool = false;
//
	//private var _keepStreamsDynamic:Bool = true;
//
	//private var _loadFunction:Function; //= load;
	//private var _rewritePathFunction:Function = rewritePath;
//
	//private var _replaceNodeFunction:Function; //= replaceNode;
	
	public function new()
	{
		
	}
//
	///**
	 //* If set to true, the LoaderGroup will load embed and/or external textures.
	 //* @return
	 //*
	 //*/
	//private function get_loadTextures():Bool
	//{
		//return _loadTextures;
	//}
//
	///**
	 //* If set to true, the LoaderGroup will load meshes.
	 //* @return
	 //*
	 //*/
	//private function get loadMeshes():Bool
	//{
		//return _loadMeshes;
	//}
//
	///**
	 //* If set to true, the LoaderGroup will load skins and animations.
	 //* @return
	 //*
	 //*/
	//private function get loadSkins():Bool
	//{
		//return _loadSkins;
	//}
//
	///**
	 //* If set to true, meshes will be merged whenever possible.
	 //* @return
	 //*
	 //*/
	//private function get mergeMeshes():Bool
	//{
		//return _mergeMeshes;
	//}
//
	//private function get keepStreamsDynamic():Bool
	//{
		//return _keepStreamsDynamic;
	//}
//
	///**
	 //* The function to call when external items such as textures must be loaded.
	 //* This function should have the following prototype:
	 //*
	 //* <pre>
	 //* function(request : URLRequest, options : ParserOptions = null) : IScene
	 //* </pre>
	 //*
	 //* The default value is the LoaderGroup.load method.
	 //*
	 //* @return
	 //*
	 //*/
	//private function get loadFunction():Function
	//{
		//return _loadFunction;
	//}
//
	///**
	 //* A function to call on every loaded node in order to replace it before inserting it
	 //* in the loaded scene graph. This function should have the following prototype:
	 //*
	 //* <pre>
	 //* function(node : IScene) : IScene
	 //* </pre>
	 //*
	 //* The default value is the idendity function: it will return the node unchanged.
	 //*
	 //* @return
	 //*
	 //*/
	//private function get replaceNodeFunction():Function
	//{
		//return _replaceNodeFunction;
	//}
//
	///**
	 //* A function that will rewrite the path of the external loaded items such as textures.
	 //* This function should have the following prototype:
	 //*
	 //* <pre>
	 //* function(path : String) : String
	 //* </pre>
	 //*
	 //* The default value is the idendity function: it will return the path unchanged.
	 //*
	 //* @return
	 //*
	 //*/
	//private function get rewritePathFunction():Function
	//{
		//return _rewritePathFunction;
	//}
//
	//private function set loadTextures(value:Bool):Void
	//{
		//_loadTextures = value;
	//}
//
	//private function set loadMeshes(value:Bool):Void
	//{
		//_loadMeshes = value;
	//}
//
	//private function set mergeMeshes(value:Bool):Void
	//{
		//_mergeMeshes = value;
	//}
//
	//private function set loadSkins(value:Bool):Void
	//{
		//_loadSkins = value;
	//}
//
	//private function set keepStreamsDynamic(value:Bool):Void
	//{
		//_keepStreamsDynamic = value;
	//}
//
	///**
	 //* @param value The prototype of this function must be function(path : String) : IScene
	 //*/
	//public function set loadFunction(value:Function):Void
	//{
		//_loadFunction = value;
	//}
//
	///**
	 //* @param value The prototype of this function must be function(path : String) : String
	 //*/
	//public function set rewritePathFunction(value:Function):Void
	//{
		//_rewritePathFunction = value;
	//}
//
	///**
	 //* @param value The prototype of this function must be function(node : IScene) : IScene
	 //*/
	//public function set replaceNodeFunction(value:Function):Void
	//{
		//_replaceNodeFunction = value;
	//}
//
//		private function load(request : URLRequest, options : ParserOptions = null) : LoaderGroup
//		{
//			return LoaderGroup.load(request, options);
//		}
//
	//private function rewritePath(path:String):String
	//{
		//return path;
	//}

//		private function replaceNode(node : IScene) : IScene
//		{
//			return node;
//		}
}
