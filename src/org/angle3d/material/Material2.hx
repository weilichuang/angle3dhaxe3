package org.angle3d.material;

import flash.errors.Error;
import haxe.ds.StringMap;
import org.angle3d.material.technique.Technique;
import org.angle3d.math.Color;
import org.angle3d.math.Matrix4f;
import org.angle3d.math.Vector2f;
import org.angle3d.math.Vector3f;
import org.angle3d.math.Vector4f;
import org.angle3d.texture.TextureMapBase;
import org.angle3d.texture.TextureType;
import org.angle3d.utils.Assert;
import org.angle3d.utils.Logger;


/**
 * 一个Material可能有多个Technique
 * @author weilichuang
 *
 */
class Material2
{
	public var name:String;
	public var transparent:Bool;

	public var def:MaterialDef;
	
	public var sortingId:Int;

	public var receivesShadows(get, set):Bool;
	

	private var mReceivesShadows:Bool;

	

	private var paramValues:StringMap<MatParam>;
	private var technique:Technique;
	private var techniques:StringMap<Technique>;

	private var nextTexUnit:Int;

	public function new(def:MaterialDef)
	{
		this.def = def;

		paramValues = new StringMap<MatParam>();
		techniques = new StringMap<Technique>();
		
		transparent = false;
		mReceivesShadows = false;
		sortingId = -1;
		nextTexUnit = 0;
	}

	/**
	 * get_the material definition (j3md file info) that <code>this</code>
	 * material is implementing.
	 *
	 * @return the material definition this material implements.
	 */
	public function getMaterialDef():MaterialDef
	{
		return def;
	}

	/**
	 * Check if setting the parameter given the type and name is allowed.
	 * @param type The type that the "set" function is designed to set
	 * @param name The name of the parameter
	 */
	private function checkSetParam(type:String, name:String):Void
	{
		var paramDef:MatParam = def.getMaterialParam(name);
		if (paramDef == null)
		{
			throw new Error("Material parameter is not defined: " + name);
		}
		
		if (type != null && paramDef.type != type) 
		{
			Logger.warn("Material parameter being set: {$name} with "
				+ "type {$type} doesn''t match definition types {$paramDef.type}");
		}
	}

	/**
	 * Pass a parameter to the material shader.
	 *
	 * @param name the name of the parameter defined in the material definition (j3md)
	 * @param type the type of the parameter {@link VarType}
	 * @param value the value of the parameter
	 */
	public function setParam(name:String, type:String, value:Dynamic):Void
	{
		checkSetParam(type, name);

		if (VarType.isTextureType(type))
		{
			setTextureParam(name, type, cast(value,TextureMapBase));
		}
		else
		{
			var matParam:MatParam = getParam(name);
			if (matParam == null)
			{
				paramValues.set(name, new MatParam(type, name, value));
			}
			else
			{
				matParam.value = value;
			}

			if (technique != null)
			{
				technique.notifyParamChanged(name, type, value);
			}
		}
	}

	/**
	 * Returns the parameter set_on this material with the given name,
	 * returns <code>null</code> if the parameter is not set.
	 *
	 * @param name The parameter name to look up.
	 * @return The MatParam if set, or null if not set.
	 */
	public inline function getParam(name:String):MatParam
	{
		return paramValues.get(name);
	}

	/**
	 * Clear a parameter from this material. The parameter must exist
	 * @param name the name of the parameter to clear
	 */
	public function clearParam(name:String):Void
	{
		checkSetParam(null, name);

		var matParam:MatParam = getParam(name);
		if (matParam == null)
		{
			return;
		}

		paramValues.remove(name);
		if (Std.is(matParam,MatParamTexture))
		{
			var texUnit:Int = cast(matParam,MatParamTexture).index;
			nextTexUnit--;
			var param:MatParam;
			var keys = paramValues.keys;
			for (key in keys)
			{
				var param:MatParam = paramValues.get(key);
				if (Std.is(param,MatParamTexture))
				{
					var texParam:MatParamTexture = cast(param, MatParamTexture);
					if (texParam.index > texUnit)
					{
						texParam.index = texParam.index - 1;
					}
				}
			}
			sortingId = -1;
		}
		
		if (technique != null)
		{
			technique.notifyParamChanged(name, null, null);
		}
	}


	/**
	 * set a texture parameter.
	 *
	 * @param name The name of the parameter
	 * @param type The variable type {@link VarType}
	 * @param value The texture value of the parameter.
	 *
	 * @throws IllegalArgumentException is value is null
	 */
	public function setTextureParam(name:String, type:String, value:TextureMapBase):Void
	{
		Assert.assert(value != null, "贴图不能为null");

		checkSetParam(type, name);
		var matParam:MatParamTexture = getTextureParam(name);
		if (matParam == null)
		{
			paramValues.set(name, new MatParamTexture(type, name, value, nextTexUnit++));
		}
		else
		{
			matParam.texture = value;
		}

		if (technique != null)
		{
			technique.notifyParamChanged(name, type, nextTexUnit - 1);
		}

		// need to recompute sort ID
		sortingId = -1;
	}

