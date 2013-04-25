package hxassist;

import haxe.macro.Expr;
import haxe.macro.Context;
import com.mindrocks.monads.Monad;

import haxe.ds.Option;

enum Either<LVal,RVal> {
    Left(l:LVal);
    Right(r:RVal);
}

class ErrorM {
    macro public static function dO(body:Expr) {
        return Monad._dO("ErrorM", body, Context, Optimizer.optimize.bind("ErrorM"));
    }

    inline public static function monad<T,K>(o:Either<T,K>)
        return ErrorM;

    inline public static function ret<L,R>(x:R)
        return Right(x);

    inline public static function throwError<L,R>(err:L)
        return Left(err);

    inline public static function tryRet<L,R>(f:Void->R)
        return try Right(f()) catch(e:Dynamic) Left(e);

    inline public static function map <L,T,K> (e:Either<L,T>, f:T->K):Either<L,K> {
        return switch (e) {
        case Right(l): Right(f(l));
        case Left(r): Left(r);
        }
    }

    inline public static function flatMap <L,T,K> (e:Either<L,T>, f:T->Either<L,K>):Either<L,K> {
        return switch (e) {
        case Right(l): f(l);
        case Left(r): Left(r);
        }
    }
}

class OptionM {
    macro public static function dO(body:Expr) {
        return Monad._dO("OptionM", body, Context, Optimizer.optimize.bind("OptionM"));
    }

    inline public static function monad<T>(o:Option<T>)
        return OptionM;

    inline public static function ret<T>(x:T)
        return Some(x);

    inline public static function map<T,K>(o:Option<T>, f:T->K):Option<K> {
        return switch (o) {
        case Some(v): Some(f(v));
        case None: None;
        }
    }

    inline public static function flatMap<T,K>(o:Option<T>, f:T->Option<K>):Option<K> {
        return switch (o) {
        case Some(v): f(v);
        case None: None;
        }
    }
}

#if macro
class Optimizer {
    public static function optimize(monadName:String, m:MonadOp, p:Position) {
        var monadRef = EConst(CIdent(monadName));
        function mk(e) return {expr:e, pos:Context.currentPos()};
        function isAValidName(name:String) {
            return try {
                Context.typeof(mk(EField(mk(monadRef), name)));
                true;
            } catch (e:Dynamic) {
                false;
            }
        }
#if MONAX_OPTIMIZE
        var m = Monad.genOptimize(m,p);
#end
        var opt = function(m) return optimize(monadName, m, p);
        return switch (m) {
        case MFlatMap(e, bindName, body):
            MFlatMap(opt(e), bindName, opt(body));
        case MMap(e, bindName, body):
            MMap(opt(e), bindName, opt(body));
        case MFuncApp(paramName, body, app):
            MFuncApp(paramName, opt(body), opt(app));
        case MExp(e):
            function loop(e:Expr) {
                return switch(e.expr) {
                case ECall({expr:EConst(CIdent(name))}, params) if (isAValidName(name)):
                    mk(ECall(mk(EField(mk(monadRef), name)), params));
                case _: haxe.macro.ExprTools.map(e,loop);
                }
            }
            MExp(loop(e));                    
        case m: m;
        }
        return m;
    }
}
#end