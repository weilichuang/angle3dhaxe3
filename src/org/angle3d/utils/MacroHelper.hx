package org.angle3d.utils;
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

class MacroHelper {
	public static function getFileContent( fileName : Expr ) {
		var fileStr = null;
		switch ( fileName.expr ) {
			case EConst(c):
				switch ( c ) {
					case CString(s): fileStr = s;
					default:
				}
			default:
		};
		if ( fileStr == null )
			Context.error("Constant string expected",fileName.pos);
		return Context.makeExpr(sys.io.File.getContent(fileStr),fileName.pos);
	}
}
#end