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
        var libpath = list.head();
        var list = list.tail().reverse();

        function readArgs(args:IList<String>) {
            Alg.match(switch (args) {
                case {"-runTests"; l;}:
                    new test.TestMain();
                    readArgs(l);
                case {"--type"; data; l;}:
                    var sp = data.split("@");
                    var pos = Std.parseInt(sp[1]);
                    var file = sp[0];

                    trace(pos);

                    AutoMake.fromFile(file)
                        (["-dce", "no",  "-D", "no-copt", "-cp", "C:/Users/Matthew/Documents/Github/hxassist/", "--macro", 'test.TestBuilder.doCheck(\'$file\', $pos)']);
                
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