	/**
	 * Returns the texture parameter set_on this material with the given name,
	 * returns <code>null</code> if the parameter is not set.
	 *
	 * @param name The parameter name to look up.
	 * @return The MatParamTexture if set, or null if not set.
	 */
	public function getTextureParam(name:String):MatParamTexture
	{
		var param:MatParam = paramValues.get(name);
		if (Std.is(param,MatParamTexture))
		{
			return cast(param,MatParamTexture);
		}
		return null;
	}

	/**
	 * Pass a texture to the material shader.
	 *
	 * @param name the name of the texture defined in the material definition
	 * (j3md) (for example Texture for Lighting.j3md)
	 * @param value the Texture object previously loaded by the asset_manager
	 */
	public function setTexture(name:String, value:TextureMapBase):Void
	{
		if (value == null)
		{
			// clear it
			clearParam(name);
			return;
		}

		var paramType:String = null;
		switch (value.getType())
		{
			case TextureType.TwoDimensional:
				paramType = VarType.TEXTURE2D;
			case TextureType.CubeMap:
				paramType = VarType.TEXTURECUBEMAP;
			default:
				throw new Error("Unknown texture type: " + value.getType());
		}

		setTextureParam(name, paramType, value);
	}

	/**
	 * Pass a Matrix4f to the material shader.
	 *
	 * @param name the name of the matrix defined in the material definition (j3md)
	 * @param value the Matrix4f object
	 */
	public inline function setMatrix4(name:String, value:Matrix4f):Void
	{
		setParam(name, VarType.MATRIX4, value);
	}

	/**
	 * Pass a Bool to the material shader.
	 *
	 * @param name the name of the Bool defined in the material definition (j3md)
	 * @param value the Bool value
	 */
	public inline function setBool(name:String, value:Bool):Void
	{
		setParam(name, VarType.Bool, value);
	}

	/**
	 * Pass a float to the material shader.
	 *
	 * @param name the name of the float defined in the material definition (j3md)
	 * @param value the float value
	 */
	public inline function setFloat(name:String, value:Float):Void
	{
		setParam(name, VarType.FLOAT, value);
	}

	/**
	 * Pass an int to the material shader.
	 *
	 * @param name the name of the int defined in the material definition (j3md)
	 * @param value the int value
	 */
	public inline function setInt(name:String, value:Int):Void
	{
		setParam(name, VarType.FLOAT, value);
	}

	/**
	 * Pass a Color to the material shader.
	 *
	 * @param name the name of the color defined in the material definition (j3md)
	 * @param value the ColorRGBA value
	 */
	public inline function setColor(name:String, value:Color):Void
	{
		setParam(name, VarType.VECTOR4, value);
	}

	/**
	 * Pass a Vector2f to the material shader.
	 *
	 * @param name the name of the Vector2f defined in the material definition (j3md)
	 * @param value the Vector2f value
	 */
	public inline function setVector2(name:String, value:Vector2f):Void
	{
		setParam(name, VarType.VECTOR2, value);
	}

	/**
	 * Pass a Vector3f to the material shader.
	 *
	 * @param name the name of the Vector3f defined in the material definition (j3md)
	 * @param value the Vector3f value
	 */
	public inline function setVector3(name:String, value:Vector3f):Void
	{
		setParam(name, VarType.VECTOR3, value);
	}

	/**
	 * Pass a Vector4f to the material shader.
	 *
	 * @param name the name of the Vector4f defined in the material definition (j3md)
	 * @param value the Vector4f value
	 */
	public inline function setVector4(name:String, value:Vector4f):Void
	{
		setParam(name, VarType.VECTOR4, value);
	}

	/**
	 * Check if the material should receive shadows or not.
	 *
	 * @return True if the material should receive shadows.
	 *
	 * @see Material#setReceivesShadows(Bool)
	 */
	private inline function get_receivesShadows():Bool
	{
		return mReceivesShadows;
	}

	/**
	 * set if the material should receive shadows or not.
	 *
	 * <p>This value is merely a marker, by itself it does nothing.
	 * Generally model loaders will use this marker to indicate
	 * the material should receive shadows and therefore any
	 * geometries using it should have the {@link ShadowMode#Receive} set
	 * on them.
	 *
	 * @param receivesShadows if the material should receive shadows or not.
	 */
	private inline function set_receivesShadows(receivesShadows:Bool):Bool
	{
		return this.mReceivesShadows = receivesShadows;
	}
}
