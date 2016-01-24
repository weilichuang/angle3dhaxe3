/*
Copyright (c) 2012-2014 Michael Baczynski, http://www.polygonal.de

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
package de.polygonal.core.es;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.FileSystem;
import sys.io.File;
#end

/**
	Injects some static fields into every class extending from de.polygonal.core.es.Entity
**/
class EntityMacro
{
	#if macro
	inline public static var FILE = ".de.polygonal.core.es.entity_macro";
	#end
	
	macro public static function build():Array<Field>
	{
		//create unique name for local classes defined in a module
		var c = Context.getLocalClass().get();
		
		var className = c.name;
		var moduleName = c.module;
		
		var name = moduleName;
		name = name.substr(name.lastIndexOf(".") + 1); //make unqualified
		if (moduleName.indexOf(className) == -1)
			name += '_$className'; //moduleName_className
		
		var next = 0;
		if (FileSystem.exists(FILE))
		{
			next = Std.parseInt(File.getContent(FILE)) + 1;
			File.saveContent(FILE, Std.string(next));
		}
		else
			File.saveContent(FILE, "0");
		
		function field(pkg:String)
		{
			var p = Context.currentPos();
			var a = pkg.split(".");
			var e = {expr: EConst(CIdent(a[0])), pos: p};
			for (i in 1...a.length) e = {expr: EField(e, a[i]), pos: p};
			return FVar(null, e);
		}
		
		var fields = Context.getBuildFields();
		var p = Context.currentPos();
		
		//add "public static var ENTITY_TYPE:Int = x"
		fields.push(
		{
			name: "ENTITY_TYPE",
			doc: "All classes that inherit from Entity can be identified by an unique integer id.",
			meta: [{name: ":keep", pos: p}],
			access: [APublic, AStatic],
			
			#if aot //workaround for adobe iOS AOT compiler as it somehow messes up the integer values; doesn't seem to happen when using floats.
			kind: FVar(TPath({pack: [], name: "Float", params: [], sub: null}), {expr: EConst(CFloat(Std.string(next))), pos: p}),
			#else
			kind: FVar(TPath({pack: [], name: "Int", params: [], sub: null}), {expr: EConst(CInt(Std.string(next))), pos: p}),
			#end
			pos: p
		});
		
		//add "public static var SUPER_CLASS = x"
		var superClass:String = null;
		if (c.superClass != null) superClass = c.superClass.t.get().module;
		if (superClass == null) superClass = "null";
		fields.push(
		{
			name: "SUPER_CLASS",
			doc: "The superclass of this class.",
			meta: [{name: ":keep", pos: p}],
			access: [APublic, AStatic],
			kind: field(superClass),
			pos: p
		});
		
		//add "public static var ENTITY_NAME:String = x"
		fields.push(
		{
			name: "ENTITY_NAME",
			doc: "Equals 'moduleName_unqualifiedClassName'.",
			meta: [{name: ":keep", pos: p}],
			access: [APublic, AStatic],
			kind: FVar(TPath({pack: [], name: "String", params: [], sub: null}), {expr: EConst(CString(name)), pos: p}),
			pos: p
		});
		
		if (name == "Entity") return fields; //don't modify Entity constructor
		
		if (next > 0xffff) Context.fatalError("type value out of bounds", Context.currentPos());
		
		fields.push(
		{
			name: "__getType",
			doc: null,
			meta: [{name: ":noCompletion", pos: p}],
			access: [APrivate, AOverride],
			kind: FFun(
			{
				args: [],
				ret: null,
				expr: {expr: EBlock([{expr: EReturn({expr: EConst(CInt(Std.string(next))), pos: p}), pos: p}]), pos: p},
				params: []
				
			}),
			pos: p
		});
		
		return fields;
	}
}