package hxassist;

import haxe.ds.Option;
import Alg.Fn;

using Alg;

import haxe.macro.*;

using haxe.macro.ComplexTypeTools;
using haxe.macro.Context;
using haxe.macro.ExprTools;

class TypeParser {
    static var last:String = "Nothing";
    macro public static function check(point:Int, e:Expr) {
        trace(forwardTypeExpression(point, e));
        return e;
    }

    
    macro public static function tail():Expr {
        return {expr:EConst(CString(last)), pos:Context.currentPos()};
    }

    #if macro
    /* Attempt to get the type of an expression at POINT even if not typed in the context yet
     * @point   = byte offset of expression within file
     * @e      = Expression to wrap when searching for value
     */
    public static function forwardTypeExpression(point:Int, e:Expr) {
        //TODO: search for package on failure type(haxe.ds).Option fails, but should result: "package haxe.ds"
        return switch (expressionAtPoint(point, e)) {
        case Some(matched):
            function loop(e)
                return if (e == matched) macro (__typeme = $e);
            else e.map(loop);

            var eval = loop(e);
            var r = macro {var __typeme; $eval; __typeme;};
            try printType(Context.typeof(r)) catch (e:Dynamic) 'TYPING FAILED: $e\r\n${exprToStr(r)}';
        case None: 'Unable to find expression at $point';
        }
    }

    public static function typeExpression(point:Int, e:Expr) {
        return switch (expressionAtPoint(point, e)) {
        case Some(matched):
            printType(Context.typeof(matched));
        case None: 'Unable to find expression at $point';
        }
    }

    static function expressionAtPoint(point:Int, e:Expr) {
        var toMatch = {expr:null, max:Math.POSITIVE_INFINITY};
        function loop(e:Expr) {
            var p = e.pos.getPosInfos();
            if (p.min <= point && p.max > point)
            {
                toMatch.expr = e;
            }
            e.iter(loop);
        }
        loop(e);
        return (toMatch.expr==null)?None:Some(toMatch.expr);
    }

    static function exprToStr(e, ?pos:haxe.PosInfos) return new haxe.macro.Printer().printExpr(e);

    public static function checkExpr(e:Expr):String {
        return printType(e.typeof());
    }
    
    public static function printType(type:Type) {
        return try switch (type) {
        case TType(t,p):
            t.get().let(Fn(_.pack.concat([_.name]).join(".")))
                + printParams(p);
        case TMono(t):
            t.get().let(Fn(if (_==null) "Unknown";
                    else printType(_)));
        case TFun(args,ret):
            var ret = ret;
            args.map(Fn(_.name+((_.name!="")?":":"")+
                    switch (_.t) {
                    case Type.TFun(_,_): '(${printType(_.t)})';
                    case _: printType(_.t);
                    }))
                .join("->")
                
                .let(Fn(''+_+'->'+ if (ret == null) "Void"; else printType(ret)));
        case TEnum(t,p):
            t.get().let(Fn(_.pack.concat([_.name]).join(".")))
                + printParams(p);
        case TAbstract(t,p):
            t.get().let(Fn(_.pack.concat([_.name]).join(".")))
                + printParams(p);
        case TInst(t,p):
            t.get().let(Fn(_.pack.concat([_.name]).join(".")))
                + printParams(p);
        case _: throw 'unable to print type $type';
        } catch(e:Dynamic) '#NOTFOUND $e#';
    }

    public static function printParams(params:Array<Type>) {
        return switch (params) {
        case []: "";
        case _: '<${params.map(printType).join(",")}>';
        }
    }
    #end
}










