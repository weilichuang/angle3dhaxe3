package angle3d.asset;

import haxe.Timer;
import haxe.ds.StringMap;
import angle3d.math.FastMath;
import angle3d.asset.caches.BaseCache;
import angle3d.asset.parsers.BaseParser;

/**
 * 资源管理
 */
class AssetManager {
	public static var maxTimeoutCount; //最大超时次数
	private static var Max_Time : Int;

	public static var fastMaxLoadNum : Int;
	public static var defaultMaxLoadNum : Int;
	public static var maxLoadNum : Int; //同时加载个数
	public static var isTrace : Bool;
	public static var isThrowError : Bool;
	public static var defaultDelayTime : Int;
	public static var delayTime : Int;
	private static var _startNextTime : Int;

	private static var _cacheMap : StringMap<BaseCache>;
	private static var _loaderMap : StringMap<StreamLoader>;
	private static var _waitList : WaitList;
	private static var _isStop : Bool = false; //是否停止
	private static var _parserMap : StringMap<Dynamic>;

	private static var _parsingMap : StringMap<BaseParser>;

	private static var _waitArray : Array<WaitInfo>;

	static function __init__():Void {
		maxTimeoutCount = 3; //最大超时次数
		Max_Time = 20 * 1000;

		fastMaxLoadNum = 5;
		defaultMaxLoadNum = 2;
		maxLoadNum = 2; //同时加载个数
		isTrace = false;
		isThrowError = false;
		defaultDelayTime = 15;
		delayTime  = defaultDelayTime;
		_startNextTime  = 0;

		_waitArray = [];

		_cacheMap = new StringMap<BaseCache>();
		_loaderMap = new StringMap<StreamLoader>();
		_waitList = new WaitList();
		_isStop = false;
		_parsingMap = new StringMap<BaseParser>();
		_parserMap = new FastHashMap<Dynamic>();
	}

	public function new() {

	}

	//--------------------------------------------------------------
	//
	//--------------------------------------------------------------

	public static function addParser( type : String, parser : Dynamic ) : Void {
		_parserMap.set( type, parser );
	}

	public static function removeParser( type : String ) : Void {
		_parserMap.remove( type );
	}

	public static function addCache( type : String, cache : BaseCache ) : Void {
		_cacheMap.set( type, cache );
	}

	public static function removeCache( type : String ) : Void {
		_cacheMap.remove( type );
	}

	public static function getCache( type : String ) : BaseCache {
		return _cacheMap.get( type );
	}

	public static function clearCache( type : String ) : Void {
		var cache : BaseCache = getCache( type );
		cache.clear();
	}

	public static function clearAllCache() : Void {
		var keys = _cacheMap.keys();
		for ( i in 0...keys.length ) {
			var c : BaseCache = _cacheMap.get(keys[i]);
			c.clear();
		}
	}

	//--------------------------------------------------------------
	//
	//--------------------------------------------------------------

	public static function setCacheMaximum( type : String, value : Int ) : Void {
		var cache : BaseCache = _cacheMap.get( type );
		if ( cache != null ) {
			cache.maximum = value;
		}
	}

	private static inline function doTrace( funcName : String, text : String ) : Void {
		#if debug
		if ( isTrace ) {
			trace( funcName+":" + text );
		}
		#end
	}

