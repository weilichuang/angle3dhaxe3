package org.angle3d.asset;

/**
 * 资源类型 
 */	
class LoaderType
{
	/**
	 * 直接的swf加载内容，不做任何处理
	 */		
	public static inline var SWF:String = "swf";
	/**
	 * 应用程序域，域资源获取使用的类型，比如预览等需要缓存的矢量资源
	 */		
	public static inline var DOMAIN:String = "domain";
	/**
	 * 文本
	 */		
	public static inline var TEXT:String = "text";
	/**
	 * 字节
	 */		
	public static inline var BINARY:String = "binary";
	/**
	 * 图片
	 */		
	public static inline var IMAGE:String = "image";
}