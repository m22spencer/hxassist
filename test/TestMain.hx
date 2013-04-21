package test;

import haxe.unit.*;
using hxassist.TypeParser;
using test.TestMain.MaybeUtils;
using Lambda;

class TestMain {
    public function new() {
        var r = new TestRunner();
        r.add(new Tests());
        r.run();
    } 

    public static var teste = macro Maybe.Just(10).bind(function(x) return Maybe.Nothing);
    
    macro public static function check(lpos:Int) {
        var min = haxe.macro.Context.getPosInfos(teste.pos).min;
        var pos = min + lpos;
        var type = TypeParser.forwardTypeExpression(pos, teste);
        return {expr:EConst(CString(type)), pos:haxe.macro.Context.currentPos()};
    }

    macro public static function checkE(lpos:Int, expr) {
        var min = haxe.macro.Context.getPosInfos(expr.pos).min;
        var pos = min + lpos;
        var type = TypeParser.forwardTypeExpression(pos, expr);
        return {expr:EConst(CString(type)), pos:haxe.macro.Context.currentPos()};
    }
}

#if !macro
@:build(test.TestBuilder.build(ret))
#end
class Tests extends haxe.unit.TestCase {
    public function test() {
        /*
        "test.#Maybe<Int>" == TestMain.check(0);
        "(v:Int):test.Maybe<Int>" == TestMain.check(6);
        "Int" == TestMain.check(11);
        "bind(f:Int->Maybe<String>):test.Maybe<String>" == TestMain.check(15);
        "Int->Maybe<String>" == TestMain.check(20);
        "Int" == TestMain.check(29);
        "test.#Maybe<Unknown>" == TestMain.check(39);
        "test.Maybe<Unknown>" == TestMain.check(45);
        "test.Maybe<Unknown>" == TestMain.check(52);
        */
    }

    public function untypedTests() {
        //Have issues with lambdas being typed too early
    }
}

enum Maybe<T> {
    Just(v:T);
    Nothing;
}

class MaybeUtils {
    public static function bind<T,K>(m:Maybe<T>, f:T->Maybe<K>):Maybe<K> {
        return switch (m) {
        case Just(v): f(v);
        default: Nothing;
        }
    }
}

class SomeTest {
    public static function main() {
        test.TestMain.Maybe.Just(10).bind(function(x) return test.TestMain.Maybe.Just(x + ""));
    }
}


















