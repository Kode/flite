package openfl._internal.app;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.Tools;

class EventMacro {
	static function build():ComplexType {
		var args = switch Context.getLocalType() {
			case TInst(_, [_.follow() => TFun(args, _)]): args;
			default: throw false;
		};
		return TPath({
			pack: ["openfl", "_internal", "app"],
			name: "Event",
			sub: "Event" + (args.length),
			params: [for (arg in args) TPType(arg.t.toComplexType())]
		});
	}
}
#end