	/**
	 获取资源，获取swf等资源时若想多次获取同一个对象，可以将isCache设为false。
	 @param ref  如果该资源需要引用计数，这个就传入该资源的引用归属
	 @param type  资源类型
	 @param url  资源位置
	 @param complete  资源获取成功的回调
	 @param error  资源获取失败的回调
	 @param open  资源开始加载的回调
	 @param progress  资源加载过程的回调
	 @param data  回调函数的参数
	 @param priority  资源加载的优先级
	 @param isCache  是否需要缓存 默认是true
	 **/
	public static function loadAsset(ref : Dynamic, type : String, url : String,
									 complete : Dynamic, error : Dynamic = null,
									 open : Dynamic = null, progress : Dynamic = null,
									 data : Dynamic = null, priority : Int = -1,
									 isCache : Bool = true) : Void {
		if (priority < 0)
			priority = Priority.STANDARD;

		if ( url == null || url == "" ) {
			return;
		}

		if ( url.indexOf( "null" ) != -1 ) {
			throwError( "url cant contain null text!" );
		}

		var info : AssetInfo = getFromCache( type, url );
		if ( info != null ) {
			if ( ref != null ) {
				info.addOwner( ref ); //引用计数
			}
			CallBackUtil.callBack( complete, info, data );
			return;
		}

		var isHasUrl : Bool = false;
		var waitInfo : WaitInfo = _waitList.getWaitInfo( url, type );
		if ( waitInfo == null ) {
			waitInfo = new WaitInfo();
			waitInfo.type = type;
			waitInfo.url = url;
			waitInfo.priority = priority;
			_waitList.addInfo(waitInfo);

			doTrace( "AssetManager loadAsset", url );
		} else
		{
			isHasUrl = true;
			waitInfo.priority = FastMath.minInt( waitInfo.priority, priority );
		}
		waitInfo.isCache = isCache;

		if (waitInfo.itemMap.exists(complete))
			return;

		if ( isCache && ref == null ) {
			var baseCache : BaseCache = _cacheMap.get( type );
			if ( baseCache.useRefCount ) {
				throwError( "type: " + type + ",需要使用引用计数" );
			}
		}

		var itemInfo : LoadingItemInfo = new LoadingItemInfo();
		itemInfo.completeHandler = complete;
		itemInfo.errorHandler = error;
		itemInfo.openHandler = open;
		itemInfo.progressHandler = progress;
		itemInfo.data = data;
		itemInfo.ref = ref;
		waitInfo.itemMap.set( complete, itemInfo );

		_waitList.sortPriority();
		//加载
		if ( isHasUrl == false ) {
			nextAsset();
		}
	}

	public static function unloadAsset( ref : Dynamic, type : String, url : String, complete : Dynamic ) : Void {
		freeAsset( ref, type, url );
		cancel( type, url, complete );
	}

	public static function freeAsset( ref : Dynamic, type : String, url : String ) : Void {
		var assetInfo : AssetInfo;
		var cache : BaseCache;
		cache = _cacheMap.get( type );
		assetInfo = cache.getAssetInfo( url );
		if ( assetInfo != null ) {
			assetInfo.removeOwner( ref );
		}
	}

	/**
	 * 直接从缓存中获取资源
	 * @param type
	 * @param url
	 * @return
	 *
	 */
	public static function getFromCache( type : String, url : String ) : AssetInfo {
		var cache : BaseCache = _cacheMap.get( type );
		if ( cache != null  ) {
			return cache.getAssetInfo( url );
		}
		return null;
	}

	/**
	 * 当前缓存中是否有资源
	 * @param type
	 * @param url
	 * @return 是否有此资源
	 *
	 */
	public static function hasAsset( type : String, url : String ) : Bool {
		var cache : BaseCache = _cacheMap.get( type );
		if ( cache != null ) {
			return cache.getAssetInfo( url ) != null;
		}
		return false;
	}

	/**
	 * 停止加载
	 *
	 */
	public static function pause() : Void {
		_isStop = true;
		closeAll();
	}

	/**
	 * 开启加载
	 *
	 */
	public static function resume() : Void {
		if ( _isStop ) {
			_isStop = false;
			nextAsset();
		}
	}

	/**
	 * 移除缓存依赖
	 * @param type
	 * @param url
	 * @param owner
	 *
	 */
	public static function removeCacheOwner( type : String, url : String, owner : Dynamic ) : Void {
		var info : AssetInfo = getFromCache( type, url );
		if ( info != null) {
			info.removeOwner( owner );
		}
	}

