package org.angle3d.utils;
import flash.utils.RegExp;
import org.angle3d.math.FastMath;


	class StringUtil
	{

		//private static var _formatRegExp:RegExp = new RegExp("{(\\d+)}", "g");
//
		//public static function format(input:String, ... values):String
		//{
			//return getFormat(input, values);
		//}
//
		//public static function getFormat(input:String, values:Array):String
		//{
			//if (input == null)
				//return "";
			//var result:String = input.replace(_formatRegExp, function():String
			//{
				//return values[parseInt(arguments[1])];
			//});
			//return result;
		//}

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
	}

