package hxassist;

import ds.IList;
import com.mindrocks.monads.instances.Prelude;
import haxe.ds.Option;

using sys.FileSystem;
using Alg;

class Run {
    static function main() new Run(Sys.args());

   
    function new(args:Iterable<String>) {
        trace(IList.ilist(args));
        //Get lib path from end of args 
        var list = IList.ilist(args).reverse();
        var expath = list.head();
        var libdir = Sys.getCwd();
        Sys.setCwd(expath);
        var list = list.tail().reverse();

        var vfs = new VFS('${libdir}temp836/');
        vfs.addClasspath(expath);

        function readArgs(args:IList<String>) {
            Alg.match(switch (args) {
                case {"-runTests"; l;}:
                    new test.TestMain();
                    readArgs(l);
                case {"--type"; file; tpath; pos; l;}:
                    var pos = Std.parseInt(pos);

                    AutoMake.fromFile(file)
                        (["-dce", "no",  "-D", "no-copt", "-cp", "C:/Users/Matthew/Documents/Github/hxassist/",
                            "--display", '"$file@0"',
                            "--macro",
                            "haxe.macro.Compiler.addMetadata('@:build(test.TestBuilder.doBuildCheck("+pos+"))', '"+tpath+"')"]);
                
                    Sys.exit(0);
                    readArgs(l);
                case {"--source"; file; contents; l;}:
                    vfs.modify(file, function(s) return Some(utils.Base64.decode(contents)));
                    readArgs(l);
                case {"--write"; l;}:
                    vfs.writeToFileSystem();
                    readArgs(l);
                case {cmd; _;}:
                    trace('unknown argument $cmd');
                case {[];}:
                    });
        }
        readArgs(list);
    }
}