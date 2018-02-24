package angle3d.utils;

class FileUtil {
	/**
	 * 获取文件内容
	 * @param	file
	 */
	public static macro function getFileContent(file:String) {
		var file = haxe.macro.Context.resolvePath(file);
		var m = haxe.macro.Context.getLocalClass().get().module;
		haxe.macro.Context.registerModuleDependency(m, file);
		return macro $v {sys.io.File.getContent(file)};
	}
}