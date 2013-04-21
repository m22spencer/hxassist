package test;

import haxe.macro.Expr;
import haxe.macro.Context;
using Lambda;
using Alg;
import Alg.Fn;

class TestBuilder {
    /**
       Builds each toplevel statement as a separate test.
       Optional expressiont to be evaluated afterward can be passed in
       RESULT == {var ret = EXPRESSION; $eval;}
    **/
    static function build(eval:Expr):Array<Field> {
        var fields = Context.getBuildFields();
        if (eval == null) eval = macro ret;
        
        var n = 0;
        return flatMap(fields, function(field) {
                switch field.kind {
                case FFun(f):
                    switch f.expr.expr {
                    case EBlock(e):
                        return e.map(function(e) return switch e.expr {
                                case EBinop(OpEq, a, b): mk('test_${n++}', macro @:pos(a.pos) assertEquals($a, {var ret = $b; $eval;})); 
                                case _: throw "Only == operator may be used";
                        });
                    default: throw "first level expression must be a block";
                    }
                default: throw "invalid field";
                }
            }).array();
    }

    static function getCString(a:Expr) {
        return switch a.expr {
        case EConst(CString(s)): s;
        default: throw "Not a CSTring";
        }
    }

    static function mk(name:String, expr:Expr):Field {
        return {
            name:name,
            kind:FFun({expr:expr, args:[], params:[], ret:null}), 
            pos:expr.pos
            } 
    }

    static function flatMap<T,K>(source:Iterable<T>, f:T->Iterable<K>):Iterable<K> {
        var out:Iterable<K> = [];
        for (elem in source) out = Lambda.concat(out, f(elem));
        return out;
    }

    macro public static function doCheck(s:String, i:Int) {
        //OnGenerate is not called during --display mode. We have to use primative completion
        Context.onGenerate(function(types) {
                var i = i;
                for (type in types) {
                    switch (type) {
                    case TInst(t,_):
                        var t = t.get();
                        var file = Std.string(Context.getPosInfos(t.pos).file);
                        if (s == Context.getPosInfos(t.pos).file) {
                            trace('matched file');
                            var fields = t.statics.get()
                                .concat(t.fields.get())
                                .concat(t.constructor!=null?[t.constructor.get()]:[]);
                            var expr = fields.filter(function(s) return
                                Context.getPosInfos(s.pos).let(function(_) return (_.min < i && _.max > i)))
                                .array()[0];

                            var expr = expr.expr();

                            var expr = Context.getTypedExpr(expr);

                            trace("Marker beginning " + sys.io.File.read(s, true).readAll().toString()
                                .substr(i, 10));

                            /*
                            switch (hxassist.TypeParser.expressionBeginningAtPoint(i, expr)) {
                            case Some(v): throw new haxe.macro.Printer().printExpr(v);
                            case None: throw 'No expression found at point $i';
                            }
                            */

                            trace(hxassist.TypeParser.forwardTypeExpression(i, expr));
                        }
                    default:
                    }
                }
            });

        return macro null;
    }
}