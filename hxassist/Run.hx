package hxassist;

import ds.IList;
import com.mindrocks.monads.instances.Prelude;

using sys.FileSystem;
using Alg;

class Run {
    static function main() new Run(Sys.args());

   
    function new(args:Iterable<String>) {
        //Get lib path from end of args 
        var list = IList.ilist(args).reverse();
        var expath = list.head();
        Sys.setCwd(expath);
        var list = list.tail().reverse();

        function readArgs(args:IList<String>) {
            Alg.match(switch (args) {
                case {"-runTests"; l;}:
                    new test.TestMain();
                    readArgs(l);
                case {"--type"; file; tpath; pos; l;}:
                    var pos = Std.parseInt(pos);

                    AutoMake.fromFile(file)
                        (["-dce", "no",  "-D", "no-copt", "-cp", "C:/Users/Matthew/Documents/Github/hxassist/", "--macro",
                            "haxe.macro.Compiler.addMetadata('@:build(test.TestBuilder.doBuildCheck("+pos+"))', '"+tpath+"')"]);
                
                    Sys.exit(0);
                    readArgs(l);
                case {cmd; _;}:
                    trace('unknown argument $cmd');
                case {[];}:
                    });
        }
        readArgs(list);
    }
}