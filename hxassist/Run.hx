package hxassist;

import ds.IList;
import com.mindrocks.monads.instances.Prelude;

using sys.FileSystem;
using Alg;

class Run {
    static function main() new Run(Sys.args());

   
    function new(args:Iterable<String>) {
        var _0;

        [0].map(function(x) { x; return x + "";});

        
        function readArgs(args:IList<String>) {
            Alg.match(switch (args) {
                case {"-runTests"; _;}:
                    new test.TestMain();
                case {"--type"; data; l;}:
                    var sp = data.split("@");
                    var pos = Std.parseInt(sp[1]);
                    var file = sp[0];

                    AutoMake.fromFile(file)
                        (["-dce", "no",  "-D", "no-copt", "--macro", 'test.TestBuilder.doCheck(\'$file\', $pos)']);
                
                    Sys.exit(0);
                    readArgs(l);
                case {cmd; l;}:
                    trace('unknown argument $cmd');
                    readArgs(l);
                case {[];}:
                    });
        }
        readArgs(IList.ilist(args));
    }
}