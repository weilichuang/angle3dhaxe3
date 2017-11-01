package org.angle3d.asset;

import org.angle3d.signal.Signal.Signal1;
import haxe.ds.StringMap;

class FilesLoader
{
	/** Dispatched when files are loaded and there are no more files to load. */
	public var onFilesLoaded:Signal1<FilesLoader>;
	
	/** Dispatched every time a file is loaded. */
	public var onFileLoaded:Signal1<FileInfo>;
	
	private var _urls:Array<String> = [];
	private var _types:Array<String> = [];
	private var _fileInfos:Array<FileInfo> = [];
	private var _fileMap:StringMap<FileInfo>;

	public function new() 
	{
		onFileLoaded = new Signal1<FileInfo>();
		onFilesLoaded = new Signal1<FilesLoader>();
		_fileInfos = [];
		_fileMap = new StringMap<FileInfo>();
	}

	public function queueFile(url : String, assetType : String = "binary") : Void
	{
		var index:Int = _urls.indexOf(url);
		if (index != -1)
			return;
			
		_urls.push(url);
		_types.push(assetType);
	}
	
	public function queueText(url:String):Void
	{
		queueFile(url, LoaderType.TEXT);
	}
	
	public function queueBinary(url:String):Void
	{
		queueFile(url, LoaderType.BINARY);
	}
	
	public function queueImage(url:String):Void
	{
		queueFile(url, LoaderType.IMAGE);
	}
	
	public function getFileCount():Int
	{
		return _urls.length;
	}

	public function getAssetByUrl( url : String ) : FileInfo 
	{
		return _fileMap.get(url);
	}

	public function getAssetByType( type : String ) : FileInfo
	{
		for ( i in 0..._fileInfos.length) 
		{
			var fileInfo:FileInfo = _fileInfos[i];
			if (fileInfo.error)
				continue;
				
			if (fileInfo.info.type == type ) 
			{
				return _fileInfos[ i ];
			}
		}
		return null;
	}

	public function getAssets() : Array<FileInfo>
	{
		return _fileInfos;
	}

	public function loadQueuedFiles() : Void 
	{
		if ( _urls != null )
		{
			for ( i in 0..._urls.length)
			{
				AssetManager.loadAsset( this, _types[ i ], _urls[ i ], _loadedHandler, _loadedErrorHandler );
			}
		}
	}

	private function _loadedHandler( info : AssetInfo ) : Void 
	{
		var fileInfo:FileInfo = new FileInfo();
		fileInfo.url = info.url;
		fileInfo.info = info;
		fileInfo.error = false;
		
		addFileInfo(fileInfo);
	}

	private function _loadedErrorHandler( url:String ) : Void
	{
		var fileInfo:FileInfo = new FileInfo();
		fileInfo.url = url;
		fileInfo.info = null;
		fileInfo.error = true;
		
		addFileInfo(fileInfo);
	}
	
	private function addFileInfo(info:FileInfo):Void
	{
		_fileInfos.push( info );
		_fileMap.set(info.url, info);
		
		onFileLoaded.dispatch(info);
		
		if ( _fileInfos.length == _urls.length )
		{
			onFilesLoaded.dispatch(this);
		}
	}

	public function dispose() : Void
	{
		for ( i in 0..._urls.length)
		{
			AssetManager.unloadAsset( this, _types[ i ], _urls[ i ], _loadedHandler );
		}
		_urls = null;
		_types = null;
		_fileInfos = null;
		_fileMap = null;
		
		onFileLoaded.removeAll();
		onFilesLoaded.removeAll();
	}
}
