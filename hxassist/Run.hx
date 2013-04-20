package hxassist;

import ds.IList;

using sys.FileSystem;

class Run {
    static function main() new Run(Sys.args());

    function new(args:Iterable<String>) {
        function readArgs(args:IList<String>) {
            Alg.match(switch (args) {
                case {"-runTests"; _;}:
                    new test.TestMain();
                case {"--type"; data; l;}:
                    var sp = data.split("@");
                    var pos = Std.parseInt(sp[1]);
                    var file = sp[0];

                    AutoMake.fromFile('test/Project/Project.hxml')
                        (["-dce", "no",  "-D", "no-copt", "-cp", Sys.getCwd().fullPath(), "--macro", 'test.TestBuilder.doCheck(\'$file\', $pos)', '--display', 'Project.hx@0']);
                
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