	/**
	 * 取消全部加载项
	 *
	 */
	public static function cancelAll() : Void {
		_waitList.clear();
		closeAll();
	}

	/**
	 * 取消指定的加载
	 * @param url
	 * @param complete
	 *
	 */
	public static function cancel( type : String, url : String, complete : Dynamic ) : Void {
		if ( complete == null ) {
			return;
		}
		//
		_waitList.remove( url, type, complete );
		if ( _waitList.hasWaitInfo( url ) == false ) {
			closeUrl( url );
		}
		nextAsset();
	}

	/**
	 * url列表的所有加载
	 * @param urlVec
	 * @param complete
	 *
	 */
	public static function cancelVec( urlVec : Array<String>, type : String, complete : Dynamic ) : Void {
		if ( complete == null ) {
			return;
		}
		//
		for ( url in urlVec ) {
			_waitList.remove( url, type, complete );
			if ( _waitList.hasWaitInfo( url ) == false ) {
				closeUrl( url );
			}
		}
		nextAsset();
	}

	/**
	 * 取消指定url的全部加载
	 * @param url
	 *
	 */
	private static function cancelUrl( url : String, type : String ) : Void {
		var baseCache : BaseCache = _cacheMap.get( type );
//			if ( baseCache.useRefCount ) {
//				throwError( "type: " + type + ",需要使用引用计数" );
//			}
		var aInfo : AssetInfo = baseCache.getAssetInfo( url );
		var info : WaitInfo = _waitList.removeUrlType( url, type );
		if ( info != null ) {
			if ( aInfo != null ) {
				var keys:Array<Dynamic> = info.itemMap.keys();
				for ( i in 0...keys.length) {
					var itemInfo : LoadingItemInfo = info.itemMap.get(keys[i]);
					if ( itemInfo.ref != null) {
						aInfo.removeOwner( itemInfo.ref );
					}
				}
			}
			info.dispose();
		}
		if ( _waitList.hasWaitInfo( url ) == false ) {
			closeUrl( url );
		}
		nextAsset();
	}

	//--------------------------------------------------------------
	//
	//--------------------------------------------------------------

	private static function closeAll() : Void {
		var keys = _loaderMap.keys();
		for (i in 0...keys.length  ) {
			var loader : StreamLoader = _loaderMap.get(keys[i]);
			closeLoader( loader );
		}
		_loaderMap = new FastHashMap<StreamLoader>();
	}

	private static function closeUrl( url : String ) : Void {
		var loader : StreamLoader = _loaderMap.get( url );
		closeLoader( loader );
		_loaderMap.remove(url);
	}

	private static function closeLoader( loader : StreamLoader ) : Void {
		if ( loader != null ) {
			doTrace( "AssetManager closeLoader", loader.url );
			loader.removeEventListener( Event.OPEN, onOpen );
			loader.removeEventListener( Event.COMPLETE, onComplete );
			loader.removeEventListener( ProgressEvent.PROGRESS, onProgress );
			loader.removeEventListener( IOErrorEvent.IO_ERROR, onError );
			loader.removeEventListener( SecurityErrorEvent.SECURITY_ERROR, onError );
			loader.close();
			LoaderPool.input( loader );
		}
	}

	private static function nextAsset() : Void {
		if ( _isStop || _waitList.length == 0 ) {
			_mc.removeEventListener( Event.ENTER_FRAME, onEnter );
			return;
		}
		if ( delayTime > 0 ) {
			_startNextTime = Lib.getTimer();
			_mc.addEventListener( Event.ENTER_FRAME, onEnter );
		} else
		{
			_nextAsset();
		}
	}

	private static function onEnter( event : Event ) : Void {
		if ( _isStop || _waitList.length == 0 ) {
			_mc.removeEventListener( Event.ENTER_FRAME, onEnter );
			return;
		}
		if ( Lib.getTimer() - _startNextTime > delayTime ) {
			_nextAsset();
		}
	}

