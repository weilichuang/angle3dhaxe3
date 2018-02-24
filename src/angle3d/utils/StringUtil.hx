package angle3d.utils;
import angle3d.math.FastMath;

class StringUtil
{
	/**
	 * 拆分并删除空行
	 * @param	str
	 * @param	p
	 * @return
	 */
	public static function splitAndTrim(str:String, p:String):Array<String>
	{
		var result:Array<String> = [];

		var list:Array<String> = str.split(p);
		var length:Int = list.length;
		for (i in 0...length)
		{
			var s:String = list[i];
			//非空行
			if (s != "")
			{
				result.push(s);
			}
		}

		return result;
	}

	/**
	 * 删除前后的空格
	 * @param	source
	 * @return
	 */
	public static function trim(source:String):String
	{
		var ereg:EReg = ~/^\s*|\s*$/g;
		return ereg.replace(source, "");
	}

	/**
	 * 删除所有空格
	 * @param	source
	 * @return
	 */
	public static function removeSpace(source:String):String
	{
		var ereg:EReg = ~/\s+/g;
		return ereg.replace(source, "");
	}

	/**
	 * 判断一个字符串是否是数字
	 */
	public static function isDigit(str:Dynamic):Bool
	{
		return !FastMath.isNaN(str);
	}
	
	public static function changeExtension(fileName:String, newExt:String):String
	{
		var index:Int = fileName.lastIndexOf(".");
		if (index != -1)
		{
			return fileName.substr(0, index+1) + newExt;
		}
		else
		{
			return fileName + "." + newExt;
		}
	}
	
	/**
	 * Returns a hash code for a string. The hash code for a
	 * `String` object is computed as
	 * <blockquote><pre>
	 * s[0]*31^(n-1) + s[1]*31^(n-2) + ... + s[n-1]
	 * </pre></blockquote>
	 * using `int` arithmetic, where `s[i]` is the
	 * <i>i</i>th character of the string, `n` is the length of
	 * the string, and `^` indicates exponentiation.
	 * (The hash value of the empty string is zero.)
	 *
	 * @return  a hash code value for this object.
	 */
	public static function hashCode(value:String):Int
	{
		var h:Int = 0;
		if (value.length > 0) 
		{
			for (i in 0...value.length) 
			{
				h = 31 * h + value.charCodeAt(i);
			}
		}
		return h;
	}
}

