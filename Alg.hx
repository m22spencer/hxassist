package ;

import haxe.macro.Expr;
using Lambda;

class Alg {
    /**
       Generates a lambda
     
        When passed a single argument, prefixes with function(_) return.
        ex:  [0].map(Fn(_.toString())) //["0"]
      
        When passed more than one argument: FN(... parameters, expression)
        ex:  [10, 5].fold(Fn(a,b, a + b), 0); //15
    **/ 
    @:noUsing macro public static function Fn(l:Array<Expr>) {
        return switch (l) {
        case []: macro function() {}
        case [a]: macro function(_) return $a;
        case l:
            function getIdent(e) {
                return switch (l[0]) {
                case {expr:EConst(CIdent(s))}: return s;
                case _: throw "invalid name for parameter";
                }
            }
            var e = l.pop();
            return {expr:EFunction(null, {
                        ret:null,
                        params:[],
                        expr:macro return $e,
                        args:l.map(function(e) return {value:null, type:null, opt:false, name:getIdent(e)})
                        }), pos:e.pos};
        }
    }

    /**
       Compose two methods   f . g as f(g(x))
    **/
    public static function compose<T,K,S>(f:K->S, g:T->K):T->S {
        return function(t:T) return f(g(t));
    }

    /**
       Allows the binding of a value without exiting the expression
       Ex: 10.let(function(x) return x + 20) //30
    **/
    public static function let<T,K>(v:T, f:T->K):K return f(v);

    /**
       Runs lambda f over each element in souce
       building at tuple containing two iterables
       _0 of true elements
       _1 of false elements
     **/
    public static function partition<T>(source:Iterable<T>, f:T->Bool):{_0:Iterable<T>, _1:Iterable<T>} {
        var left = [];
        var right = [];
        for (elem in source) {
            if (f(elem)) left.push(elem);
            else right.push(elem);
        }
        return {_0:left, _1:right};
    }
    
    macro public static function toMap(source, keySelector) {
        return macro [for (elem in $source)
                $keySelector(elem) => elem];
    }

    macro public static function toMapMulti(source, keySelector) {
        return macro {
            var m = new Map(); 
            for (elem in source) {
                var key = f(elem);
                if (!m.exists(key)) m.set(key, []);
                else m.get(key).push(elem);
            }
            return m;
        }
    }

    public static function first<T>(source:Iterable<T>) {
        for (elem in source) return elem;
        throw "Out of bounds. source contains no elements";
    }

    /**
       Allow a pattern match to work on IList<T> with {x; xs;} style
          {[];} represents empty set
          {a; b; [];}; is a list of type (a (b Nil));

          ( = and | do not currently work, I'll fix this soon)
    **/
    macro public static function match(sw:Expr) {
        #if macro 
        function listReplacer(expr:Expr):Expr {
            return switch (expr.expr) {
            case EBlock(e):
                function map(e:Array<Expr>):Expr {
                    var first = e[0];
                    var rest = e.slice(1);
                    return if (e.length == 0) throw "impossible.. list must accept a tail";
                    else if (e.length == 1) macro {_tail:$first};
                    else {
                        var rest = map(e.slice(1));
                        macro @:pos(first.pos) {_head:$first, _tail:$rest};
                    }
                }
                function loop(cells:Array<Expr>):Expr {
                    return switch (cells.slice(0,2)) {
                    case [a = {expr:EArrayDecl([])}]: macro @:pos(a.pos) ds.Cell.Nil;
                    case [a = {expr:EConst(CIdent(_))}]: macro @:pos(a.pos) $a;
                    case [a, _]:
                        var n = loop(cells.slice(1));
                        macro @:pos(a.pos) ds.Cell.Cons($a, $n);
                    default: throw "Could not build cell match expression"; null;
                    }
                }
                loop(e);
            default: haxe.macro.ExprTools.map(expr, listReplacer);
            }
        }

        var e = switch (sw.expr) {
        case ESwitch(e, cases, edef):
        //
        var cases = cases
        .map(function(cs) return {
                values:cs.values.map(function(v) return listReplacer(v)).array(),
                guard:cs.guard,
                expr:cs.expr
            }).array();
        {expr:ESwitch(e, cases, edef), pos:sw.pos};
        default: throw "Must be passed a switch";
        }
        //trace(new haxe.macro.Printer().printExpr(e));
        return e;
        #end
    }
}