	private static function _nextAsset() : Void {
		//是否还有可加载信息
		var info : WaitInfo = getWaitInfo();
		if ( info != null ) {
			startRemote( info );
		} else
		{
			_mc.removeEventListener( Event.ENTER_FRAME, onEnter );
		}
	}

	private static function startRemote( info : WaitInfo ) : Void {
		if ( _loaderMap.size() >= maxLoadNum ) {
			_mc.removeEventListener( Event.ENTER_FRAME, onEnter );
			return;
		}
		var loader : StreamLoader = LoaderPool.output();
		startLoad( loader, info );
		CallBackUtil.open( info.itemMap, info.url );
	}

	private static function getWaitInfo() : WaitInfo {
		for (info in _waitList.data ) {
			if (!_loaderMap.exists(info.url) && !_parsingMap.exists(info.url))
				return info;
		}
		return null;
	}

	private static function startLoad( loader : StreamLoader, info : WaitInfo ) : Void {
		doTrace( "AssetManager startLoad", info.url );
		_loaderMap.set( info.url, loader );
		loader.clearTimeout();
		loader.addEventListener( Event.OPEN, onOpen );
		loader.addEventListener( Event.COMPLETE, onComplete );
		loader.addEventListener( ProgressEvent.PROGRESS, onProgress );
		loader.addEventListener( IOErrorEvent.IO_ERROR, onError );
		loader.addEventListener( SecurityErrorEvent.SECURITY_ERROR, onError );
		loader.timeoutId = Timer.delay(function():Void{
			onTimeout(info.url);
		}, Max_Time);
		loader.doLoad( info );
	}

	private static function onTimeout( url : String ) : Void {
		var waitInfos : Array<WaitInfo> = _waitList.getWaitInfos( url );
		for ( info  in waitInfos ) {
			if ( info != null ) {
				if ( info.timeCount >= maxTimeoutCount ) {
					parseError( url, "加载重试次数到达上限" + maxTimeoutCount + "," + info.url );
					nextAsset();
				} else {
					info.timeCount++;
					var loader : StreamLoader = _loaderMap.get(info.url);
					if ( loader != null ) {
						startLoad( loader, info );
						return;
					} else {
						parseError( url, "加载重试load已被取消" + maxTimeoutCount + "," + info.url );
						nextAsset();
					}
				}
			}
		}
	}

	//--------------------------------------------------------------
	//
	//--------------------------------------------------------------

	private static function onOpen( event : Event ) : Void {
		//var loader : StreamLoader = event.currentTarget as StreamLoader;
	}

	private static function onComplete( event : Event ) : Void {
		var loader : StreamLoader = cast event.currentTarget;
		untyped _waitArray.length = 0;
		var waitInfos : Array<WaitInfo> = _waitList.getWaitInfos( loader.url, _waitArray );
		if ( waitInfos.length > 0 ) {
			var bytes : ByteArray = new ByteArray();
			loader.readBytes( bytes );
			for ( info in waitInfos ) {
				if ( info != null ) {
					doTrace( "AssetManager onComplete", info.url );
					bytes.position = 0;
					startParse( info, bytes );
				}
			}
		}
	}

	private static function startParse( info : WaitInfo, bytes : ByteArray ) : Void {
		var p : Dynamic = _parserMap.get( info.type );
		if ( Std.is(p, BaseParser) ) {
			p.setType( info.type );
			p.initialize( parseComplete, parseError, info.isCache );
			_parsingMap.set( info.url, p );
			p.parse( info.url, bytes );
		} else if (Std.is(p,Class)) {
			var ip : BaseParser = cast Type.createInstance(p, []);
			ip.setType( info.type );
			ip.initialize( parseComplete, parseError, info.isCache );
			_parsingMap.set( info.url, ip );
			ip.parse( info.url, bytes );
		} else
		{
			parseError( info.url );
		}
	}

