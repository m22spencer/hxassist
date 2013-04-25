package hxassist;

import haxe.macro.Context;
import haxe.macro.Expr;
using Lambda;
using Alg;
using haxe.macro.TypeTools;
using haxe.macro.ComplexTypeTools;

class MacroBuilder {
#if macro

    macro public static function typeField(tpath:String, field:String) {
        Context.onGenerate(function(types) {
                for (type in types) {
                    switch (type) {
                    case TInst(t,_) if ('$t' == tpath):
                        var t = t.get();
                        var field = t.statics.get().filter(function(fld) return fld.name == field);
                        if (field.count() == 0) throw 'unable to find field $field';
                        var field = field.list().first();

                        if (field.expr == null) throw '$field has no expr';

                        var expr = Context.getTypedExpr(field.expr());
                        var typer = TypeParser.forwardTypeExpression2(expr);
                    case _:
                    }
                }
        });
        return macro "Nothing";
    }

    macro public static function typeField2(tpath:String, field:String) {
        switch (Context.getType(tpath)) {
        case TInst(t,_) if ('$t' == tpath):
            var t = t.get();
            var field = t.statics.get().filter(function(fld) return fld.name == field);
            if (field.count() == 0) throw 'unable to find field $field';
            var field = field.list().first();

            if (field.expr == null) throw '$field has no expr';

            var expr = Context.getTypedExpr(field.expr());
            var expr = fixTypedExprExpr(expr);
            var typer = TypeParser.forwardTypeExpression2(expr);
        case _:
        }
        return macro null;
    }
    
    //build macro
    public static function findDeclaration(pos:Int) {
        return applyFunAtExpr(Context.getBuildFields(), pos, function(e) {
                return macro hxassist.MacroBuilder.findDecl($e);
            });
    }

    static function fixTypedExprExpr(expr:Expr) {
        function loop(e:Expr):Expr {
            function mk(def:ExprDef) return {expr:def, pos:e.pos};

            var e = switch (e.expr) {
            case EVars(vars):
            var e = mk(EVars(vars.map(function(v) return {type:fixCT(v.type), name:v.name, expr:v.expr})));
            e;
            case ETry(e, catches):
            mk(ETry(e, catches.map(function(c) return {type:fixCT(c.type), name:c.name, expr:c.expr})));
            case EFunction(name, f):
            var args = f.args.map(function(_) return {value:_.value, type:fixCT(_.type), opt:_.opt, name:_.name});
            var fun = {
                ret:fixCT(f.ret),
                params:f.params.map(fixTPDecl),
                expr:f.expr,
                args:args
            };
            mk(EFunction(name, fun));
            case EDisplayNew(t): throw "NYI";
            case ECheckType(e, t): mk(ECheckType(e, fixCT(t)));
            case ECast(e, t): mk(ECast(e, fixCT(t)));
            default: e;
            }
            return haxe.macro.ExprTools.map(e, loop);
        }
        return loop(expr);
    }
    
    static function fixCT(t:Null<ComplexType>):Null<ComplexType> {
        return if (t == null) null;
        else switch (t) {
        case TPath(p):
            var mclass = false;
            var sub = if (p.sub == null) null;
            else if (p.sub.charAt(0) == "#") {
                mclass = true;
                p.sub.substr(1);
            }
            else p.sub;

            var sub = if (sub == p.name) null; else sub;
                    
            var nct = TPath({
                    sub:sub,
                    params:p.params.map(function(p) return switch (p) {
                        case TPType(t): TPType(fixCT(t)); 
                        default: p;
                        }),
                    pack:p.pack,
                    name:p.name
                });
            return if (mclass) macro :Class<$nct>;
            else nct;
        default: t;
        }
    }

    static function fixTPDecl(tpd:TypeParamDecl):TypeParamDecl {
        return {params:tpd.params.map(fixTPDecl), name:tpd.name, constraints:tpd.constraints.map(fixCT)};
    }

    //Creates an alias of the current module to use while typing
    //Since the current module is not available
    //(required to type after macro expansion)
    public static function shadowModule(module:String) {
        
    }

    public static function applyFunAtExpr(fields:Array<Field>, i:Int, fn:Expr->Expr) {
        var fields = fields.partition(function(f) return Context.getPosInfos(f.pos)
            .let(function(_) return _.min < i && _.max > i));
        return fields._0.map(function(f) {
                f.kind = switch (f.kind) {
                case FFun(f):
                var found = false;
                function loop(e:Expr):Expr {
                    var p = Context.getPosInfos(e.pos);
                    return if (p.min == i && !found) {
                        found = true;
                        fn(e);
                    } else haxe.macro.ExprTools.map(e, loop);
                }
                f.expr = loop(f.expr);
                FFun(f);
                case _: f.kind;
                }
                return f;
        }).concat(fields._1).array();
    }

    public static function posOfType(t:Type) {

    }
#end
}