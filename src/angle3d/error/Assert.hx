package angle3d.error;

#if macro
	import haxe.macro.Context;
	import haxe.macro.Expr;
#end

/**
	Assertion macro injects an assertion statement.

	An assertion specifies a condition that you expect to be true at a point in your program.

	If that condition is not true, the assertion fails, throwing an instance of the `AssertError` class.
**/
class Assert {
	macro public static function assert(predicate:Expr, ?info:Expr):Expr {
		if (!Context.defined("debug")) return macro {};

		var error = false;
		switch (Context.typeof(predicate)) {
			case TAbstract(_, _):
			case _: error = true;
		}

		if (error) Context.error("predicate should be a boolean", predicate.pos);

		var hasInfo = true;
		switch (Context.typeof(info)) {
			case TMono(t):
				error = t.get() != null;
				hasInfo = false;

			case TInst(t, _):
				error = t.get().name != "String";
			case _: error = true;
		}

		if (error) Context.error("info should be a string", info.pos);

		var p = Context.currentPos();

		var infoStr =
			if (hasInfo)
				EBinop(OpAdd, info, {expr: EConst(CString(" (" + new haxe.macro.Printer().printExpr(predicate) + ")")), pos: p});
		else
			EConst(CString(new haxe.macro.Printer().printExpr(predicate)));

		var eif = {expr: EThrow({expr: ENew({name: "AssertError", pack: ["org", "angle3d", "error"], params: []}, [{expr: infoStr, pos: p}]), pos: p}), pos: p};
		var econd = {expr: EBinop(OpNotEq, {expr: EConst(CIdent("true")), pos: p}, predicate), pos: p};
		return {expr: EIf(econd, eif, null), pos: p};
	}
}