	private static function parseComplete( info : AssetInfo, isCache : Bool ) : Void {
		_parsingMap.remove( info.url );
		if ( info.type == null )
			throwError( "AssetManager onComplete url=" + info.url + ", type=" + info.type );
		var waitInfo : WaitInfo = _waitList.removeUrlType( info.url, info.type );
		if ( waitInfo != null ) {
			if ( isCache ) {
				var cache : BaseCache = _cacheMap.get( waitInfo.type );
				if ( cache != null) {
					cache.addAssetInfo( info );
				}
			}
			CallBackUtil.complete( waitInfo.itemMap, info );
			waitInfo.dispose();
		}
		closeUrl( info.url );
		nextAsset();
	}

	private static function onError( event : IOErrorEvent ) : Void {
		var loader : StreamLoader = cast event.currentTarget;
		loader.clearTimeout();

		var waitInfos : Array<WaitInfo> = _waitList.getWaitInfos( loader.url );
		for ( i in 0...waitInfos.length) {
			var info : WaitInfo = waitInfos[ i ];
			if ( info.timeCount < maxTimeoutCount ) {
				info.timeCount++;
				var loadert : StreamLoader = _loaderMap.get(info.url);
				if ( loadert != null ) {
					startLoad( loadert, info );
					return;
				}
			}
		}

		parseError( loader.url, "不存在 event.text:" + event.text + "event.errorID:" + event.errorID );
		nextAsset();
	}

	private static function parseError( url : String, msg : String = "" ) : Void {
		doTrace( "AssetManager parseError", "解析出错url:" + url + msg );
		throwError( "解析出错url:" + url + msg );
		var waitInfos : Array<WaitInfo> = _waitList.removeUrl( url );
		if ( waitInfos != null ) {
			for ( info in waitInfos ) {
				doTrace( "AssetManager onError", info.url );
				CallBackUtil.error( info.itemMap, info.url );
				info.dispose();
			}
		}
		closeUrl( url );
	}

	private static function onProgress( event : ProgressEvent ) : Void {
		if ( event.bytesTotal > 0 ) {
			var loader : StreamLoader = cast event.currentTarget;
			var waitInfos : Array<WaitInfo> = _waitList.getWaitInfos( loader.url, _waitArray );
			if ( waitInfos != null ) {
				for ( waitInfo in waitInfos ) {
					CallBackUtil.progress( waitInfo.itemMap, event.bytesLoaded, event.bytesTotal );
				}
			}
		}
	}

	private static function throwError( msg : String ) : Void {
		if ( isThrowError )
			throw msg;
	}

	public static function startFastMode() : Void {
		maxLoadNum = fastMaxLoadNum;
		delayTime = 0;
	}

	public static function stopFastMode() : Void {
		maxLoadNum = defaultMaxLoadNum;
		delayTime = defaultDelayTime;
	}

	public static function getCacheSimpleLog() : String {
		var log : String = "";
		var baseCache : BaseCache;
		var keys = _cacheMap.keys();
		for ( i in 0...keys.length ) {
			baseCache = _cacheMap.get( keys[i] );
			log += "count:" + baseCache.count;
			log += "\n";
		}
		return log;
	}

	public static function getCacheLog() : String {
		var log : String = "";
		var baseCache : BaseCache;
		var assetInfo : AssetInfo;
		log += "getTimer():" + Lib.getTimer();
		log += "\n";
		log += getCacheSimpleLog();

		var keys = _cacheMap.keys();
		for ( i in 0...keys.length ) {
			baseCache = _cacheMap.get( keys[i] );
			log += "count:" + baseCache.count;
			log += "\n";
			for ( assetInfo in baseCache.assetInfos ) {
				log += "\turl:" + assetInfo.url + " numOwners:" + assetInfo.numOwners + " noUseTime:" + assetInfo.noUseTime;
				log += "\n";
			}
			log += "----------------------------------------------------------------------------";
			log += "\n";
		}
		return log;
	}
}

