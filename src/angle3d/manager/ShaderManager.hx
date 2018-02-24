package angle3d.manager;

import haxe.ds.IntMap;
import haxe.ds.StringMap;
import angle3d.shader.Shader;

/**
 * 注册和注销Shader管理
 */
class ShaderManager
{
	public static var instance:ShaderManager;
	public static function init():Void
	{
		instance = new ShaderManager();
	}

	private var _shaderCode2Id:StringMap<Int>;
	private var _compiledShaderCount : Int = 0;
	private var _shaderCache:IntMap<Shader>;

	private function new()
	{
		_shaderCode2Id = new StringMap<Int>();
		_compiledShaderCount = 0;
		_shaderCache = new IntMap<Shader>();
	}

	/**
	 * 注册一个Shader
	 * @param vertexSource
	 * @param fragmentSource
	 */
	public function registerShader(vertexSource:String, fragmentSource:String):Shader
	{
		var vertexCodeId : Int = shaderCode2Id( vertexSource );
		if ( vertexCodeId == -1) 
		{
			vertexCodeId = _compiledShaderCount;
			_shaderCode2Id.set(vertexSource, vertexCodeId);
			_compiledShaderCount++;
		}
		
		var fragCodeId : Int = shaderCode2Id( fragmentSource );
		if ( fragCodeId == -1) 
		{
			fragCodeId = _compiledShaderCount;
			_shaderCode2Id.set(fragmentSource, fragCodeId);
			_compiledShaderCount++;
		}
		
		var shader:Shader = null;
		var programeKey : Int = getShaderKey( vertexCodeId, fragCodeId );
		if ( !_shaderCache.exists(programeKey) )
		{
			shader = mShaderCompiler.complie(vertexSource, fragmentSource);
			shader.id = programeKey;
			_shaderCache.set(programeKey, shader);
		}
		else
		{
			shader = _shaderCache.get(programeKey);
		}

		shader.registerCount++;

		//#if debug
		//Logger.log("[REGISTER SHADER]\n" + vertexSource+"\n" + fragmentSource + "\n" + " count:" + shader.registerCount);
		//#end

		return shader;
	}

	/**
	 * 注销一个Shader,Shader引用为0时销毁对应的Progame3D
	 * @param shader
	 */
	public function unregisterShader(shader:Shader):Void
	{
		if (shader.registerCount > 0)
		{
			shader.registerCount--;

			//#if debug
			//Logger.log("[UNREGISTER SHADER]" + shader + " count:" + shader.registerCount);
			//#end
		}
	}
	
	private inline function getShaderKey( vertexId : Int, fragmentId : Int ) : Int
	{
		#if debug
		if ( vertexId <= -1 || fragmentId <= -1 )
		{
			throw "NoShaderFindError";
		}
		if ( vertexId >= 65536 || fragmentId >= 65536 ) 
		{
			throw "ShaderExceedsIdxError";
		}
		#end
		
		return (vertexId << 16) + fragmentId;
	}
	
	private function shaderCode2Id( code : String ) : Int 
	{
		if ( _shaderCode2Id.exists(code) )
		{
			return _shaderCode2Id.get(code);
		}
		return -1;
	}
}