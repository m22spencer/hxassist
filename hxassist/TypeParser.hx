package hxassist;

import haxe.ds.Option;
import Alg.Fn;

using Alg;

import haxe.macro.*;
import haxe.macro.Expr;

using haxe.macro.ComplexTypeTools;
using haxe.macro.Context;
using haxe.macro.ExprTools;
using Lambda;
using Std;

using hxassist.Monads;


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
        return "";
        //TODO: search for package on failure type(haxe.ds).Option fails, but should result: "package haxe.ds"
        return switch (expressionBeginningAtPoint(point, e)) {
        case Some(matched):
            function loop(e) {
                return if (e == matched)
                    switch (e.expr) {
                    case EFunction(name, f) if (name == null):
                        var u = f.expr;
                        macro function(x) {__typeme = {type_x:x}; $u;};
                    case _: macro (__typeme = $e);
                    }
                else e.map(loop);
            }
            var eval = loop(e);
            var r = macro { var __typeme; $eval; __typeme;};
            trace(exprToStr(r));
            try printType(Context.typeof(r)) catch (e:Dynamic) 'TYPING FAILED: $e\r\n${exprToStr(r)}';
        case None: 'Unable to find expression at $point';
        }
    }
    /*
    static var init = function() {
        var typer = forwardTypeExpression2(macro Lambda.mapi([3.5], function(i,x) return x+""));
        switch (typer(19, true)) {
        case Some(t): trace(printType(t));
        case _: trace('No type found');
        }
    }();
    */
    
    /**
       Types all expressions within E
       returns a lamda for matching a byte position to a type
       lambda (point, useLocal)

       The macro breaks the following:
       bind(function(x) return x + "")

       Into this:
       var __t0, __t1, __t2, __t3, __t4, __t5;
       {__t0 = {__t1 = bind}(function(x) {{__t2 = x;}; {return {__t3 = {__t4 = x;} + {__t5 = "";};};};});};
       {__t0:__t0, __t1 ... etc}; //TYPE THIS

       The final type is then split up and reconnected into a final type for each position

       (Note that in the actual macro, names look as so:  __type__$min__$max_$(index|ret))

       Function arity is referred to as so:
       funtion(1, 2):0

       Thanks to CauÃª for the technique!
    **/
        public static function forwardTypeExpression2(e:Expr):Int->?Bool->Option<haxe.macro.Type> {

        var basepos = e.pos.getPosInfos();
        var cpos = Context.currentPos();
        function asIdent(s:String) return {expr:EConst(CIdent(s)), pos:cpos};
        var toType:Array<String> = [];
        function capture_name(e:Expr) {
            return e.pos.getPosInfos().let(Fn('__type__${_.min}_${_.max}'));
        }

        function capture_map(e:Expr, f:Expr->Expr) {
            var s = capture_name(e);
            if (toType.exists(Fn(_==s))) Context.warning("Duplicate key created, possible macro?", Context.currentPos());
            else toType.push(s);
            var e = e.map(f);

            var ident = {expr:EConst(CIdent(s)), pos:cpos};

            return macro {$ident = $e;};
        }

        var ret_capture = null;
        function loop(e:Expr) {
            return switch (e.expr) {
            case EFunction(fname, f):
                var captures = f.args.mapi(function(i,arg) return {name:arg.name, capture:capture_name(e) + "_" + arg.name});
                ret_capture = capture_name(e) + '_ret';
                captures.iter(function(_) return toType.push(_.capture));
                var e = loop(f.expr);
                var exprs = captures.map(function(_) return macro ${asIdent(_.capture)} = ${asIdent(_.name)}).array();
                
                var inner = macro {$b{exprs}; $e;};
                
                {expr:EFunction(fname, {
                            ret:f.ret,
                params:f.params,
                            args:f.args,
                expr:inner,
                            }), pos:e.pos };
            case EReturn(e) if (e != null):
                if (!toType.exists(Fn(_ == ret_capture))) toType.push(ret_capture);
                var retident = asIdent(ret_capture);
                var e = e.map(loop);
                var inner = macro {$retident = $e;};
                {expr:EReturn(inner), pos:cpos};
                
            case EVars(_): e.map(loop);     //can't type statements
            case EIn(e1, e2): 

                {expr:EIn(e1, capture_map(e2, loop)), pos:cpos};
                
                /* We skip these for now since they cause issues! */
            case EField(_, _): e.map(loop); //Tries to type packages
            case EConst(CIdent(_)): e.map(loop);    //(part of the above fix)

            case EBlock(_): e.map(loop);    //Causes missing return errors
            case EDisplay(e, _): e.map(loop);
            case _: 
                capture_map(e, loop);
            }
        }
        var capt = loop(e);

        trace(exprToStr(capt));



        var reg = ~/__type__([^_]*)_([^_]*)_?([^_]*)?/;

        function get3(s:String) {
            return if (!reg.match(s)) throw "impossible";
            else {
                var min = reg.matched(1).parseInt();
                var max = reg.matched(2).parseInt();
                var argname = reg.matched(3);
                {min:min, max:max, argname:argname};
            }
        }

        var vdecl = {expr:EVars(toType.map(Fn({name:_, type:null, expr:null}))), pos:cpos};
        var typed:Array<{type:haxe.macro.Type, pos:{min:Int, max:Int, argname:String}}> = 
            [for (val in toType) {
                    var ident = asIdent(val);
                    var type = try {
                        var eval = macro { $vdecl; $capt; $ident; };
                        Context.typeof(eval);
                    } catch(e:Dynamic) {
                        trace("Unable to type: " + e);
                        null;
                    }
                    {type:type, pos:get3(val)};
            }];
            

            
            /* Everything fails to type if a single item fails .. This is not safe
            var odecl = {expr:EObjectDecl({toType.map(Fn({field:_, expr:{expr:EConst(CIdent(_)), pos:cpos}})); [];}), pos:cpos};
        var eval = macro {
            $vdecl;
            $capt;
            $odecl;
        }

        trace(exprToStr(eval));
        var typeAll = Context.typeof(eval);

        

        var typed = switch (typeAll) {
        case TAnonymous(t):
        t.get().fields
        .map(Fn({type:_.type, pos:get3(_.name)}));
        case _: throw "impossible";
        }
            */

            trace(typed);

        var map = new haxe.ds.StringMap<Array<{type:haxe.macro.Type, pos:{min:Int, max:Int, argname:String}}>>();

        function write(x:{type:haxe.macro.Type, pos:{min:Int, max:Int, argname:String}}) {
            var key = x.pos.min + ":" + x.pos.max;
            if (!map.exists(key)) { map.set(key,[]); }
            map.get(key).push(x);
        }
        
        typed.iter(Fn(write(_)));

        var types = map.array();

        return function(point:Int, local:Bool = false):Option<Type> {
            var point = if (local) point + basepos.min; else point;
            var set = map.filter(function(t) return t.list().first().pos.min == point);
            return if (set.length == 0) None;
            else {
                var types = set.first();
                if (types.length == 1) Some(types.list().first().type);
                else {
                    //This is a lambda expression
                    var rettype:Type = if (types.exists(Fn(_.pos.argname == "ret"))) {
                        //Value returning function
                        var rett = types.filter(Fn(_.pos.argname == "ret"));
                        types = types.filter(Fn(_.pos.argname != "ret"));
                        rett.list().first().type;
                    } else haxe.macro.ComplexTypeTools.toType(macro : Void);

                    //FIXME this does not handle optional types yet
                    Some(TFun(types.map(Fn({t:_.type, opt:false, name:_.pos.argname})), rettype));
                }
            }
        }

    }

    public static function typeExpression(point:Int, e:Expr) {
        return switch (expressionBeginningAtPoint(point, e)) {
        case Some(matched):
            trace("Found expression at this point: " + matched);
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

    public static function expressionBeginningAtPoint(point:Int, e:Expr) {
        var matched = null;
        function loop(e:Expr)
            if (e.pos.getPosInfos().min == point) matched = e;
            else e.iter(loop);
        loop(e);
        return (matched==null)?None:Some(matched);
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
        case TAnonymous(t):
            '{'+t.get().fields.map(Fn(printType(_.type))).join(", ") + "}";
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










